"
I am a metric reader that periodically collects and exports snapshots through an OTMetricExporter.
I manage the export loop, batching, timing, and shutdown coordination.
"
Class {
	#name : 'OTPeriodicExportingMetricReader',
	#superclass : 'OTMetricReader',
	#instVars : [
		'exporter',
		'exportLock',
		'exportIntervalMillis',
		'exportTimeoutMillis',
		'exportProcess',
		'maxExportBatchSize'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTPeriodicExportingMetricReader class >> exporter: anOTMetricExporter [

	^ self new
		  exporter: anOTMetricExporter;
		  yourself
]

{ #category : 'collecting' }
OTPeriodicExportingMetricReader >> collect [

	^ self collectResult snapshot
]

{ #category : 'collecting' }
OTPeriodicExportingMetricReader >> collectResult [

	| batchResult exportResult |
	self isStopping ifTrue: [
		^ OTMetricBatchResult failureSnapshot: OTMetricSnapshot empty failedReasons: { 'OpenTelemetry metric reader is shutdown' } ].
	^ exportLock critical: [
			  self isStopping ifTrue: [
				  ^ OTMetricBatchResult failureSnapshot: OTMetricSnapshot empty failedReasons: { 'OpenTelemetry metric reader is shutdown' } ].
			  batchResult := self collectSnapshotResult.
			  exportResult := self exportSnapshotResult: batchResult snapshot.
			  ^ batchResult
				    combinedWithLifecycleResult: exportResult
				    failedReason: (self exporterOperationFailureMessageNamed: 'export' result: exportResult) ]
]

{ #category : 'accessing' }
OTPeriodicExportingMetricReader >> defaultAggregationSelector [

	^ self exporter aggregationSelector
]

{ #category : 'accessing' }
OTPeriodicExportingMetricReader >> defaultTemporalitySelector [

	^ self exporter temporalitySelector
]

{ #category : 'callbacks' }
OTPeriodicExportingMetricReader >> didRegisterWithProvider [

	self restartExportProcess
]

{ #category : 'accessing' }
OTPeriodicExportingMetricReader >> exportIntervalMillis [

	^ exportIntervalMillis ifNil: [ 60000 ]
]

{ #category : 'accessing' }
OTPeriodicExportingMetricReader >> exportIntervalMillis: anInteger [

	exportIntervalMillis := anInteger ifNil: [ 60000 ] ifNotNil: [ anInteger max: 1 ].
	self provider ifNotNil: [ self restartExportProcess ].
	^ self exportIntervalMillis
]

{ #category : 'accessing' }
OTPeriodicExportingMetricReader >> exportProcess [

	^ exportProcess
]

{ #category : 'private - exporting' }
OTPeriodicExportingMetricReader >> exportSnapshotResult: anOTMetricSnapshot [

	^ (self exportSnapshotsFrom: anOTMetricSnapshot) inject: OTLifecycleResult success into: [ :allExported :each |
		  allExported combinedWith: (self runExporterOperationResultNamed: 'export' do: [ self exporter export: each ]) ]
]

{ #category : 'private - exporting' }
OTPeriodicExportingMetricReader >> exportSnapshotsFrom: anOTMetricSnapshot [

	| batchSize metrics |
	batchSize := self maxExportBatchSize.
	batchSize ifNil: [ ^ { anOTMetricSnapshot } ].
	metrics := anOTMetricSnapshot metrics.
	metrics isEmpty ifTrue: [ ^ { anOTMetricSnapshot } ].
	^ Array streamContents: [ :stream |
			  | currentBatch currentCount |
			  currentBatch := OrderedCollection new.
			  currentCount := 0.
			  metrics do: [ :eachMetric |
					  | pointIndex points |
					  points := eachMetric points.
					  pointIndex := 1.
					  [ pointIndex <= points size ] whileTrue: [
							  | available chunk endIndex |
							  currentCount = batchSize ifTrue: [
									  stream nextPut: (self snapshot: anOTMetricSnapshot withMetrics: currentBatch).
									  currentBatch := OrderedCollection new.
									  currentCount := 0 ].
							  available := batchSize - currentCount.
							  endIndex := pointIndex + available - 1 min: points size.
							  chunk := points copyFrom: pointIndex to: endIndex.
							  currentBatch add: (self metricData: eachMetric withPoints: chunk).
							  currentCount := currentCount + chunk size.
							  pointIndex := endIndex + 1 ] ].
			  currentBatch ifNotEmpty: [ stream nextPut: (self snapshot: anOTMetricSnapshot withMetrics: currentBatch) ] ]
]

{ #category : 'accessing' }
OTPeriodicExportingMetricReader >> exportTimeoutMillis [

	^ exportTimeoutMillis ifNil: [ 30000 ]
]

{ #category : 'accessing' }
OTPeriodicExportingMetricReader >> exportTimeoutMillis: anInteger [

	exportTimeoutMillis := anInteger ifNil: [ 30000 ] ifNotNil: [ anInteger max: 1 ].
	^ self exportTimeoutMillis
]

{ #category : 'accessing' }
OTPeriodicExportingMetricReader >> exporter [

	^ exporter ifNil: [ exporter := OTNoopMetricExporter new ]
]

{ #category : 'accessing' }
OTPeriodicExportingMetricReader >> exporter: anOTMetricExporter [

	exporter := anOTMetricExporter ifNil: [ OTNoopMetricExporter new ] ifNotNil: [ anOTMetricExporter ].
	^ self exporter
]

{ #category : 'private - logging' }
OTPeriodicExportingMetricReader >> exporterOperationFailureMessageNamed: anOperationName result: anOTLifecycleResult [

	anOTLifecycleResult isSuccess ifTrue: [ ^ nil ].
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'OpenTelemetry metric exporter ';
				  nextPutAll: self exporter class name;
				  nextPutAll: ' ';
				  nextPutAll: anOperationName;
				  nextPutAll: ' ';
				  nextPutAll: (anOTLifecycleResult isTimeout
						   ifTrue: [ 'timed out' ]
						   ifFalse: [ 'failed' ]) ]
]

{ #category : 'lifecycle' }
OTPeriodicExportingMetricReader >> forceFlush [

	^ self forceFlushResult isSuccess
]

{ #category : 'lifecycle' }
OTPeriodicExportingMetricReader >> forceFlushResult [

	| batchResult exportResult flushResult |
	self isStopping ifTrue: [ ^ OTLifecycleResult failure ].
	^ exportLock critical: [
			  self isStopping ifTrue: [ ^ OTLifecycleResult failure ].
			  batchResult := self collectSnapshotResult.
			  exportResult := self exportSnapshotResult: batchResult snapshot.
			  flushResult := self runExporterOperationResultNamed: 'forceFlush' do: [ self exporter forceFlush ].
			  ^ ((batchResult
				      combinedWithLifecycleResult: exportResult
				      failedReason: (self exporterOperationFailureMessageNamed: 'export' result: exportResult))
				     combinedWithLifecycleResult: flushResult
				     failedReason: (self exporterOperationFailureMessageNamed: 'forceFlush' result: flushResult)) asLifecycleResult ]
]

{ #category : 'initialization' }
OTPeriodicExportingMetricReader >> initialize [

	super initialize.
	exportLock := Semaphore forMutualExclusion.
	exportIntervalMillis := 60000.
	exportTimeoutMillis := 30000
]

{ #category : 'accessing' }
OTPeriodicExportingMetricReader >> maxExportBatchSize [

	^ maxExportBatchSize
]

{ #category : 'accessing' }
OTPeriodicExportingMetricReader >> maxExportBatchSize: anInteger [

	maxExportBatchSize := anInteger ifNotNil: [ anInteger max: 1 ].
	^ self maxExportBatchSize
]

{ #category : 'private - exporting' }
OTPeriodicExportingMetricReader >> metricData: anOTMetricData withPoints: someMetricPoints [

	^ anOTMetricData copyWithPoints: someMetricPoints
]

{ #category : 'private - lifecycle' }
OTPeriodicExportingMetricReader >> restartExportProcess [

	self stopExportProcess.
	self startExportProcess
]

{ #category : 'private - lifecycle' }
OTPeriodicExportingMetricReader >> runExporterOperation: aBlock [

	^ (self runExporterOperationResultNamed: 'operation' do: aBlock) isSuccess
]

{ #category : 'private - lifecycle' }
OTPeriodicExportingMetricReader >> runExporterOperationResultNamed: anOperationName do: aBlock [

	^ [ OTLifecycleResult fromBoolean: (self exporter withOperationNamed: anOperationName default: false do: aBlock) ]
		  valueWithinMilliseconds: self exportTimeoutMillis
		  onTimeout: [ OTLifecycleResult timeout ]
]

{ #category : 'lifecycle' }
OTPeriodicExportingMetricReader >> shutdown [

	^ self shutdownResult isSuccess
]

{ #category : 'lifecycle' }
OTPeriodicExportingMetricReader >> shutdownResult [

	| exporterResult |
	self isShutdown ifTrue: [ ^ OTLifecycleResult failure ].
	self beginShutdown ifFalse: [ ^ OTLifecycleResult failure ].
	self stopExportProcess.
	exporterResult := exportLock critical: [ self runExporterOperationResultNamed: 'shutdown' do: [ self exporter shutdown ] ].
	self finishShutdown.
	^ exporterResult
]

{ #category : 'private - exporting' }
OTPeriodicExportingMetricReader >> snapshot: anOTMetricSnapshot withMetrics: someMetrics [

	^ OTMetricSnapshot
		  resource: anOTMetricSnapshot resource
		  measurements: anOTMetricSnapshot measurements
		  metrics: someMetrics
		  collectedAt: anOTMetricSnapshot collectedAt
]

{ #category : 'private - lifecycle' }
OTPeriodicExportingMetricReader >> startExportProcess [

	^ exportLock critical: [
			  self isStopping ifTrue: [ ^ nil ].
			  exportProcess ifNotNil: [ ^ exportProcess ].
			  exportProcess := [
				                   [ self isStopping ] whileFalse: [
						                   (Delay forMilliseconds: self exportIntervalMillis) wait.
						                   self isStopping ifFalse: [ self collect ] ] ] forkAt: Processor userBackgroundPriority.
			  exportProcess ]
]

{ #category : 'private - lifecycle' }
OTPeriodicExportingMetricReader >> stopExportProcess [

	| process |
	process := exportLock critical: [
			           | runningProcess |
			           runningProcess := exportProcess.
			           exportProcess := nil.
			           runningProcess ].
	process ifNotNil: [ process terminate ].
	^ nil
]
