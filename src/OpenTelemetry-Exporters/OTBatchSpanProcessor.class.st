"
I am a processor that forwards batches of `OTSpan` to the configured `OTSpanExporter`.
Batches are sent when the configured batchSize is reached, when the scheduled delay elapses, or when the image is exited.
"
Class {
	#name : 'OTBatchSpanProcessor',
	#superclass : 'OTSpanProcessor',
	#instVars : [
		'batch',
		'batchSize',
		'maxQueueSize',
		'queueLock',
		'exportLock',
		'flushProcess',
		'workAvailable',
		'stateLock',
		'exportInProgress',
		'shutdownRequested',
		'queueBecameNonEmptyAt',
		'exporter'
	],
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'private - configuration' }
OTBatchSpanProcessor class >> exportTimeoutMillisByProcessor [

	^ OTClassStateStore
		valueAt: #otExportTimeoutMillisByProcessor
		forClass: self
		ifAbsent: [
			| values |
			values := WeakIdentityKeyDictionary new.
			OTClassStateStore
				valueAt: #otExportTimeoutMillisByProcessor
				forClass: self
				put: values.
			values ]
]

{ #category : 'class initialization' }
OTBatchSpanProcessor class >> initialize [

	SessionManager default registerToolClassNamed: self name
]

{ #category : 'private - configuration' }
OTBatchSpanProcessor class >> scheduledDelayMillisByProcessor [

	^ OTClassStateStore
		valueAt: #otScheduledDelayMillisByProcessor
		forClass: self
		ifAbsent: [
			| values |
			values := WeakIdentityKeyDictionary new.
			OTClassStateStore
				valueAt: #otScheduledDelayMillisByProcessor
				forClass: self
				put: values.
			values ]
]

{ #category : 'system startup' }
OTBatchSpanProcessor class >> shutDown [

	self allInstancesDo: [ :processor | processor flush ]
]

{ #category : 'accessing' }
OTBatchSpanProcessor >> batchSize [

	^ batchSize
]

{ #category : 'accessing' }
OTBatchSpanProcessor >> batchSize: anInteger [

	anInteger >= 1 ifFalse: [
		Error signal: 'Batch size must be superior or equal to 1' ].
	batchSize := maxQueueSize ifNil: [ anInteger ] ifNotNil: [ anInteger min: maxQueueSize ]
]

{ #category : 'processing' }
OTBatchSpanProcessor >> exportNextBatch [

	^ self exportAvailableBatchesAllowPartial: false
]

{ #category : 'private - processing' }
OTBatchSpanProcessor >> exportNextBatchLocked [

	^ self exportAvailableBatchesAllowPartial: false
]

{ #category : 'accessing' }
OTBatchSpanProcessor >> exportTimeoutMillis [

	^ self class exportTimeoutMillisByProcessor
		at: self
		ifAbsent: [ OTSpanProcessor defaultBatchSpanProcessorExportTimeoutMillis ]
]

{ #category : 'accessing' }
OTBatchSpanProcessor >> exportTimeoutMillis: anInteger [

	(anInteger isInteger and: [ anInteger >= 1 ]) ifFalse: [
		Error signal: 'Export timeout must be superior or equal to 1 millisecond' ].
	self class exportTimeoutMillisByProcessor at: self put: anInteger.
	^ anInteger
]

{ #category : 'processing' }
OTBatchSpanProcessor >> flush [

	self isShutdown ifTrue: [ ^ false ].
	self ensureFlushProcess.
	(self exportAvailableBatchesAllowPartial: true) ifFalse: [ ^ false ].
	^ self waitUntilIdleTimeoutMillis: self exportTimeoutMillis
]

{ #category : 'processing' }
OTBatchSpanProcessor >> forceFlush [

	| flushed exported |
	self isShutdown ifTrue: [ ^ false ].
	flushed := self flush.
	flushed ifFalse: [ ^ false ].
	exported := self
		runExporterOperation: [ self exporter forceFlush ].
	^ flushed & exported
]

{ #category : 'accessing' }
OTBatchSpanProcessor >> exporter [

	^ exporter ifNil: [ exporter := OTSpanExporter current ]
]

{ #category : 'accessing' }
OTBatchSpanProcessor >> exporter: aSpanExporter [

	exporter := aSpanExporter
]

{ #category : 'initialization' }
OTBatchSpanProcessor >> initialize [
	"Default BSP sizing is aligned with the OpenTelemetry environment variable defaults"

	super initialize.
	maxQueueSize := 2048.
	batchSize := 512.
	batch := OrderedCollection new: maxQueueSize.
	queueLock := Semaphore forMutualExclusion.
	exportLock := Semaphore forMutualExclusion.
	workAvailable := Semaphore new.
	stateLock := Semaphore forMutualExclusion.
	exportInProgress := false.
	shutdownRequested := false.
	queueBecameNonEmptyAt := nil
]

{ #category : 'accessing' }
OTBatchSpanProcessor >> maxQueueSize [

	^ maxQueueSize
]

{ #category : 'accessing' }
OTBatchSpanProcessor >> maxQueueSize: anInteger [

	anInteger >= 1 ifFalse: [
		Error signal: 'Max queue size must be superior or equal to 1' ].
	maxQueueSize := anInteger.
	batchSize ifNotNil: [ batchSize := batchSize min: maxQueueSize ]
]

{ #category : 'processing' }
OTBatchSpanProcessor >> process: span [
	"Queue sampled spans for asynchronous export."

	| accepted shouldWakeWorker |
	accepted := false.
	shouldWakeWorker := false.
	self isStopping ifTrue: [ ^ false ].
	self isShutdown ifTrue: [ ^ false ].
	(self shouldExport: span) ifFalse: [ ^ true ].
	self ensureFlushProcess.
	queueLock critical: [
		| wasEmpty |
		batch size >= maxQueueSize ifTrue: [ ^ false ].
		wasEmpty := batch isEmpty.
		batch add: span.
		wasEmpty ifTrue: [ queueBecameNonEmptyAt := Time millisecondClockValue ].
		accepted := true.
		shouldWakeWorker := wasEmpty or: [ batch size >= batchSize ] ].
	shouldWakeWorker ifTrue: [ workAvailable signal ].
	^ accepted
]

{ #category : 'private - processing' }
OTBatchSpanProcessor >> exportAvailableBatchesAllowPartial: allowPartial [

	| allExported allowPartialNow spans |
	allExported := true.
	allowPartialNow := allowPartial.
	[
	spans := self nextBatchForExportAllowPartial: allowPartialNow.
	spans notNil ]
		whileTrue: [
			allExported := (self exportSpans: spans) & allExported.
			allowPartialNow := false ].
	^ allExported
]

{ #category : 'private - processing' }
OTBatchSpanProcessor >> exportInProgress [

	^ stateLock critical: [ exportInProgress = true ]
]

{ #category : 'private - processing' }
OTBatchSpanProcessor >> exportInProgress: aBoolean [

	stateLock critical: [ exportInProgress := aBoolean = true ].
	^ exportInProgress
]

{ #category : 'private - processing' }
OTBatchSpanProcessor >> exportSpans: spans [

	^ exportLock critical: [
		self exportInProgress: true.
		[ self runExporterOperation: [ self exporter export: spans ] ]
			ensure: [ self exportInProgress: false ] ]
]

{ #category : 'private - processing' }
OTBatchSpanProcessor >> isIdle [

	| queueEmpty |
	queueEmpty := queueLock critical: [ batch isEmpty ].
	^ queueEmpty and: [ self exportInProgress not ]
]

{ #category : 'private - processing' }
OTBatchSpanProcessor >> isStopping [

	^ stateLock critical: [ shutdownRequested = true ]
]

{ #category : 'private - processing' }
OTBatchSpanProcessor >> markShutdownRequested [

	stateLock critical: [ shutdownRequested := true ].
	^ self
]

{ #category : 'private - processing' }
OTBatchSpanProcessor >> nextBatchForExportAllowPartial: allowPartial [

	| exportCount spans |
	^ queueLock critical: [
		batch ifEmpty: [ ^ nil ].
		(allowPartial not and: [ batch size < batchSize ]) ifTrue: [ ^ nil ].
		exportCount := batchSize min: batch size.
		spans := batch copyFrom: 1 to: exportCount.
		exportCount timesRepeat: [ batch removeFirst ].
		batch isEmpty
			ifTrue: [ queueBecameNonEmptyAt := nil ]
			ifFalse: [
				batch size < batchSize ifTrue: [
					queueBecameNonEmptyAt := Time millisecondClockValue ] ].
		spans ]
]

{ #category : 'private - processing' }
OTBatchSpanProcessor >> nextWorkDecision [

	^ queueLock critical: [
		| remainingDelay |
		batch isEmpty ifTrue: [ ^ #idle ].
		batch size >= batchSize ifTrue: [ ^ #fullBatch ].
		queueBecameNonEmptyAt ifNil: [
			queueBecameNonEmptyAt := Time millisecondClockValue ].
		remainingDelay := self scheduledDelayMillis
			- (Time millisecondClockValue - queueBecameNonEmptyAt).
		remainingDelay <= 0 ifTrue: [ ^ #partialBatch ].
		remainingDelay ]
]

{ #category : 'accessing' }
OTBatchSpanProcessor >> scheduledDelayMillis [

	^ self class scheduledDelayMillisByProcessor
		at: self
		ifAbsent: [ OTSpanProcessor defaultBatchSpanProcessorScheduledDelayMillis ]
]

{ #category : 'accessing' }
OTBatchSpanProcessor >> scheduledDelayMillis: anInteger [

	(anInteger isInteger and: [ anInteger >= 1 ]) ifFalse: [
		Error signal: 'Scheduled delay must be superior or equal to 1 millisecond' ].
	self class scheduledDelayMillisByProcessor at: self put: anInteger.
	^ anInteger
]

{ #category : 'processing' }
OTBatchSpanProcessor >> shutdown [

	| flushed shutdownResult |
	self isShutdown ifTrue: [ ^ false ].
	self markShutdownRequested.
	workAvailable signal.
	flushed := self flush.
	self stopFlushProcess.
	shutdownResult := self
		runExporterOperation: [ self exporter shutdown ].
	self markShutdown.
	^ shutdownResult & flushed
]

{ #category : 'private - processing' }
OTBatchSpanProcessor >> ensureFlushProcess [

	self isStopping ifTrue: [ ^ nil ].
	(flushProcess notNil and: [ flushProcess isTerminated not ]) ifTrue: [ ^ flushProcess ].
	flushProcess := [ self runFlushLoop ] forkAt: Processor userBackgroundPriority.
	^ flushProcess
]

{ #category : 'private - processing' }
OTBatchSpanProcessor >> runFlushLoop [

	| decision timedOut |
	[ self isStopping ] whileFalse: [
		decision := self nextWorkDecision.
		decision = #idle ifTrue: [
			workAvailable wait ]
		ifFalse: [
			decision = #fullBatch ifTrue: [
				self exportAvailableBatchesAllowPartial: false ]
			ifFalse: [
				decision = #partialBatch ifTrue: [
					self exportAvailableBatchesAllowPartial: true ]
				ifFalse: [
					timedOut := workAvailable waitTimeoutMilliseconds: decision.
					timedOut ifTrue: [
						self exportAvailableBatchesAllowPartial: true ] ] ] ] ]
]

{ #category : 'private - processing' }
OTBatchSpanProcessor >> runExporterOperation: aBlock [

	^ aBlock
		valueWithinMilliseconds: self exportTimeoutMillis
		onTimeout: [ false ]
]

{ #category : 'private - processing' }
OTBatchSpanProcessor >> stopFlushProcess [

	flushProcess ifNotNil: [
		workAvailable signal.
		flushProcess terminate.
		flushProcess := nil ]
]

{ #category : 'private - processing' }
OTBatchSpanProcessor >> synchronized: aBlock [

	^ queueLock critical: aBlock
]

{ #category : 'private - processing' }
OTBatchSpanProcessor >> waitUntilIdleTimeoutMillis: anInteger [

	| deadline |
	deadline := Time millisecondClockValue + anInteger.
	[
		self isIdle ifTrue: [ ^ true ].
		Time millisecondClockValue >= deadline ifTrue: [ ^ false ].
		(Delay forMilliseconds: 5) wait ]
		repeat
]
