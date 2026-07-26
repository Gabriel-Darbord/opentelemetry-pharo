"
I am a metric reader that periodically collects and exports snapshots through an OTMetricExporter.
I manage the export loop, timing, and shutdown coordination.
"
Class {
	#name : 'OTPeriodicExportingMetricReader',
	#superclass : 'OTMetricReader',
	#instVars : [
		'exporter',
		'exportLock',
		'exportIntervalMillis',
		'exportTimeoutMillis',
		'exportProcess'
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
			  self exporter export: snapshot.
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
			  exportResult := self exporter export: snapshot.
			  flushResult := self exporter forceFlush.
			  exportResult & flushResult ]
]

{ #category : 'initialization' }
OTPeriodicExportingMetricReader >> initialize [

	super initialize.
	exportLock := Semaphore forMutualExclusion.
	exportIntervalMillis := 60000.
	exportTimeoutMillis := 30000
]

{ #category : 'private - lifecycle' }
OTPeriodicExportingMetricReader >> restartExportProcess [

	self stopExportProcess.
	self startExportProcess
]

{ #category : 'lifecycle' }
OTPeriodicExportingMetricReader >> shutdown [

	| exporterResult |
	(self beginShutdown) ifFalse: [ ^ false ].
	self stopExportProcess.
	exporterResult := exportLock critical: [ self exporter shutdown ].
	self finishShutdown.
	^ exporterResult
]

{ #category : 'private - lifecycle' }
OTPeriodicExportingMetricReader >> startExportProcess [

	^ exportLock critical: [
			  self isStopping ifTrue: [ ^ nil ].
			  exportProcess ifNotNil: [ ^ exportProcess ].
			  exportProcess := [
				                   [ self isStopping ] whileFalse: [
						                   (Delay forMilliseconds: self exportIntervalMillis) wait.
						                   self isStopping ifFalse: [ self collect ] ] ]
					                   forkAt: Processor userBackgroundPriority.
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
