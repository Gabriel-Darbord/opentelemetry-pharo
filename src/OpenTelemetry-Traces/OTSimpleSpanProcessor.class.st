"
I am a basic processor that forwards any `OTSpan` I receive directly to the configured `OTSpanExporter`.
"
Class {
	#name : 'OTSimpleSpanProcessor',
	#superclass : 'OTSpanProcessor',
	#instVars : [
		'exportLock',
		'exporter'
	],
	#category : 'OpenTelemetry-Traces',
	#package : 'OpenTelemetry-Traces'
}

{ #category : 'private - configuration' }
OTSimpleSpanProcessor class >> exportTimeoutMillisByProcessor [

	^ OTClassStateStore valueAt: #otExportTimeoutMillisByProcessor forClass: self ifAbsentPut: [ WeakIdentityKeyDictionary new ]
]

{ #category : 'private - hooks' }
OTSimpleSpanProcessor >> beforeOnEndExportingSnapshot: aSpanSnapshot [
	"Extension hook for subclasses that need to coordinate before export begins."

	self
]

{ #category : 'accessing' }
OTSimpleSpanProcessor >> exportTimeoutMillis [

	^ self class exportTimeoutMillisByProcessor at: self ifAbsent: [ OTSpanProcessor defaultBatchSpanProcessorExportTimeoutMillis ]
]

{ #category : 'accessing' }
OTSimpleSpanProcessor >> exportTimeoutMillis: anInteger [

	| normalized |
	normalized := self validatedRuntimeInteger: anInteger minimum: 0 forOperation: 'exportTimeoutMillis:'.
	normalized ifNil: [ ^ self exportTimeoutMillis ].
	self class exportTimeoutMillisByProcessor at: self put: normalized.
	^ normalized
]

{ #category : 'accessing' }
OTSimpleSpanProcessor >> exporter [

	^ exporter ifNil: [ exporter := OTSpanExporter current ]
]

{ #category : 'accessing' }
OTSimpleSpanProcessor >> exporter: aSpanExporter [

	aSpanExporter ifNil: [
			exporter := nil.
			^ exporter ].
	(self validatedExporterConfiguration: aSpanExporter forOperation: 'exporter:') ifNil: [ ^ exporter ].
	exporter := aSpanExporter
]

{ #category : 'processing' }
OTSimpleSpanProcessor >> flush [

	^ exportLock critical: [ self runExporterOperation: [ self exporter forceFlush ] ]
]

{ #category : 'processing' }
OTSimpleSpanProcessor >> flushResult [

	^ exportLock critical: [ self runExporterOperationResultNamed: 'forceFlush' do: [ self exporter forceFlush ] ]
]

{ #category : 'processing' }
OTSimpleSpanProcessor >> forceFlushResult [

	self isStopping ifTrue: [ ^ OTLifecycleResult failure ].
	^ self flushResult
]

{ #category : 'initialization' }
OTSimpleSpanProcessor >> initialize [

	super initialize.
	exportLock := Semaphore forMutualExclusion
]

{ #category : 'processing' }
OTSimpleSpanProcessor >> onEnd: span [
	"Directly export sampled spans and treat record-only spans as accepted without exporting"

	| snapshot |
	self isStopping ifTrue: [ ^ false ].
	(self shouldExport: span) ifFalse: [ ^ true ].
	snapshot := OTSpanSnapshot fromSpan: span.
	self beforeOnEndExportingSnapshot: snapshot.
	^ exportLock critical: [
			  self isStopping ifTrue: [ ^ false ].
			  self runExporterOperation: [ self exporter export: { snapshot } ] ]
]

{ #category : 'private - processing' }
OTSimpleSpanProcessor >> runExporterOperation: aBlock [

	self exportTimeoutMillis = 0 ifTrue: [ ^ aBlock value ].
	^ aBlock valueWithinMilliseconds: self exportTimeoutMillis onTimeout: [ false ]
]

{ #category : 'private - processing' }
OTSimpleSpanProcessor >> runExporterOperationResultNamed: anOperationName do: aBlock [

	self exportTimeoutMillis = 0 ifTrue: [
		^ OTLifecycleResult fromBoolean: (self exporter withOperationNamed: anOperationName default: false do: aBlock) ].
	^ [ OTLifecycleResult fromBoolean: (self exporter withOperationNamed: anOperationName default: false do: aBlock) ]
		  valueWithinMilliseconds: self exportTimeoutMillis
		  onTimeout: [ OTLifecycleResult timeout ]
]

{ #category : 'processing' }
OTSimpleSpanProcessor >> shutdown [

	| flushed shutdownResult |
	self beginShutdown ifFalse: [ ^ false ].
	flushed := self flush.
	shutdownResult := exportLock critical: [ self runExporterOperation: [ self exporter shutdown ] ].
	self markShutdown.
	^ shutdownResult & flushed
]

{ #category : 'processing' }
OTSimpleSpanProcessor >> shutdownResult [

	| flushed shutdownResult |
	self beginShutdown ifFalse: [ ^ OTLifecycleResult failure ].
	flushed := self flushResult.
	shutdownResult := exportLock critical: [ self runExporterOperationResultNamed: 'shutdown' do: [ self exporter shutdown ] ].
	self markShutdown.
	^ flushed combinedWith: shutdownResult
]

{ #category : 'private - configuration' }
OTSimpleSpanProcessor >> validatedRuntimeInteger: aValue minimum: aMinimum forOperation: anOperationName [

	(aValue isInteger and: [ aValue >= aMinimum ]) ifTrue: [ ^ aValue ].
	self configurationWarningOwner noteInvalidRuntimeConfigurationValue: aValue forOperation: anOperationName.
	^ nil
]
