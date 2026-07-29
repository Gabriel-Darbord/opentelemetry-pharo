Class {
	#name : 'OTMetricExemplarTest',
	#superclass : 'TestCase',
	#instVars : [
		'provider',
		'reader',
		'tracerProvider',
		'tracer'
	],
	#category : 'OpenTelemetry-Metrics-Tests',
	#package : 'OpenTelemetry-Metrics-Tests'
}

{ #category : 'private' }
OTMetricExemplarTest >> assertReservoir: anOTMetricExemplarReservoir staysSafeWithMaximumCollectSize: anInteger measurementBlock: aBlock [

	| collectedBatches collectorCount done errors gate lock offererCount workerCount |
	collectedBatches := OrderedCollection new.
	errors := OrderedCollection new.
	lock := Semaphore forMutualExclusion.
	gate := Semaphore new.
	done := Semaphore new.
	offererCount := 4.
	collectorCount := 2.
	workerCount := offererCount + collectorCount.
	1 to: offererCount do: [ :offererIndex |
			[
				[
					gate wait.
					1 to: 50 do: [ :measurementIndex |
					anOTMetricExemplarReservoir offerMeasurement: (aBlock value: offererIndex value: measurementIndex) ] ]
					on: Error
					do: [ :anError | lock critical: [ errors add: anError ] ].
				done signal ] forkAt: Processor userBackgroundPriority ].
	1 to: collectorCount do: [ :collectorIndex |
			[
				[
					gate wait.
					1 to: 50 do: [ :each |
							| collected |
							collected := anOTMetricExemplarReservoir collectForPointAttributes: { ('status' -> '200') }.
							lock critical: [ collectedBatches add: collected ] ] ]
					on: Error
					do: [ :anError | lock critical: [ errors add: anError ] ].
				done signal ] forkAt: Processor userBackgroundPriority ].
	workerCount timesRepeat: [ gate signal ].
	workerCount timesRepeat: [ self assert: (done waitTimeoutMilliseconds: 2000) not ].
	self assert: errors isEmpty.
	self assert: (collectedBatches allSatisfy: [ :each | each size <= anInteger ]).
	self assert:
		(collectedBatches allSatisfy: [ :each | each allSatisfy: [ :exemplar | exemplar class identicalTo: OTMetricExemplar ] ]).
	self assert: (anOTMetricExemplarReservoir collectForPointAttributes: { ('status' -> '200') }) size <= anInteger
]

{ #category : 'private' }
OTMetricExemplarTest >> currentMetricPoint [

	^ reader collectSnapshot metrics first points first
]

{ #category : 'running' }
OTMetricExemplarTest >> setUp [

	super setUp.
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	provider addMetricReader: reader.
	tracerProvider := OTTracerProvider new
		                  sampler: OTAlwaysOnSampler new;
		                  spanProcessor: OTSimpleSpanProcessor new;
		                  yourself.
	tracer := tracerProvider tracerNamed: 'metrics-tests'
]

{ #category : 'running' }
OTMetricExemplarTest >> tearDown [

	[
		OpenTelemetry currentSpan: nil.
		provider ifNotNil: [ provider shutdown ].
		tracerProvider ifNotNil: [ tracerProvider shutdown ] ] ensure: [ super tearDown ]
]

{ #category : 'tests' }
OTMetricExemplarTest >> testAlignedHistogramBucketReservoirIsSafeUnderConcurrentOfferAndCollect [

	| counter reservoir |
	counter := (provider meterNamed: 'demo.metrics') counterNamed: 'requests.total'.
	reservoir := OTAlignedHistogramBucketMetricExemplarReservoir boundaries: #( 10 20 ).
	self assertReservoir: reservoir staysSafeWithMaximumCollectSize: 3 measurementBlock: [ :offererIndex :measurementIndex |
			| value |
			value := #( 5 15 25 ) at: (offererIndex + measurementIndex - 1 rem: 3) + 1.
			OTMetricMeasurement instrument: counter value: value attributes: { ('worker' -> offererIndex asString) } ]
]

{ #category : 'tests' }
OTMetricExemplarTest >> testDefaultExemplarReservoirUsesAlignedBucketsForExplicitHistogram [

	| context histogram reservoir |
	provider exemplarFilter: OTMetricExemplarFilter alwaysOn.
	histogram := (provider meterNamed: 'demo.metrics')
		             histogramNamed: 'request.duration'
		             unit: 'ms'
		             description: 'Request duration'
		             advice: { ('ExplicitBucketBoundaries' -> #( 10 20 )) } asDictionary.
	context := OTMetricAggregationContext
		           collectedAt: DateAndTime now asUTC
		           startTimestamp: nil
		           temporality: #cumulative
		           aggregation: #default
		           retainedAttributeKeys: nil
		           cardinalityLimit: 2000
		           aggregationParameters: nil
		           exemplarFilter: provider exemplarFilter
		           exemplarReservoirFactory: nil.
	reservoir := context newExemplarReservoirForInstrument: histogram pointAttributes: { ('status' -> '200') }.
	self assert: reservoir class identicalTo: OTAlignedHistogramBucketMetricExemplarReservoir
]

{ #category : 'tests' }
OTMetricExemplarTest >> testDefaultExemplarReservoirUsesConfiguredSimpleReservoirForExponentialHistogram [

	| context histogram reservoir |
	provider exemplarFilter: OTMetricExemplarFilter alwaysOn.
	histogram := (provider meterNamed: 'demo.metrics')
		             histogramNamed: 'request.duration'
		             unit: 'ms'
		             description: 'Request duration'
		             advice: Dictionary new.
	context := OTMetricAggregationContext
		           collectedAt: DateAndTime now asUTC
		           startTimestamp: nil
		           temporality: #cumulative
		           aggregation: #base2ExponentialBucketHistogram
		           retainedAttributeKeys: nil
		           cardinalityLimit: 2000
		           aggregationParameters: { (#maxSize -> 7) } asOrderedDictionary
		           exemplarFilter: provider exemplarFilter
		           exemplarReservoirFactory: nil.
	reservoir := context newExemplarReservoirForInstrument: histogram pointAttributes: { ('status' -> '200') }.
	self assert: reservoir class identicalTo: OTSimpleFixedSizeMetricExemplarReservoir.
	self assert: reservoir size equals: 7
]

{ #category : 'tests' }
OTMetricExemplarTest >> testAlwaysOffFilterSkipsCustomExemplarReservoirCreation [

	| counter factoryCallCount point |
	factoryCallCount := 0.
	provider
		exemplarFilter: OTMetricExemplarFilter alwaysOff;
		addView: ((OTMetricView named: 'requests.total')
				 exemplarReservoirFactory: [ :context :instrument :pointAttributes |
						 factoryCallCount := factoryCallCount + 1.
						 OTRecordingMetricExemplarReservoir new ];
				 yourself).
	counter := (provider meterNamed: 'demo.metrics') counterNamed: 'requests.total'.
	counter add: 1 attributes: { ('status' -> '200') }.
	point := self currentMetricPoint.
	self assert: factoryCallCount equals: 0.
	self assert: point exemplars isEmpty
]

{ #category : 'tests' }
OTMetricExemplarTest >> testAlwaysOnFilterCapturesDroppedAttributesAsExemplarFilteredAttributes [

	| counter exemplar point |
	provider
		exemplarFilter: OTMetricExemplarFilter alwaysOn;
		addView: ((OTMetricView named: 'requests.total')
				 attributeKeys: #( 'status' );
				 yourself).
	counter := (provider meterNamed: 'demo.metrics') counterNamed: 'requests.total'.
	counter add: 1 attributes: {
			('status' -> '200').
			('user' -> 'alice') }.
	point := self currentMetricPoint.
	exemplar := point exemplars first.
	self assert: point value equals: 1.
	self assert: point attributes size equals: 1.
	self assert: (point attributes at: 'status') equals: '200'.
	self assert: exemplar value equals: 1.
	self assert: exemplar filteredAttributes size equals: 1.
	self assert: (exemplar filteredAttributes at: 'user') equals: 'alice'
]

{ #category : 'tests' }
OTMetricExemplarTest >> testExplicitHistogramUsesOneExemplarPerBucket [

	| histogram point values |
	provider exemplarFilter: OTMetricExemplarFilter alwaysOn.
	histogram := (provider meterNamed: 'demo.metrics')
		             histogramNamed: 'request.duration'
		             unit: 'ms'
		             description: 'Request duration'
		             advice: { ('ExplicitBucketBoundaries' -> #( 10 20 )) } asDictionary.
	histogram record: 5.
	histogram record: 7.
	histogram record: 15.
	point := self currentMetricPoint.
	values := (point exemplars collect: [ :each | each value ]) asSortedCollection asArray.
	self assert: values equals: #( 7 15 )
]

{ #category : 'tests' }
OTMetricExemplarTest >> testDefaultExemplarReservoirUsesSizeOneSimpleReservoirForNonHistogramAggregation [

	| context counter reservoir |
	provider exemplarFilter: OTMetricExemplarFilter alwaysOn.
	counter := (provider meterNamed: 'demo.metrics') counterNamed: 'requests.total'.
	context := OTMetricAggregationContext
		           collectedAt: DateAndTime now asUTC
		           startTimestamp: nil
		           temporality: #cumulative
		           aggregation: #default
		           retainedAttributeKeys: nil
		           cardinalityLimit: 2000
		           aggregationParameters: nil
		           exemplarFilter: provider exemplarFilter
		           exemplarReservoirFactory: nil.
	reservoir := context newExemplarReservoirForInstrument: counter pointAttributes: { ('status' -> '200') }.
	self assert: reservoir class identicalTo: OTSimpleFixedSizeMetricExemplarReservoir.
	self assert: reservoir size equals: 1
]

{ #category : 'tests' }
OTMetricExemplarTest >> testSimpleFixedSizeReservoirIsSafeUnderConcurrentOfferAndCollect [

	| counter reservoir |
	counter := (provider meterNamed: 'demo.metrics') counterNamed: 'requests.total'.
	reservoir := OTSimpleFixedSizeMetricExemplarReservoir size: 3.
	self assertReservoir: reservoir staysSafeWithMaximumCollectSize: 3 measurementBlock: [ :offererIndex :measurementIndex |
			OTMetricMeasurement
				instrument: counter
				value: offererIndex * 1000 + measurementIndex
				attributes: { ('worker' -> offererIndex asString) } ]
]

{ #category : 'tests' }
OTMetricExemplarTest >> testTraceBasedFilterCapturesSampledSpanIdentity [

	| counter exemplar point span |
	provider exemplarFilter: OTMetricExemplarFilter traceBased.
	counter := (provider meterNamed: 'demo.metrics') counterNamed: 'requests.total'.
	span := tracer startSpanNamed: 'sampled'.
	OpenTelemetry useSpan: span during: [
			counter add: 1 attributes: {
					('status' -> '200').
					('user' -> 'alice') } ].
	span end.
	point := self currentMetricPoint.
	exemplar := point exemplars first.
	self assert: exemplar traceId equals: span traceId.
	self assert: exemplar spanId equals: span spanId
]

{ #category : 'tests' }
OTMetricExemplarTest >> testTraceBasedFilterSkipsMeasurementsWithoutSampledSpan [

	| counter point |
	provider exemplarFilter: OTMetricExemplarFilter traceBased.
	counter := (provider meterNamed: 'demo.metrics') counterNamed: 'requests.total'.
	counter add: 1 attributes: { ('status' -> '200') }.
	point := self currentMetricPoint.
	self assert: point exemplars isEmpty
]

{ #category : 'tests' }
OTMetricExemplarTest >> testViewCanProvideCustomExemplarReservoir [

	| counter point reservoirs reservoir |
	reservoirs := OrderedCollection new.
	provider
		exemplarFilter: OTMetricExemplarFilter alwaysOn;
		addView: ((OTMetricView named: 'requests.total')
				 attributeKeys: #( 'status' );
				 exemplarReservoirFactory: [ :context :instrument :pointAttributes |
						 | customReservoir |
						 customReservoir := OTRecordingMetricExemplarReservoir new.
						 customReservoir pointAttributes: pointAttributes.
						 reservoirs add: customReservoir.
						 customReservoir ];
				 yourself).
	counter := (provider meterNamed: 'demo.metrics') counterNamed: 'requests.total'.
	counter add: 1 attributes: {
			('status' -> '200').
			('user' -> 'alice') }.
	point := self currentMetricPoint.
	reservoir := reservoirs first.
	self assert: reservoirs size equals: 1.
	self assert: reservoir collectArgument equals: point attributes.
	self assert: reservoir pointAttributes equals: point attributes.
	self assert: reservoir offeredMeasurements size equals: 1.
	self assert: reservoir offeredMeasurements first attributes size equals: 1.
	self assert: (reservoir offeredMeasurements first attributes at: 'status') equals: '200'.
	self assert: reservoir offeredMeasurements first exemplarAttributes size equals: 2.
	self assert: (reservoir offeredMeasurements first exemplarAttributes at: 'user') equals: 'alice'.
	self assert: point exemplars size equals: 1.
	self assert: point exemplars first value equals: 1.
	self assert: (point exemplars first filteredAttributes at: 'user') equals: 'alice'
]
