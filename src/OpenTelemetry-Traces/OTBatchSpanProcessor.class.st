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
	#category : 'OpenTelemetry-Traces',
	#package : 'OpenTelemetry-Traces'
}

{ #category : 'private - configuration' }
OTBatchSpanProcessor class >> exportTimeoutMillisByProcessor [

	^ OTClassStateStore valueAt: #otExportTimeoutMillisByProcessor forClass: self ifAbsentPut: [ WeakIdentityKeyDictionary new ]
]

{ #category : 'class initialization' }
OTBatchSpanProcessor class >> initialize [

	SessionManager default registerToolClassNamed: self name
]

{ #category : 'accessing' }
OTBatchSpanProcessor class >> liveInstances [
	"The processors that exist, which saving and starting the image visit without walking the heap."

	^ self registryLock critical: [ self registry keys reject: [ :each | each isNil ] ]
]

{ #category : 'private - registry' }
OTBatchSpanProcessor class >> register: aProcessor [

	self registryLock critical: [ self registry at: aProcessor put: true ]
]

{ #category : 'private - registry' }
OTBatchSpanProcessor class >> registry [
	"The processors that exist, subclasses' included, weakly held."

	^ OTClassStateStore valueAt: #otProcessors forClass: OTBatchSpanProcessor ifAbsentPut: [ WeakIdentityKeyDictionary new ]
]

{ #category : 'private - registry' }
OTBatchSpanProcessor class >> registryLock [

	^ OTClassStateStore valueAt: #otProcessorsLock forClass: OTBatchSpanProcessor ifAbsentPut: [ Semaphore forMutualExclusion ]
]

{ #category : 'private - configuration' }
OTBatchSpanProcessor class >> scheduledDelayMillisByProcessor [

	^ OTClassStateStore valueAt: #otScheduledDelayMillisByProcessor forClass: self ifAbsentPut: [ WeakIdentityKeyDictionary new ]
]

{ #category : 'system startup' }
OTBatchSpanProcessor class >> shutDown: quitting [
	"Before the image is saved. An image that quits first exports what is queued, waiting a second at most, since a VM that is quitting should not wait on a collector, and drops the rest. One that goes on keeps its queue, which a later start from this save drops. Either way the exporters' connections are then closed, see OTExporterConnections."

	quitting ifTrue: [
			self liveInstances do: [ :each |
					each
						flushWithinMilliseconds: self snapshotFlushTimeoutMillis;
						discardQueuedSpans ] ].
	OTExporterConnections prepareForSnapshot
]

{ #category : 'system startup' }
OTBatchSpanProcessor class >> snapshotFlushTimeoutMillis [
	"The longest an image that quits waits for its queued spans."

	^ 1000
]

{ #category : 'system startup' }
OTBatchSpanProcessor class >> startUp: resuming [
	"An image that starts from its saved file forgets what its processors were doing when it was saved, rather than export it under settings that may have changed since, and rather than make its start wait on it."

	resuming ifTrue: [ self liveInstances do: [ :each | each forgetEarlierSession ] ]
]

{ #category : 'accessing' }
OTBatchSpanProcessor >> batchSize [

	^ batchSize
]

{ #category : 'accessing' }
OTBatchSpanProcessor >> batchSize: anInteger [

	| normalized |
	normalized := self validatedRuntimeInteger: anInteger minimum: 1 forOperation: 'batchSize:'.
	normalized ifNil: [ ^ batchSize ].
	batchSize := maxQueueSize ifNil: [ normalized ] ifNotNil: [ normalized min: maxQueueSize ]
]

{ #category : 'private - hooks' }
OTBatchSpanProcessor >> beforeOnEndEnqueueingSnapshot: aSpanSnapshot [
	"Extension hook for subclasses that need to coordinate before queueing begins."

	self
]

{ #category : 'processing' }
OTBatchSpanProcessor >> discardQueuedSpans [
	"Drops the queued spans without exporting them."

	| dropped |
	dropped := queueLock critical: [
		           | count |
		           count := batch size.
		           batch removeAll.
		           queueBecameNonEmptyAt := nil.
		           count ].
	dropped > 0 ifTrue: [
			OTSdkSelfObservability current
				adjustQueueSizeBy: dropped negated
				forProcessor: self
				signal: #span
				capacity: maxQueueSize ]
]

{ #category : 'private - processing' }
OTBatchSpanProcessor >> ensureFlushProcess [
	"Starts the flush process unless it runs. Spans that end at once in several processes would otherwise each start one, and those not kept would outlive the processor."

	^ stateLock critical: [
			  shutdownRequested = true
				  ifTrue: [ nil ]
				  ifFalse: [
						  (flushProcess notNil and: [ flushProcess isTerminated not ]) ifFalse: [
							  flushProcess := [ self runFlushLoop ] forkAt: Processor userBackgroundPriority ].
						  flushProcess ] ]
]

{ #category : 'private - processing' }
OTBatchSpanProcessor >> exportAvailableBatchesAllowPartial: allowPartial [

	| allExported allowPartialNow spans |
	allExported := true.
	allowPartialNow := allowPartial.
	[
		spans := self nextBatchForExportAllowPartial: allowPartialNow.
		spans notNil ] whileTrue: [
			allExported := (self exportSpans: spans) & allExported.
			allowPartialNow := false ].
	^ allExported
]

{ #category : 'private - processing' }
OTBatchSpanProcessor >> exportAvailableBatchesAllowPartialResult: allowPartial [

	| allExported allowPartialNow spans |
	allExported := OTLifecycleResult success.
	allowPartialNow := allowPartial.
	[
		spans := self nextBatchForExportAllowPartial: allowPartialNow.
		spans notNil ] whileTrue: [
			allExported := allExported combinedWith: (self exportSpansResult: spans).
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

{ #category : 'processing' }
OTBatchSpanProcessor >> exportNextBatch [

	^ self exportAvailableBatchesAllowPartial: false
]

{ #category : 'private - processing' }
OTBatchSpanProcessor >> exportNextBatchLocked [

	^ self exportAvailableBatchesAllowPartial: false
]

{ #category : 'private - processing' }
OTBatchSpanProcessor >> exportSpans: spans [

	^ exportLock critical: [
			  self exportInProgress: true.
			  [ self runExporterOperation: [ self exporter export: spans ] ] ensure: [ self exportInProgress: false ] ]
]

{ #category : 'private - processing' }
OTBatchSpanProcessor >> exportSpansResult: spans [

	| durationSeconds result startedMillis |
	^ exportLock critical: [
			  self exportInProgress: true.
			  [
				  startedMillis := Time millisecondClockValue.
				  OTSdkSelfObservability current recordExportStartedFor: self exporter signal: #span itemCount: spans size.
				  result := self runExporterOperationResultNamed: 'export' do: [ self exporter export: spans ].
				  durationSeconds := OTSdkSelfObservability elapsedSecondsSinceMillisecondClockValue: startedMillis.
				  OTSdkSelfObservability current
					  recordExportFinishedFor: self exporter
					  signal: #span
					  itemCount: spans size
					  result: result
					  durationSeconds: durationSeconds;
					  recordProcessedCount: spans size
					  forProcessor: self
					  signal: #span
					  errorType: (OTSdkSelfObservability lifecycleErrorTypeFor: result).
				  result ] ensure: [ self exportInProgress: false ] ]
]

{ #category : 'accessing' }
OTBatchSpanProcessor >> exportTimeoutMillis [

	^ self class exportTimeoutMillisByProcessor at: self ifAbsent: [ OTSpanProcessor defaultBatchSpanProcessorExportTimeoutMillis ]
]

{ #category : 'accessing' }
OTBatchSpanProcessor >> exportTimeoutMillis: anInteger [

	| normalized |
	normalized := self validatedRuntimeInteger: anInteger minimum: 0 forOperation: 'exportTimeoutMillis:'.
	normalized ifNil: [ ^ self exportTimeoutMillis ].
	self class exportTimeoutMillisByProcessor at: self put: normalized.
	^ normalized
]

{ #category : 'accessing' }
OTBatchSpanProcessor >> exporter [

	^ exporter ifNil: [ exporter := OTSpanExporter current ]
]

{ #category : 'accessing' }
OTBatchSpanProcessor >> exporter: aSpanExporter [

	aSpanExporter ifNil: [
			exporter := nil.
			^ exporter ].
	(self validatedExporterConfiguration: aSpanExporter forOperation: 'exporter:') ifNil: [ ^ exporter ].
	exporter := aSpanExporter
]

{ #category : 'processing' }
OTBatchSpanProcessor >> flush [

	self isShutdown ifTrue: [ ^ false ].
	self ensureFlushProcess.
	(self exportAvailableBatchesAllowPartial: true) ifFalse: [ ^ false ].
	^ self waitUntilIdleTimeoutMillis: self exportTimeoutMillis
]

{ #category : 'processing' }
OTBatchSpanProcessor >> flushResult [

	self isShutdown ifTrue: [ ^ OTLifecycleResult failure ].
	self ensureFlushProcess.
	^ (self exportAvailableBatchesAllowPartialResult: true) combinedWith:
		  (self waitUntilIdleResultTimeoutMillis: self exportTimeoutMillis)
]

{ #category : 'processing' }
OTBatchSpanProcessor >> flushWithinMilliseconds: anInteger [
	"Exports what is queued, and answers whether all of it went within anInteger milliseconds."

	^ [ self flush ] valueWithinMilliseconds: anInteger onTimeout: [ false ]
]

{ #category : 'processing' }
OTBatchSpanProcessor >> forceFlush [

	| exported flushed |
	self isShutdown ifTrue: [ ^ false ].
	flushed := self flush.
	exported := self runExporterOperation: [ self exporter forceFlush ].
	^ flushed & exported
]

{ #category : 'processing' }
OTBatchSpanProcessor >> forceFlushResult [

	| exported flushed |
	self isShutdown ifTrue: [ ^ OTLifecycleResult failure ].
	flushed := self flushResult.
	exported := self runExporterOperationResultNamed: 'forceFlush' do: [ self exporter forceFlush ].
	^ flushed combinedWith: exported
]

{ #category : 'processing' }
OTBatchSpanProcessor >> forgetEarlierSession [
	"Stops the export the image was saved in the middle of, and drops the queued spans: both belong to the session that saved it. The next span starts a flush process again."

	self
		stopFlushProcess;
		discardQueuedSpans
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
	queueBecameNonEmptyAt := nil.
	OTBatchSpanProcessor register: self
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

{ #category : 'accessing' }
OTBatchSpanProcessor >> maxQueueSize [

	^ maxQueueSize
]

{ #category : 'accessing' }
OTBatchSpanProcessor >> maxQueueSize: anInteger [

	| normalized |
	normalized := self validatedRuntimeInteger: anInteger minimum: 1 forOperation: 'maxQueueSize:'.
	normalized ifNil: [ ^ maxQueueSize ].
	maxQueueSize := normalized.
	batchSize ifNotNil: [ batchSize := batchSize min: maxQueueSize ]
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
				  ifFalse: [ batch size < batchSize ifTrue: [ queueBecameNonEmptyAt := Time millisecondClockValue ] ].
			  OTSdkSelfObservability current
				  adjustQueueSizeBy: exportCount negated
				  forProcessor: self
				  signal: #span
				  capacity: maxQueueSize.
			  spans ]
]

{ #category : 'private - processing' }
OTBatchSpanProcessor >> nextWorkDecision [

	^ queueLock critical: [
			  | remainingDelay |
			  batch isEmpty ifTrue: [ ^ #idle ].
			  batch size >= batchSize ifTrue: [ ^ #fullBatch ].
			  queueBecameNonEmptyAt ifNil: [ queueBecameNonEmptyAt := Time millisecondClockValue ].
			  remainingDelay := self scheduledDelayMillis - (Time millisecondClockValue - queueBecameNonEmptyAt).
			  remainingDelay <= 0 ifTrue: [ ^ #partialBatch ].
			  remainingDelay ]
]

{ #category : 'private - logging' }
OTBatchSpanProcessor >> noteFlushError: anError [

	| message |
	message := 'OpenTelemetry batch span processor flush failed: ' , anError messageText.
	OTDiagnosticLogger current
		handleSuppressedError: anError
		message: message
		fallback: [ OTDiagnosticLogger defaultWarningSink value: message ]
]

{ #category : 'processing' }
OTBatchSpanProcessor >> onEnd: span [
	"Queue sampled spans for asynchronous export."

	| accepted shouldWakeWorker snapshot |
	accepted := false.
	shouldWakeWorker := false.
	self isStopping ifTrue: [ ^ false ].
	self isShutdown ifTrue: [ ^ false ].
	(self shouldExport: span) ifFalse: [ ^ true ].
	snapshot := OTSpanSnapshot fromSpan: span.
	self beforeOnEndEnqueueingSnapshot: snapshot.
	self ensureFlushProcess.
	queueLock critical: [
			| wasEmpty |
			self isStopping ifTrue: [ ^ false ].
			batch size >= maxQueueSize ifTrue: [
					OTSdkSelfObservability current
						recordProcessedCount: 1
						forProcessor: self
						signal: #span
						errorType: 'queue_full'.
					^ false ].
			wasEmpty := batch isEmpty.
			batch add: snapshot.
			wasEmpty ifTrue: [ queueBecameNonEmptyAt := Time millisecondClockValue ].
			accepted := true.
			shouldWakeWorker := wasEmpty or: [ batch size >= batchSize ] ].
	accepted ifTrue: [
			OTSdkSelfObservability current
				adjustQueueSizeBy: 1
				forProcessor: self
				signal: #span
				capacity: maxQueueSize ].
	shouldWakeWorker ifTrue: [ workAvailable signal ].
	^ accepted
]

{ #category : 'private - processing' }
OTBatchSpanProcessor >> processNextWork [

	| decision timedOut |
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
										timedOut ifTrue: [ self exportAvailableBatchesAllowPartial: true ] ] ] ]
]

{ #category : 'private - processing' }
OTBatchSpanProcessor >> runExporterOperation: aBlock [

	self exportTimeoutMillis = 0 ifTrue: [ ^ aBlock value ].
	^ aBlock valueWithinMilliseconds: self exportTimeoutMillis onTimeout: [ false ]
]

{ #category : 'private - processing' }
OTBatchSpanProcessor >> runExporterOperationResultNamed: anOperationName do: aBlock [

	self exportTimeoutMillis = 0 ifTrue: [
		^ OTLifecycleResult fromBoolean: (self exporter withOperationNamed: anOperationName default: false do: aBlock) ].
	^ [ OTLifecycleResult fromBoolean: (self exporter withOperationNamed: anOperationName default: false do: aBlock) ]
		  valueWithinMilliseconds: self exportTimeoutMillis
		  onTimeout: [ OTLifecycleResult timeout ]
]

{ #category : 'private - processing' }
OTBatchSpanProcessor >> runFlushLoop [
	"An error drops the batch being exported rather than end the loop, which would leave the queue to fill, and quit a headless image. So does an error while noting it."

	[ self isStopping ] whileFalse: [
			[ self processNextWork ]
				on: Error
				do: [ :error |
						[ self noteFlushError: error ]
							on: Error
							do: [ :noteError | noteError return: nil ] ] ]
]

{ #category : 'accessing' }
OTBatchSpanProcessor >> scheduledDelayMillis [

	^ self class scheduledDelayMillisByProcessor at: self ifAbsent: [ OTSpanProcessor defaultBatchSpanProcessorScheduledDelayMillis ]
]

{ #category : 'accessing' }
OTBatchSpanProcessor >> scheduledDelayMillis: anInteger [

	| normalized |
	normalized := self validatedRuntimeInteger: anInteger minimum: 0 forOperation: 'scheduledDelayMillis:'.
	normalized ifNil: [ ^ self scheduledDelayMillis ].
	self class scheduledDelayMillisByProcessor at: self put: normalized.
	^ normalized
]

{ #category : 'processing' }
OTBatchSpanProcessor >> shutdown [

	| flushed shutdownResult |
	self isShutdown ifTrue: [ ^ false ].
	self markShutdownRequested.
	workAvailable signal.
	flushed := self forceFlush.
	self stopFlushProcess.
	shutdownResult := self runExporterOperation: [ self exporter shutdown ].
	self markShutdown.
	^ shutdownResult & flushed
]

{ #category : 'processing' }
OTBatchSpanProcessor >> shutdownResult [

	| flushed shutdownResult |
	self isShutdown ifTrue: [ ^ OTLifecycleResult failure ].
	self markShutdownRequested.
	workAvailable signal.
	flushed := self forceFlushResult.
	self stopFlushProcess.
	shutdownResult := self runExporterOperationResultNamed: 'shutdown' do: [ self exporter shutdown ].
	self markShutdown.
	^ flushed combinedWith: shutdownResult
]

{ #category : 'private - processing' }
OTBatchSpanProcessor >> stopFlushProcess [

	| process |
	process := stateLock critical: [
			           | running |
			           running := flushProcess.
			           flushProcess := nil.
			           running ].
	process ifNotNil: [
			workAvailable signal.
			process terminate ]
]

{ #category : 'private - processing' }
OTBatchSpanProcessor >> synchronized: aBlock [

	^ queueLock critical: aBlock
]

{ #category : 'private - configuration' }
OTBatchSpanProcessor >> validatedRuntimeInteger: aValue minimum: aMinimum forOperation: anOperationName [

	(aValue isInteger and: [ aValue >= aMinimum ]) ifTrue: [ ^ aValue ].
	self configurationWarningOwner noteInvalidRuntimeConfigurationValue: aValue forOperation: anOperationName.
	^ nil
]

{ #category : 'private - processing' }
OTBatchSpanProcessor >> waitUntilIdleResultTimeoutMillis: anInteger [

	| deadline |
	anInteger = 0 ifTrue: [
			[
				self isIdle ifTrue: [ ^ OTLifecycleResult success ].
				(Delay forMilliseconds: 5) wait ] repeat ].
	deadline := Time millisecondClockValue + anInteger.
	[
		self isIdle ifTrue: [ ^ OTLifecycleResult success ].
		Time millisecondClockValue >= deadline ifTrue: [ ^ OTLifecycleResult timeout ].
		(Delay forMilliseconds: 5) wait ] repeat
]

{ #category : 'private - processing' }
OTBatchSpanProcessor >> waitUntilIdleTimeoutMillis: anInteger [

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
