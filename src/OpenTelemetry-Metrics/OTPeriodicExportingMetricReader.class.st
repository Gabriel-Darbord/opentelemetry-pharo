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

	self isStopping ifTrue: [ ^ OTMetricSnapshot empty ].
	^ exportLock critical: [
			  | snapshot |
			  self isStopping ifTrue: [ ^ OTMetricSnapshot empty ].
			  snapshot := self collectSnapshot.
			  self exportSnapshot: snapshot.
			  snapshot ]
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
OTPeriodicExportingMetricReader >> exportSnapshot: anOTMetricSnapshot [

	^ (self exportSnapshotsFrom: anOTMetricSnapshot) allSatisfy: [ :each | self runExporterOperation: [ self exporter export: each ] ]
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

{ #category : 'lifecycle' }
OTPeriodicExportingMetricReader >> forceFlush [

	self isStopping ifTrue: [ ^ false ].
	^ exportLock critical: [
			  | exportResult flushResult snapshot |
			  self isStopping ifTrue: [ ^ false ].
			  snapshot := self collectSnapshot.
			  exportResult := self exportSnapshot: snapshot.
			  exportResult ifFalse: [ ^ false ].
			  flushResult := self runExporterOperation: [ self exporter forceFlush ].
			  exportResult & flushResult ]
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

	^ [ aBlock value ] valueWithinMilliseconds: self exportTimeoutMillis onTimeout: [ false ]
]

{ #category : 'lifecycle' }
OTPeriodicExportingMetricReader >> shutdown [

	| exporterResult |
	self beginShutdown ifFalse: [ ^ false ].
	self stopExportProcess.
	exporterResult := exportLock critical: [ self exporter shutdown ].
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
