Class {
	#name : 'OTMetricReaderTest',
	#superclass : 'TestCase',
	#instVars : [
		'provider'
	],
	#category : 'OpenTelemetry-Metrics-Tests',
	#package : 'OpenTelemetry-Metrics-Tests'
}

{ #category : 'private' }
OTMetricReaderTest >> sampleProducerSnapshotNamed: aString [

	| scope |
	scope := OTInstrumentationScope
		         named: 'external.metrics'
		         version: '1.0.0'
		         schemaUrl: 'https://scope.example/schema'
		         attributes: #(  ).
	^ self sampleProducerSnapshotNamed: aString instrumentationScope: scope
]

{ #category : 'private' }
OTMetricReaderTest >> sampleProducerSnapshotNamed: aString instrumentationScope: anOTInstrumentationScope [

	| point resource sumMetric |
	resource := OTResource attributes: { ('service.name' -> 'producer') } schemaUrl: 'https://producer.example/schema'.
	point := OTNumberDataPoint
		         attributes: { ('source' -> 'external') }
		         value: 7
		         startTimestamp: DateAndTime unixEpoch + (Duration nanoSeconds: 1)
		         timestamp: DateAndTime unixEpoch + (Duration nanoSeconds: 2).
	sumMetric := OTSumMetricData new.
	sumMetric
		instrumentationScope: anOTInstrumentationScope;
		name: aString;
		description: 'External count';
		unit: '1';
		points: { point };
		monotonic: true;
		temporality: #cumulative.
	^ OTMetricSnapshot
		  resource: resource
		  measurements: #(  )
		  metrics: { sumMetric }
		  collectedAt: point timestamp
]

{ #category : 'running' }
OTMetricReaderTest >> tearDown [

	[ provider ifNotNil: [ provider shutdown ] ] ensure: [ super tearDown ]
]

{ #category : 'tests' }
OTMetricReaderTest >> testCollectSnapshotDropsProducerMetricStreamFilteredByMetricFilter [

	| filter producer reader snapshot |
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	filter := OTRecordingMetricFilter new.
	filter metricResultBlock: [ :scope :name :kind :unit |
			name = 'external.requests.total'
				ifTrue: [ OTMetricFilter drop ]
				ifFalse: [ OTMetricFilter accept ] ].
	producer := OTRecordingMetricProducer snapshot: (self sampleProducerSnapshotNamed: 'external.requests.total').
	reader
		metricFilter: filter;
		addMetricProducer: producer.
	provider addMetricReader: reader.
	snapshot := reader collectSnapshot.
	self assert: producer produceCount equals: 1.
	self assert: snapshot metrics isEmpty
]

{ #category : 'tests' }
OTMetricReaderTest >> testCollectSnapshotDropsSdkMetricStreamFilteredByMetricFilter [

	| filter reader snapshot |
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	filter := OTRecordingMetricFilter new.
	filter metricResultBlock: [ :scope :name :kind :unit |
			name = 'requests.total'
				ifTrue: [ OTMetricFilter drop ]
				ifFalse: [ OTMetricFilter accept ] ].
	reader metricFilter: filter.
	provider addMetricReader: reader.
	((provider meterNamed: 'demo.metrics') counterNamed: 'requests.total') add: 3.
	snapshot := reader collectSnapshot.
	self assert: snapshot metrics isEmpty
]

{ #category : 'tests' }
OTMetricReaderTest >> testCollectSnapshotIncludesMetricsFromRegisteredMetricProducer [

	| producer providerResource reader snapshot |
	provider := OTMeterProvider new.
	providerResource := OTResource attributes: { ('service.name' -> 'sdk') } schemaUrl: 'https://sdk.example/schema'.
	provider resource: providerResource.
	reader := OTInMemoryMetricReader new.
	producer := OTRecordingMetricProducer snapshot: (self sampleProducerSnapshotNamed: 'external.requests.total').
	reader addMetricProducer: producer.
	provider addMetricReader: reader.
	snapshot := reader collectSnapshot.
	self assert: producer produceCount equals: 1.
	self assert: snapshot resource equals: providerResource.
	self assert: snapshot measurements isEmpty.
	self assert: snapshot metrics size equals: 1.
	self assert: snapshot metrics first name equals: 'external.requests.total'
]

{ #category : 'tests' }
OTMetricReaderTest >> testCollectSnapshotMergesSdkAndMetricProducerMetrics [

	| names producer reader snapshot |
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	producer := OTRecordingMetricProducer snapshot: (self sampleProducerSnapshotNamed: 'external.requests.total').
	reader addMetricProducer: producer.
	provider addMetricReader: reader.
	((provider meterNamed: 'demo.metrics') counterNamed: 'local.requests.total') add: 3.
	snapshot := reader collectSnapshot.
	names := snapshot metrics collect: [ :each | each name ].
	self assert: producer produceCount equals: 1.
	self assert: snapshot metrics size equals: 2.
	self assert: (names includes: 'local.requests.total').
	self assert: (names includes: 'external.requests.total')
]

{ #category : 'tests' }
OTMetricReaderTest >> testCollectSnapshotPartiallyFiltersSdkMetricPoints [

	| filter metric point reader snapshot |
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	filter := OTRecordingMetricFilter new.
	filter
		metricResultBlock: [ :scope :name :kind :unit |
				name = 'requests.total'
					ifTrue: [ OTMetricFilter acceptPartial ]
					ifFalse: [ OTMetricFilter accept ] ];
		attributesResultBlock: [ :scope :name :kind :unit :attributes |
				(attributes at: 'method' ifAbsent: [ nil ]) = 'GET'
					ifTrue: [ OTMetricFilter accept ]
					ifFalse: [ OTMetricFilter drop ] ].
	reader metricFilter: filter.
	provider addMetricReader: reader.
	((provider meterNamed: 'demo.metrics') counterNamed: 'requests.total')
		add: 1 attributes: { ('method' -> 'GET') };
		add: 1 attributes: { ('method' -> 'POST') }.
	snapshot := reader collectSnapshot.
	self assert: snapshot metrics size equals: 1.
	metric := snapshot metrics first.
	self assert: metric points size equals: 1.
	point := metric points first.
	self assert: (point attributes at: 'method') equals: 'GET'
]

{ #category : 'tests' }
OTMetricReaderTest >> testCollectSnapshotPassesMetricFilterToRegisteredMetricProducer [

	| filter producer reader |
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	filter := OTRecordingMetricFilter new.
	producer := OTRecordingMetricProducer snapshot: (self sampleProducerSnapshotNamed: 'external.requests.total').
	reader
		metricFilter: filter;
		addMetricProducer: producer.
	provider addMetricReader: reader.
	reader collectSnapshot.
	self assert: producer produceCount equals: 1.
	self assert: producer lastMetricFilter identicalTo: filter
]

{ #category : 'tests' }
OTMetricReaderTest >> testCollectSnapshotResultIncludesProducerFailureReasonsAndPartialMetrics [

	| names producer reader result |
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	producer := OTRecordingMetricProducer snapshot: (self sampleProducerSnapshotNamed: 'external.requests.total').
	producer produceResultBlock: [ :each | OTMetricBatchResult failureSnapshot: each snapshot failedReasons: { 'producer failed' } ].
	reader addMetricProducer: producer.
	provider addMetricReader: reader.
	((provider meterNamed: 'demo.metrics') counterNamed: 'local.requests.total') add: 3.
	result := reader collectSnapshotResult.
	names := result snapshot metrics collect: [ :each | each name ].
	self assert: result isFailure.
	self assert: producer produceCount equals: 1.
	self assert: result failedReasons equals: #( 'producer failed' ).
	self assert: result snapshot metrics size equals: 2.
	self assert: (names includes: 'local.requests.total').
	self assert: (names includes: 'external.requests.total')
]

{ #category : 'tests' }
OTMetricReaderTest >> testCollectSnapshotResultInjectsProducerInstrumentationScopeWhenMissing [

	| producer reader result scope |
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	scope := OTInstrumentationScope
		         named: 'external.producer'
		         version: '2.0.0'
		         schemaUrl: 'https://producer.example/scope'
		         attributes: #(  ).
	producer := OTRecordingMetricProducer snapshot:
		            (self
			             sampleProducerSnapshotNamed: 'external.requests.total'
			             instrumentationScope: (OTInstrumentationScope named: '')).
	producer instrumentationScope: scope.
	reader addMetricProducer: producer.
	provider addMetricReader: reader.
	result := reader collectSnapshotResult.
	self assert: result isSuccess.
	self assert: result snapshot metrics size equals: 1.
	self assert: result snapshot metrics first instrumentationScope equals: scope
]

{ #category : 'tests' }
OTMetricReaderTest >> testCollectSnapshotResultPassesProviderResourceToRegisteredMetricProducer [

	| producer providerResource reader |
	provider := OTMeterProvider new.
	providerResource := OTResource attributes: { ('service.name' -> 'sdk') } schemaUrl: 'https://sdk.example/schema'.
	provider resource: providerResource.
	reader := OTInMemoryMetricReader new.
	producer := OTRecordingMetricProducer snapshot: (self sampleProducerSnapshotNamed: 'external.requests.total').
	reader addMetricProducer: producer.
	provider addMetricReader: reader.
	reader collectSnapshotResult.
	self assert: producer lastResource equals: providerResource
]

{ #category : 'tests' }
OTMetricReaderTest >> testCollectSnapshotResultReportsAsynchronousCallbackTimeout [

	| instrument reader result |
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	reader callbackTimeoutMillis: 1.
	provider addMetricReader: reader.
	instrument := (provider meterNamed: 'demo.metrics') observableCounterNamed: 'runtime.page_faults' callbacks: { [ :observer |
			              (Delay forMilliseconds: 50) wait.
			              observer observe: 42 attributes: { ('pid' -> '1001') } ] }.
	result := reader collectSnapshotResult.
	self assert: instrument class identicalTo: OTObservableCounter.
	self assert: result isTimeout.
	self assert: result snapshot metrics isEmpty.
	self assert: result failedReasons size equals: 1.
	self assert: (result failedReasons first includesSubstring: 'timed out')
]

{ #category : 'tests' }
OTMetricReaderTest >> testConcurrentDeltaCollectSnapshotConsumesWindowOnce [

	1 to: 10 do: [ :iteration |
			| done errors gate lock meterProvider reader results workerCount |
			meterProvider := OTMeterProvider new.
			reader := OTInMemoryMetricReader new.
			reader temporalitySelector: [ :metricInstrument | #delta ].
			meterProvider addMetricReader: reader.
			((meterProvider meterNamed: 'demo.metrics') counterNamed: 'requests.total') add: 1 attributes: { ('method' -> 'GET') }.
			results := OrderedCollection new.
			errors := OrderedCollection new.
			lock := Semaphore forMutualExclusion.
			gate := Semaphore new.
			done := Semaphore new.
			workerCount := 8.
			workerCount timesRepeat: [
					[
						[
							gate wait.
							lock critical: [ results add: reader collectSnapshot ] ]
							on: Error
							do: [ :anError | lock critical: [ errors add: anError ] ].
						done signal ] forkAt: Processor userBackgroundPriority ].
			workerCount timesRepeat: [ gate signal ].
			workerCount timesRepeat: [ self assert: (done waitTimeoutMilliseconds: 1000) not ].
			self assert: errors isEmpty.
			self assert: results size equals: workerCount.
			self assert: (results count: [ :each | each metrics notEmpty ]) equals: 1.
			self assert: (results detect: [ :each | each metrics notEmpty ]) metrics first points first value equals: 1 ]
]

{ #category : 'tests' }
OTMetricReaderTest >> testConcurrentDeltaCollectSnapshotIsSafe [

	| done errors gate instrument lock reader results workerCount |
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	reader temporalitySelector: [ :metricInstrument | #delta ].
	provider addMetricReader: reader.
	instrument := (provider meterNamed: 'demo.metrics')
		              observableCounterNamed: 'runtime.page_faults'
		              callbacks: { [ :observer | observer observe: 42 attributes: { ('pid' -> '1001') } ] }.
	results := OrderedCollection new.
	errors := OrderedCollection new.
	lock := Semaphore forMutualExclusion.
	gate := Semaphore new.
	done := Semaphore new.
	workerCount := 8.
	workerCount timesRepeat: [
			[
				[
					gate wait.
					lock critical: [ results add: reader collectSnapshot ] ]
					on: Error
					do: [ :anError | lock critical: [ errors add: anError ] ].
				done signal ] forkAt: Processor userBackgroundPriority ].
	workerCount timesRepeat: [ gate signal ].
	workerCount timesRepeat: [ self assert: (done waitTimeoutMilliseconds: 1000) not ].
	self assert: instrument class identicalTo: OTObservableCounter.
	self assert: errors isEmpty.
	self assert: results size equals: workerCount.
	self assert: (results allSatisfy: [ :each | each class = OTMetricSnapshot ])
]

{ #category : 'tests' }
OTMetricReaderTest >> testConcurrentShutdownReturnsTrueOnce [

	| done gate lock reader results workerCount |
	reader := OTRecordingMetricReader new.
	results := OrderedCollection new.
	lock := Semaphore forMutualExclusion.
	gate := Semaphore new.
	done := Semaphore new.
	workerCount := 8.
	workerCount timesRepeat: [
			[
				gate wait.
				lock critical: [ results add: reader shutdown ].
				done signal ] forkAt: Processor userBackgroundPriority ].
	workerCount timesRepeat: [ gate signal ].
	workerCount timesRepeat: [ self assert: (done waitTimeoutMilliseconds: 1000) not ].
	self assert: (results count: [ :each | each ]) equals: 1.
	self assert: (results count: [ :each | each not ]) equals: workerCount - 1.
	self assert: reader isShutdown.
	self assert: reader shutdownCount equals: 1
]

{ #category : 'tests' }
OTMetricReaderTest >> testForceFlushReturnsFalseAfterShutdown [

	| reader |
	reader := OTInMemoryMetricReader new.
	self assert: reader shutdown.
	self deny: reader forceFlush
]
