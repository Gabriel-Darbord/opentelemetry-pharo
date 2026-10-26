Class {
	#name : 'OTMetricBatchLifecycleTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Metrics-Tests',
	#package : 'OpenTelemetry-Metrics-Tests'
}

{ #category : 'private' }
OTMetricBatchLifecycleTest >> assertOperation: anOperation failureMode: aMode flushCount: aCount [

	| exporter provider reader counter result |
	exporter := OTFirstBatchFailingMetricExporter new
		            failureMode: aMode;
		            yourself.
	provider := OTMeterProvider new.
	reader := OTPeriodicExportingMetricReader exporter: exporter.
	reader
		exportIntervalMillis: 1000000;
		exportTimeoutMillis: 150;
		maxExportBatchSize: 1.
	provider addMetricReader: reader.
	counter := (provider meterNamed: 'batching') counterNamed: 'requests'.
	1 to: 3 do: [ :index | counter add: index attributes: { ('index' -> index) } ].
	[
		result := anOperation value: reader.
		self assert: result isSuccess equals: aMode = #delay.
		aMode = #timeout ifTrue: [ self assert: result isTimeout ].
		self assert: exporter exports size equals: 3.
		self assert: (exporter exports collect: [ :snapshot | snapshot metrics first points first value ]) asArray equals: #( 1 2 3 ).
		self assert: exporter forceFlushCount equals: aCount ] ensure: [ provider shutdown ]
]

{ #category : 'tests' }
OTMetricBatchLifecycleTest >> testCollectionContinuesAfterFailedBatches [

	#( failure error timeout ) do: [ :mode |
		self assertOperation: [ :reader | reader collectResult ] failureMode: mode flushCount: 0 ]
]

{ #category : 'tests' }
OTMetricBatchLifecycleTest >> testEachBatchGetsItsOwnExportTimeout [

	self assertOperation: [ :reader | reader forceFlushResult ] failureMode: #delay flushCount: 1
]

{ #category : 'tests' }
OTMetricBatchLifecycleTest >> testForceFlushContinuesAfterFailedBatches [

	#( failure error timeout ) do: [ :mode |
		self assertOperation: [ :reader | reader forceFlushResult ] failureMode: mode flushCount: 1 ]
]

{ #category : 'tests' }
OTMetricBatchLifecycleTest >> testShutdownContinuesAfterFailedBatches [

	#( failure error timeout ) do: [ :mode |
		self assertOperation: [ :reader | reader shutdownResult ] failureMode: mode flushCount: 1 ]
]
