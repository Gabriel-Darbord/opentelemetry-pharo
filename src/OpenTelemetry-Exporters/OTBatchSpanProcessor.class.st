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
		'exportLock',
		'flushProcess'
	],
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'private - configuration' }
OTBatchSpanProcessor class >> exportTimeoutMillisByProcessor [

	^ OTBatchSpanProcessor
		propertyAt: #otExportTimeoutMillisByProcessor
		ifAbsent: [
			| values |
			values := WeakIdentityKeyDictionary new.
			OTBatchSpanProcessor propertyAt: #otExportTimeoutMillisByProcessor put: values.
			values ]
]

{ #category : 'class initialization' }
OTBatchSpanProcessor class >> initialize [

	SessionManager default registerToolClassNamed: self name
]

{ #category : 'private - configuration' }
OTBatchSpanProcessor class >> scheduledDelayMillisByProcessor [

	^ OTBatchSpanProcessor
		propertyAt: #otScheduledDelayMillisByProcessor
		ifAbsent: [
			| values |
			values := WeakIdentityKeyDictionary new.
			OTBatchSpanProcessor propertyAt: #otScheduledDelayMillisByProcessor put: values.
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

	^ self synchronized: [ self exportNextBatchLocked ]
]

{ #category : 'private - processing' }
OTBatchSpanProcessor >> exportNextBatchLocked [

	| exportCount spans |
	batch ifEmpty: [ ^ false ].
	exportCount := batchSize min: batch size.
	spans := batch copyFrom: 1 to: exportCount.
	exportCount timesRepeat: [ batch removeFirst ].
	^ OTSpanExporter current export: spans
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

	| allExported didExport |
	self isShutdown ifTrue: [ ^ false ].
	^ self synchronized: [
		allExported := true.
		didExport := false.
		[ batch isEmpty ] whileFalse: [
			didExport := true.
			allExported := (self exportNextBatchLocked) & allExported ].
		^ didExport ifTrue: [ allExported ] ifFalse: [ false ] ]
]

{ #category : 'processing' }
OTBatchSpanProcessor >> forceFlush [

	| flushed exported |
	self isShutdown ifTrue: [ ^ false ].
	flushed := self flush.
	exported := OTSpanExporter current forceFlush.
	^ flushed | exported
]

{ #category : 'initialization' }
OTBatchSpanProcessor >> initialize [
	"Default BSP sizing is aligned with the OpenTelemetry environment variable defaults"

	super initialize.
	maxQueueSize := 2048.
	batchSize := 512.
	batch := OrderedCollection new: maxQueueSize.
	exportLock := Semaphore forMutualExclusion
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
	"Wait until the sampled batch has been filled to export"

	self isShutdown ifTrue: [ ^ false ].
	(self shouldExport: span) ifFalse: [ ^ true ].
	self ensureFlushProcess.
	^ self synchronized: [
		batch size >= maxQueueSize ifTrue: [ ^ false ].
		batch add: span.
		batch size < batchSize ifTrue: [ ^ true ].
		^ self exportNextBatchLocked ]
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
	self stopFlushProcess.
	flushed := self forceFlush.
	shutdownResult := OTSpanExporter current shutdown.
	self markShutdown.
	^ shutdownResult & flushed
]

{ #category : 'private - processing' }
OTBatchSpanProcessor >> ensureFlushProcess [

	(flushProcess notNil and: [ flushProcess isTerminated not ]) ifTrue: [ ^ flushProcess ].
	flushProcess := [ self runFlushLoop ] forkAt: Processor userBackgroundPriority.
	^ flushProcess
]

{ #category : 'private - processing' }
OTBatchSpanProcessor >> runFlushLoop [

	[ self isShutdown ] whileFalse: [
		(Delay forMilliseconds: self scheduledDelayMillis) wait.
		self isShutdown ifFalse: [ self flush ] ]
]

{ #category : 'private - processing' }
OTBatchSpanProcessor >> stopFlushProcess [

	flushProcess ifNotNil: [
		flushProcess terminate.
		flushProcess := nil ]
]

{ #category : 'private - processing' }
OTBatchSpanProcessor >> synchronized: aBlock [

	^ exportLock critical: aBlock
]
