"
A batching log-record processor that asynchronously exports readable log records.

It serializes calls to its exporter, maintains a bounded queue, and stops accepting new log records once shutdown begins.
"
Class {
	#name : 'OTBatchLogRecordProcessor',
	#superclass : 'OTLogRecordProcessor',
	#instVars : [
		'queue',
		'maxExportBatchSize',
		'maxQueueSize',
		'queueLock',
		'exportLock',
		'flushProcess',
		'workAvailable',
		'stateLock',
		'exportInProgress',
		'shutdownRequested',
		'shutdownCompleted',
		'queueBecameNonEmptyAt',
		'exporter',
		'scheduledDelayMillis',
		'exportTimeoutMillis'
	],
	#category : 'OpenTelemetry-Logs',
	#package : 'OpenTelemetry-Logs'
}

{ #category : 'testing' }
OTBatchLogRecordProcessor >> enabledIn: anOTContext instrumentationScope: anInstrumentationScope severityNumber: anObject eventName: aString [

	^ self isStopping not and: [
			  self isShutdown not and: [
					  self exporter
						  enabledIn: anOTContext
						  instrumentationScope: anInstrumentationScope
						  severityNumber: anObject
						  eventName: aString ] ]
]

{ #category : 'private - processing' }
OTBatchLogRecordProcessor >> ensureFlushProcess [

	self isStopping ifTrue: [ ^ nil ].
	(flushProcess notNil and: [ flushProcess isTerminated not ]) ifTrue: [ ^ flushProcess ].
	flushProcess := [ self runFlushLoop ] forkAt: Processor userBackgroundPriority.
	^ flushProcess
]

{ #category : 'processing' }
OTBatchLogRecordProcessor >> exportAvailableBatchesAllowPartial: allowPartial [

	| allExported allowPartialNow records |
	allExported := true.
	allowPartialNow := allowPartial.
	[
		records := self nextBatchForExportAllowPartial: allowPartialNow.
		records notNil ] whileTrue: [
			allExported := (self exportLogRecords: records) & allExported.
			allowPartialNow := false ].
	^ allExported
]

{ #category : 'private - processing' }
OTBatchLogRecordProcessor >> exportInProgress [

	^ stateLock critical: [ exportInProgress = true ]
]

{ #category : 'private - processing' }
OTBatchLogRecordProcessor >> exportInProgress: aBoolean [

	stateLock critical: [ exportInProgress := aBoolean = true ].
	^ exportInProgress
]

{ #category : 'private - processing' }
OTBatchLogRecordProcessor >> exportLogRecords: someLogRecords [

	^ exportLock critical: [
			  self exportInProgress: true.
			  [ self runExporterOperation: [ self exporter export: someLogRecords ] ] ensure: [ self exportInProgress: false ] ]
]

{ #category : 'accessing' }
OTBatchLogRecordProcessor >> exportTimeoutMillis [

	^ exportTimeoutMillis
]

{ #category : 'accessing' }
OTBatchLogRecordProcessor >> exportTimeoutMillis: anInteger [

	(anInteger isInteger and: [ anInteger >= 0 ]) ifFalse: [
		Error signal: 'Export timeout must be superior or equal to 0 millisecond' ].
	exportTimeoutMillis := anInteger.
	^ exportTimeoutMillis
]

{ #category : 'accessing' }
OTBatchLogRecordProcessor >> exporter [

	^ exporter ifNil: [ OTNoopLogRecordExporter new ]
]

{ #category : 'accessing' }
OTBatchLogRecordProcessor >> exporter: anOTLogRecordExporter [

	exporter := anOTLogRecordExporter.
	^ exporter
]

{ #category : 'processing' }
OTBatchLogRecordProcessor >> flush [

	self isShutdown ifTrue: [ ^ false ].
	self ensureFlushProcess.
	(self exportAvailableBatchesAllowPartial: true) ifFalse: [ ^ false ].
	^ self waitUntilIdleTimeoutMillis: self exportTimeoutMillis
]

{ #category : 'processing' }
OTBatchLogRecordProcessor >> forceFlush [

	| flushed exported |
	self isShutdown ifTrue: [ ^ false ].
	flushed := self flush.
	flushed ifFalse: [ ^ false ].
	exported := self runExporterOperation: [ self exporter forceFlush ].
	^ flushed & exported
]

{ #category : 'initialization' }
OTBatchLogRecordProcessor >> initialize [

	super initialize.
	maxQueueSize := 2048.
	maxExportBatchSize := 512.
	queue := OrderedCollection new: maxQueueSize.
	queueLock := Semaphore forMutualExclusion.
	exportLock := Semaphore forMutualExclusion.
	workAvailable := Semaphore new.
	stateLock := Semaphore forMutualExclusion.
	exportInProgress := false.
	shutdownRequested := false.
	shutdownCompleted := false.
	queueBecameNonEmptyAt := nil.
	scheduledDelayMillis := 1000.
	exportTimeoutMillis := 30000
]

{ #category : 'testing' }
OTBatchLogRecordProcessor >> isIdle [

	| queueEmpty |
	queueEmpty := queueLock critical: [ queue isEmpty ].
	^ queueEmpty and: [ self exportInProgress not ]
]

{ #category : 'testing' }
OTBatchLogRecordProcessor >> isShutdown [

	^ stateLock critical: [ shutdownCompleted = true ]
]

{ #category : 'testing' }
OTBatchLogRecordProcessor >> isStopping [

	^ stateLock critical: [ shutdownRequested = true ]
]

{ #category : 'private - processing' }
OTBatchLogRecordProcessor >> markShutdown [

	stateLock critical: [ shutdownCompleted := true ].
	self
]

{ #category : 'private - processing' }
OTBatchLogRecordProcessor >> markShutdownRequested [

	stateLock critical: [ shutdownRequested := true ].
	self
]

{ #category : 'accessing' }
OTBatchLogRecordProcessor >> maxExportBatchSize [

	^ maxExportBatchSize
]

{ #category : 'accessing' }
OTBatchLogRecordProcessor >> maxExportBatchSize: anInteger [

	anInteger >= 1 ifFalse: [ Error signal: 'Max export batch size must be superior or equal to 1' ].
	maxExportBatchSize := maxQueueSize ifNil: [ anInteger ] ifNotNil: [ anInteger min: maxQueueSize ].
	^ maxExportBatchSize
]

{ #category : 'accessing' }
OTBatchLogRecordProcessor >> maxQueueSize [

	^ maxQueueSize
]

{ #category : 'accessing' }
OTBatchLogRecordProcessor >> maxQueueSize: anInteger [

	anInteger >= 1 ifFalse: [ Error signal: 'Max queue size must be superior or equal to 1' ].
	maxQueueSize := anInteger.
	maxExportBatchSize ifNotNil: [ maxExportBatchSize := maxExportBatchSize min: maxQueueSize ].
	^ maxQueueSize
]

{ #category : 'private - processing' }
OTBatchLogRecordProcessor >> nextBatchForExportAllowPartial: allowPartial [

	| exportCount records |
	^ queueLock critical: [
			  queue ifEmpty: [ ^ nil ].
			  (allowPartial not and: [ queue size < maxExportBatchSize ]) ifTrue: [ ^ nil ].
			  exportCount := maxExportBatchSize min: queue size.
			  records := queue copyFrom: 1 to: exportCount.
			  exportCount timesRepeat: [ queue removeFirst ].
			  queue isEmpty
				  ifTrue: [ queueBecameNonEmptyAt := nil ]
				  ifFalse: [ queue size < maxExportBatchSize ifTrue: [ queueBecameNonEmptyAt := Time millisecondClockValue ] ].
			  records ]
]

{ #category : 'private - processing' }
OTBatchLogRecordProcessor >> nextWorkDecision [

	^ queueLock critical: [
			  | remainingDelay |
			  queue isEmpty ifTrue: [ ^ #idle ].
			  queue size >= maxExportBatchSize ifTrue: [ ^ #fullBatch ].
			  queueBecameNonEmptyAt ifNil: [ queueBecameNonEmptyAt := Time millisecondClockValue ].
			  remainingDelay := self scheduledDelayMillis - (Time millisecondClockValue - queueBecameNonEmptyAt).
			  remainingDelay <= 0 ifTrue: [ ^ #partialBatch ].
			  remainingDelay ]
]

{ #category : 'processing' }
OTBatchLogRecordProcessor >> onEmit: anOTLogRecord context: anOTContext [
	"Queue a copy because batching processors must not race with later log-record mutation."

	| accepted shouldWakeWorker |
	accepted := false.
	shouldWakeWorker := false.
	self isStopping ifTrue: [ ^ self ].
	self isShutdown ifTrue: [ ^ self ].
	self ensureFlushProcess.
	queueLock critical: [
			| wasEmpty |
			queue size >= maxQueueSize ifTrue: [ ^ self ].
			wasEmpty := queue isEmpty.
			queue add: anOTLogRecord copy.
			wasEmpty ifTrue: [ queueBecameNonEmptyAt := Time millisecondClockValue ].
			accepted := true.
			shouldWakeWorker := wasEmpty or: [ queue size >= maxExportBatchSize ] ].
	accepted ifTrue: [ shouldWakeWorker ifTrue: [ workAvailable signal ] ].
	self
]

{ #category : 'private - processing' }
OTBatchLogRecordProcessor >> runExporterOperation: aBlock [

	self exportTimeoutMillis = 0 ifTrue: [ ^ aBlock value ].
	^ aBlock valueWithinMilliseconds: self exportTimeoutMillis onTimeout: [ false ]
]

{ #category : 'private - processing' }
OTBatchLogRecordProcessor >> runFlushLoop [

	| decision timedOut |
	[ self isStopping ] whileFalse: [
			decision := self nextWorkDecision.
			decision = #idle
				ifTrue: [ workAvailable wait ]
				ifFalse: [
						decision = #fullBatch
							ifTrue: [ self exportAvailableBatchesAllowPartial: false ]
							ifFalse: [
									decision = #partialBatch
										ifTrue: [ self exportAvailableBatchesAllowPartial: true ]
										ifFalse: [
												timedOut := workAvailable waitTimeoutMilliseconds: decision.
												timedOut ifTrue: [ self exportAvailableBatchesAllowPartial: true ] ] ] ] ]
]

{ #category : 'accessing' }
OTBatchLogRecordProcessor >> scheduledDelayMillis [

	^ scheduledDelayMillis
]

{ #category : 'accessing' }
OTBatchLogRecordProcessor >> scheduledDelayMillis: anInteger [

	(anInteger isInteger and: [ anInteger >= 0 ]) ifFalse: [
		Error signal: 'Scheduled delay must be superior or equal to 0 millisecond' ].
	scheduledDelayMillis := anInteger.
	^ scheduledDelayMillis
]

{ #category : 'processing' }
OTBatchLogRecordProcessor >> shutdown [

	| flushed shutdownResult |
	self isShutdown ifTrue: [ ^ false ].
	self markShutdownRequested.
	workAvailable signal.
	flushed := self flush.
	self stopFlushProcess.
	shutdownResult := self runExporterOperation: [ self exporter shutdown ].
	self markShutdown.
	^ shutdownResult & flushed
]

{ #category : 'private - processing' }
OTBatchLogRecordProcessor >> stopFlushProcess [

	flushProcess ifNotNil: [
			workAvailable signal.
			flushProcess terminate.
			flushProcess := nil ]
]

{ #category : 'private - processing' }
OTBatchLogRecordProcessor >> waitUntilIdleTimeoutMillis: anInteger [

	| deadline |
	anInteger = 0 ifTrue: [
			[
				self isIdle ifTrue: [ ^ true ].
				(Delay forMilliseconds: 5) wait ] repeat ].
	deadline := Time millisecondClockValue + anInteger.
	[
		self isIdle ifTrue: [ ^ true ].
		Time millisecondClockValue >= deadline ifTrue: [ ^ false ].
		(Delay forMilliseconds: 5) wait ] repeat
]
