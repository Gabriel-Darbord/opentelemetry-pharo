Class {
	#name : 'OTMeterProviderTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Metrics-Tests',
	#package : 'OpenTelemetry-Metrics-Tests'
}

{ #category : 'private' }
OTMeterProviderTest >> runConcurrentOperations: someAssociations [

	| done errors gate lock results |
	results := OrderedCollection new.
	errors := OrderedCollection new.
	lock := Semaphore forMutualExclusion.
	gate := Semaphore new.
	done := Semaphore new.
	someAssociations do: [ :eachOperation |
			[
				[
					gate wait.
					lock critical: [ results add: eachOperation key -> eachOperation value value ] ]
					on: Error
					do: [ :anError | lock critical: [ errors add: anError ] ].
				done signal ] forkAt: Processor userBackgroundPriority ].
	someAssociations size timesRepeat: [ gate signal ].
	someAssociations size timesRepeat: [ self assert: (done waitTimeoutMilliseconds: 1000) not ].
	^ {
		  results.
		  errors }
]

{ #category : 'private' }
OTMeterProviderTest >> sampleAttributes [

	^ OrderedDictionary new
		  at: 'scope.answer' put: 42;
		  yourself
]

{ #category : 'running' }
OTMeterProviderTest >> tearDown [

	[
		OpenTelemetry meterProvider: nil.
		OTMeter instrumentWarningSink: nil.
		OTMeterProvider meterNameWarningSink: nil.
		OTMeterProvider reset ] ensure: [ super tearDown ]
]

{ #category : 'tests' }
OTMeterProviderTest >> testAsynchronousInstrumentCollectsMeasurementsPerReader [

	| callbackCount measurement provider reader |
	callbackCount := 0.
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	provider addMetricReader: reader.
	(provider meterNamed: 'demo.metrics')
		observableGaugeNamed: 'runtime.memory'
		callbacks: { [ :observer |
				callbackCount := callbackCount + 1.
				observer observe: 42 attributes: { ('state' -> 'used') } ] }
		unit: 'By'
		description: 'Runtime memory'
		advice: Dictionary new.
	self assert: reader collect size equals: 1.
	self assert: callbackCount equals: 1.
	measurement := reader collect first.
	self assert: callbackCount equals: 2.
	self assert: measurement instrument name equals: 'runtime.memory'.
	self assert: measurement value equals: 42.
	self assert: (measurement attributes at: 'state') equals: 'used'
]

{ #category : 'tests' }
OTMeterProviderTest >> testAsynchronousInstrumentCreationAcceptsCallbacksWithoutInvokingThem [

	| callbackCount instrument meter |
	callbackCount := 0.
	meter := OTMeterProvider current meterNamed: 'demo.metrics'.
	instrument := meter
		              observableCounterNamed: 'runtime.cpu'
		              callbacks: { [ callbackCount := callbackCount + 1 ] }
		              unit: '1'
		              description: 'CPU'
		              advice: { ('attributes' -> #( 'state' )) } asDictionary.
	self assert: instrument class identicalTo: OTObservableCounter.
	self assert: instrument meter identicalTo: meter.
	self assert: instrument name equals: 'runtime.cpu'.
	self assert: instrument unit equals: '1'.
	self assert: instrument description equals: 'CPU'.
	self assert: instrument callbacks size equals: 1.
	self assert: callbackCount equals: 0
]

{ #category : 'tests' }
OTMeterProviderTest >> testAsynchronousNoopInstrumentOperationsAreSafe [

	| instrument |
	instrument := OTObservableGauge noop.
	self assert: instrument class identicalTo: OTNoopObservableGauge.
	self deny: instrument enabled.
	self assert: (instrument bind: { ('key' -> 'value') }) identicalTo: instrument.
	self shouldnt: [ instrument observe: 42 ] raise: Error.
	self shouldnt: [ instrument observe: 42 attributes: { ('key' -> 'value') } ] raise: Error
]

{ #category : 'tests' }
OTMeterProviderTest >> testAsynchronousObservableCounterCumulativeSnapshotKeepsStableStartTimestamp [

	| callbackValue firstPoint provider reader secondPoint |
	callbackValue := 5.
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	provider addMetricReader: reader.
	(provider meterNamed: 'demo.metrics')
		observableCounterNamed: 'runtime.page_faults'
		callbacks: { [ :observer | observer observe: callbackValue attributes: { ('pid' -> '1001') } ] }
		unit: '1'
		description: 'Page faults'
		advice: Dictionary new.
	firstPoint := reader collectSnapshot metrics first points first.
	callbackValue := 8.
	secondPoint := reader collectSnapshot metrics first points first.
	self assert: firstPoint value equals: 5.
	self assert: secondPoint value equals: 8.
	self assert: secondPoint startTimestamp equals: firstPoint startTimestamp
]

{ #category : 'tests' }
OTMeterProviderTest >> testAsynchronousObservableCounterCumulativeLateSeriesUsesPriorCollectionTimestampAsStartTimestamp [

	| callbackValues firstPoint latePoint provider reader secondSnapshot |
	callbackValues := OrderedDictionary new
		                  at: '1001' put: 5;
		                  yourself.
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	provider addMetricReader: reader.
	(provider meterNamed: 'demo.metrics')
		observableCounterNamed: 'runtime.page_faults'
		callbacks: { [ :observer |
				callbackValues associationsDo: [ :each |
					observer observe: each value attributes: { ('pid' -> each key) } ] ] }
		unit: '1'
		description: 'Page faults'
		advice: Dictionary new.
	firstPoint := reader collectSnapshot metrics first points first.
	callbackValues := OrderedDictionary new
		                  at: '1001' put: 8;
		                  at: '1002' put: 3;
		                  yourself.
	secondSnapshot := reader collectSnapshot.
	latePoint := secondSnapshot metrics first points
		             detect: [ :each | (each attributes at: 'pid') = '1002' ]
		             ifNone: [ self fail: 'Expected late cumulative asynchronous series' ].
	self assert: latePoint value equals: 3.
	self assert: latePoint startTimestamp equals: firstPoint timestamp
]

{ #category : 'tests' }
OTMeterProviderTest >> testAsynchronousObservableCounterDeltaSnapshotConvertsCumulativeValues [

	| callbackValue firstPoint provider reader secondPoint |
	callbackValue := 5.
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	reader temporalitySelector: [ :instrument | #delta ].
	provider addMetricReader: reader.
	(provider meterNamed: 'demo.metrics')
		observableCounterNamed: 'runtime.page_faults'
		callbacks: { [ :observer | observer observe: callbackValue attributes: { ('pid' -> '1001') } ] }
		unit: '1'
		description: 'Page faults'
		advice: Dictionary new.
	firstPoint := reader collectSnapshot metrics first points first.
	callbackValue := 8.
	secondPoint := reader collectSnapshot metrics first points first.
	self assert: firstPoint value equals: 5.
	self assert: secondPoint value equals: 3.
	self assert: secondPoint startTimestamp equals: firstPoint timestamp
]

{ #category : 'tests' }
OTMeterProviderTest >> testAsynchronousObservableUpDownCounterDeltaSnapshotSupportsSignedDifferences [

	| callbackValue firstPoint provider reader secondPoint |
	callbackValue := 5.
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	reader temporalitySelector: [ :instrument | #delta ].
	provider addMetricReader: reader.
	(provider meterNamed: 'demo.metrics')
		observableUpDownCounterNamed: 'runtime.workers'
		callbacks: { [ :observer | observer observe: callbackValue attributes: { ('pool' -> 'default') } ] }
		unit: '1'
		description: 'Workers'
		advice: Dictionary new.
	firstPoint := reader collectSnapshot metrics first points first.
	callbackValue := 2.
	secondPoint := reader collectSnapshot metrics first points first.
	self assert: firstPoint value equals: 5.
	self assert: secondPoint value equals: -3
]

{ #category : 'tests' }
OTMeterProviderTest >> testAsynchronousObservationOutsideCallbacksIsIgnored [

	| instrument provider reader |
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	provider addMetricReader: reader.
	instrument := (provider meterNamed: 'demo.metrics')
		              observableCounterNamed: 'runtime.cpu'
		              callbacks: #(  )
		              unit: '1'
		              description: 'CPU'
		              advice: Dictionary new.
	instrument observe: 42 attributes: { ('state' -> 'manual') }.
	self assert: reader collect isEmpty
]

{ #category : 'tests' }
OTMeterProviderTest >> testAsynchronousObserverAppliesOneTimestampPerCallback [

	| measurements provider reader timestamps |
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	provider addMetricReader: reader.
	(provider meterNamed: 'demo.metrics')
		observableGaugeNamed: 'runtime.memory'
		callbacks: { [ :observer |
				observer observe: 42 attributes: { ('state' -> 'used') }.
				observer observe: 7 attributes: { ('state' -> 'free') } ] }
		unit: 'By'
		description: 'Runtime memory'
		advice: Dictionary new.
	measurements := reader collect.
	self assert: measurements size equals: 2.
	timestamps := measurements collect: [ :each | each timestamp ].
	self assert: timestamps asSet size equals: 1
]

{ #category : 'tests' }
OTMeterProviderTest >> testAsynchronousObserverIgnoresNonFiniteMeasurements [

	| measurement measurements provider reader |
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	provider addMetricReader: reader.
	(provider meterNamed: 'demo.metrics')
		observableGaugeNamed: 'runtime.memory'
		callbacks: { [ :observer |
				observer observe: Float nan.
				observer observe: Float infinity.
				observer observe: Float negativeInfinity.
				observer observe: 42 attributes: { ('state' -> 'used') } ] }
		unit: 'By'
		description: 'Runtime memory'
		advice: Dictionary new.
	measurements := reader collect.
	self assert: measurements size equals: 1.
	measurement := measurements first.
	self assert: measurement instrument name equals: 'runtime.memory'.
	self assert: measurement value equals: 42.
	self assert: (measurement attributes at: 'state') equals: 'used'
]

{ #category : 'tests' }
OTMeterProviderTest >> testBoundWrapperAcceptsAdditionalAttributes [

	| bound counter meter |
	meter := OTMeterProvider current meterNamed: 'demo.metrics'.
	counter := meter counterNamed: 'requests.total'.
	bound := counter bind: { ('method' -> 'GET') }.
	self shouldnt: [ bound add: 1 ] raise: Error.
	self shouldnt: [ bound add: 1 attributes: { ('status' -> 200) } ] raise: Error
]

{ #category : 'tests' }
OTMeterProviderTest >> testBoundWrapperRecordsMergedMeasurements [

	| bound measurement provider |
	provider := OTMeterProvider new.
	bound := ((provider meterNamed: 'demo.metrics') counterNamed: 'requests.total') bind: { ('method' -> 'GET') }.
	bound add: 1 attributes: { ('status' -> 200) }.
	self assert: provider measurements size equals: 1.
	measurement := provider measurements first.
	self assert: (measurement attributes at: 'method') equals: 'GET'.
	self assert: (measurement attributes at: 'status') equals: 200
]

{ #category : 'tests' }
OTMeterProviderTest >> testConcurrentDeltaReadersDoNotShareCollectionState [

	| done errors firstDeltaReader firstResults gate lock provider secondDeltaReader secondResults |
	provider := OTMeterProvider new.
	firstDeltaReader := OTInMemoryMetricReader new.
	firstDeltaReader temporalitySelector: [ :instrument | #delta ].
	secondDeltaReader := OTInMemoryMetricReader new.
	secondDeltaReader temporalitySelector: [ :instrument | #delta ].
	provider
		addMetricReader: firstDeltaReader;
		addMetricReader: secondDeltaReader.
	lock := Semaphore forMutualExclusion.
	errors := OrderedCollection new.
	firstResults := OrderedCollection new.
	secondResults := OrderedCollection new.
	((provider meterNamed: 'demo.metrics') counterNamed: 'requests.total') add: 1.
	2 timesRepeat: [
			gate := Semaphore new.
			done := Semaphore new.
			[
				[
					| snapshot |
					gate wait.
					snapshot := firstDeltaReader collectSnapshot.
					lock critical: [ firstResults add: snapshot ] ]
					on: Error
					do: [ :anError | lock critical: [ errors add: anError ] ].
				done signal ] forkAt: Processor userBackgroundPriority.
			[
				[
					| snapshot |
					gate wait.
					snapshot := secondDeltaReader collectSnapshot.
					lock critical: [ secondResults add: snapshot ] ]
					on: Error
					do: [ :anError | lock critical: [ errors add: anError ] ].
				done signal ] forkAt: Processor userBackgroundPriority.
			2 timesRepeat: [ gate signal ].
			2 timesRepeat: [ self assert: (done waitTimeoutMilliseconds: 1000) not ].
			firstResults size = 1 ifTrue: [ ((provider meterNamed: 'demo.metrics') counterNamed: 'requests.total') add: 2 ] ].
	self assert: errors isEmpty.
	self assert: firstResults size equals: 2.
	self assert: secondResults size equals: 2.
	self assert: firstResults first metrics first points first value equals: 1.
	self assert: secondResults first metrics first points first value equals: 1.
	self assert: firstResults second metrics first points first value equals: 2.
	self assert: secondResults second metrics first points first value equals: 2
]

{ #category : 'tests' }
OTMeterProviderTest >> testConcurrentForceFlushIsSafe [

	| done gate lock provider reader results workerCount |
	provider := OTMeterProvider new.
	reader := OTRecordingMetricReader new.
	provider addMetricReader: reader.
	results := OrderedCollection new.
	lock := Semaphore forMutualExclusion.
	gate := Semaphore new.
	done := Semaphore new.
	workerCount := 8.
	workerCount timesRepeat: [
			[
				gate wait.
				lock critical: [ results add: provider forceFlush ].
				done signal ] forkAt: Processor userBackgroundPriority ].
	workerCount timesRepeat: [ gate signal ].
	workerCount timesRepeat: [ self assert: (done waitTimeoutMilliseconds: 1000) not ].
	self assert: (results allSatisfy: [ :each | each ]).
	self assert: reader forceFlushCount equals: workerCount
]

{ #category : 'tests' }
OTMeterProviderTest >> testConcurrentMeterCreationReturnsIdenticalMeter [

	| done gate lock provider results workerCount |
	provider := OTMeterProvider new.
	results := OrderedCollection new.
	lock := Semaphore forMutualExclusion.
	gate := Semaphore new.
	done := Semaphore new.
	workerCount := 8.
	workerCount timesRepeat: [
			[
				gate wait.
				lock critical: [ results add: (provider meterNamed: 'demo.metrics') ].
				done signal ] forkAt: Processor userBackgroundPriority ].
	workerCount timesRepeat: [ gate signal ].
	workerCount timesRepeat: [ self assert: (done waitTimeoutMilliseconds: 1000) not ].
	self assert: results notEmpty.
	self assert: results asSet size equals: 1.
	self assert: results first class identicalTo: OTMeter
]

{ #category : 'tests' }
OTMeterProviderTest >> testConcurrentShutdownReturnsTrueOnce [

	| done gate lock provider reader results workerCount |
	provider := OTMeterProvider new.
	reader := OTRecordingMetricReader new.
	provider addMetricReader: reader.
	results := OrderedCollection new.
	lock := Semaphore forMutualExclusion.
	gate := Semaphore new.
	done := Semaphore new.
	workerCount := 8.
	workerCount timesRepeat: [
			[
				gate wait.
				lock critical: [ results add: provider shutdown ].
				done signal ] forkAt: Processor userBackgroundPriority ].
	workerCount timesRepeat: [ gate signal ].
	workerCount timesRepeat: [ self assert: (done waitTimeoutMilliseconds: 1000) not ].
	self assert: (results count: [ :each | each ]) equals: 1.
	self assert: (results count: [ :each | each not ]) equals: workerCount - 1.
	self assert: provider isShutdown.
	self assert: reader shutdownCount equals: 1
]

{ #category : 'tests' }
OTMeterProviderTest >> testCurrentProviderUsesConfiguredResourceDefaults [

	| resource |
	resource := OTMeterProvider current resource.
	self assert: (resource attributeAt: 'telemetry.sdk.name') equals: 'opentelemetry'
]

{ #category : 'tests' }
OTMeterProviderTest >> testDeltaMetricReaderCollectsOnlyNewCounterMeasurements [

	| firstMetric firstPoint provider reader secondMetric secondPoint secondSnapshot |
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	reader temporalitySelector: [ :instrument | #delta ].
	provider addMetricReader: reader.
	((provider meterNamed: 'demo.metrics') counterNamed: 'requests.total') add: 1 attributes: { ('method' -> 'GET') }.
	firstMetric := reader collectSnapshot metrics first.
	firstPoint := firstMetric points first.
	self assert: firstMetric temporality equals: #delta.
	self assert: firstPoint value equals: 1.
	((provider meterNamed: 'demo.metrics') counterNamed: 'requests.total') add: 2 attributes: { ('method' -> 'GET') }.
	secondSnapshot := reader collectSnapshot.
	secondMetric := secondSnapshot metrics first.
	secondPoint := secondMetric points first.
	self assert: secondMetric temporality equals: #delta.
	self assert: secondPoint value equals: 2.
	self assert: secondPoint startTimestamp equals: firstPoint timestamp
]

{ #category : 'tests' }
OTMeterProviderTest >> testDeltaMetricReaderSkipsUnchangedSeries [

	| provider reader |
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	reader temporalitySelector: [ :instrument | #delta ].
	provider addMetricReader: reader.
	((provider meterNamed: 'demo.metrics') counterNamed: 'requests.total') add: 1.
	self assert: reader collectSnapshot metrics size equals: 1.
	self assert: reader collectSnapshot metrics isEmpty
]

{ #category : 'tests' }
OTMeterProviderTest >> testDisabledInstrumentDoesNotRecordMeasurements [

	| instrument provider |
	provider := OTMeterProvider new.
	provider meterConfigurator: [ :scope | false ].
	instrument := (provider meterNamed: 'demo.metrics') counterNamed: 'requests.total'.
	instrument add: 1 attributes: { ('method' -> 'GET') }.
	self assert: provider measurements isEmpty
]

{ #category : 'tests' }
OTMeterProviderTest >> testDisabledObservableInstrumentDoesNotCollectMeasurements [

	| provider reader |
	provider := OTMeterProvider new.
	provider meterConfigurator: [ :scope | false ].
	reader := OTInMemoryMetricReader new.
	provider addMetricReader: reader.
	(provider meterNamed: 'demo.metrics')
		observableGaugeNamed: 'runtime.memory'
		callbacks: { [ :observer | observer observe: 42 ] }
		unit: 'By'
		description: 'Runtime memory'
		advice: Dictionary new.
	self assert: reader collect isEmpty
]

{ #category : 'tests' }
OTMeterProviderTest >> testDistinctMeterRequestsReturnDistinctMeters [

	| first second provider |
	provider := OTMeterProvider new.
	first := provider meterNamed: 'first'.
	second := provider
		          meterNamed: 'second'
		          version: '1.2.3'
		          schemaUrl: 'https://opentelemetry.io/schemas/1.0.0'
		          attributes: { ('component' -> 'worker') }.
	self deny: first identicalTo: second
]

{ #category : 'tests' }
OTMeterProviderTest >> testEmptyMeterNameWarnsAndReturnsFallbackMeter [

	self withMeterNameWarningsDo: [ :warnings |
			| meter provider |
			provider := OTMeterProvider new.
			meter := provider meterNamed: ''.
			self assert: meter instrumentationName equals: ''.
			self assert: warnings asArray equals: { ('OpenTelemetry meter name was invalid: ' , '' printString) } ]
]

{ #category : 'tests' }
OTMeterProviderTest >> testExplicitMeterProviderCanBeInstalledGlobally [

	| provider |
	provider := OTMeterProvider new.
	OpenTelemetry meterProvider: provider.
	self assert: OpenTelemetry meterProvider identicalTo: provider
]

{ #category : 'tests' }
OTMeterProviderTest >> testForceFlushAnswersSuccess [

	self assert: OTMeterProvider new forceFlush
]

{ #category : 'tests' }
OTMeterProviderTest >> testForceFlushReturnsFalseAfterShutdown [

	| provider reader |
	provider := OTMeterProvider new.
	reader := OTRecordingMetricReader new.
	provider addMetricReader: reader.
	self assert: provider shutdown.
	self deny: provider forceFlush.
	self assert: reader forceFlushCount equals: 0
]

{ #category : 'tests' }
OTMeterProviderTest >> testGaugeAggregationUsesCollectionTimeAsPointTimestamp [

	| collectedAt context gauge measurement metric point provider |
	provider := OTMeterProvider new.
	gauge := (provider meterNamed: 'demo.metrics') gaugeNamed: 'queue.depth'.
	measurement := OTMetricMeasurement instrument: gauge value: 7 attributes: { ('queue' -> 'main') }.
	measurement timestamp: DateAndTime unixEpoch + (Duration seconds: 5).
	collectedAt := DateAndTime unixEpoch + (Duration seconds: 10).
	context := OTMetricAggregationContext collectedAt: collectedAt startTimestamp: nil temporality: #cumulative.
	metric := gauge metricDataFromMeasurements: { measurement } using: context.
	point := metric points first.
	self assert: point value equals: 7.
	self assert: point startTimestamp equals: measurement timestamp.
	self assert: point timestamp equals: collectedAt
]

{ #category : 'tests' }
OTMeterProviderTest >> testInMemoryMetricReaderCollectsRecordedMeasurements [

	| counter measurement provider reader |
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	provider addMetricReader: reader.
	counter := (provider meterNamed: 'demo.metrics') counterNamed: 'requests.total'.
	counter add: 1 attributes: { ('method' -> 'GET') }.
	self assert: reader collect size equals: 1.
	measurement := reader collect first.
	self assert: measurement instrument identicalTo: counter.
	self assert: measurement value equals: 1.
	self assert: (measurement attributes at: 'method') equals: 'GET'
]

{ #category : 'tests' }
OTMeterProviderTest >> testInMemoryMetricReaderCollectsSynchronousAndAsynchronousMeasurements [

	| measurements provider reader |
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	provider addMetricReader: reader.
	((provider meterNamed: 'demo.metrics') counterNamed: 'requests.total') add: 1 attributes: { ('method' -> 'GET') }.
	(provider meterNamed: 'demo.metrics')
		observableGaugeNamed: 'runtime.memory'
		callbacks: { [ :observer | observer observe: 42 attributes: { ('state' -> 'used') } ] }
		unit: 'By'
		description: 'Runtime memory'
		advice: Dictionary new.
	measurements := reader collect.
	self assert: measurements size equals: 2.
	self assert: (measurements anySatisfy: [ :each | each instrument name = 'requests.total' ]).
	self assert: (measurements anySatisfy: [ :each | each instrument name = 'runtime.memory' ])
]

{ #category : 'tests' }
OTMeterProviderTest >> testIndependentDeltaReadersDoNotShareCollectionState [

	| firstDeltaReader provider secondDeltaReader |
	provider := OTMeterProvider new.
	firstDeltaReader := OTInMemoryMetricReader new.
	firstDeltaReader temporalitySelector: [ :instrument | #delta ].
	secondDeltaReader := OTInMemoryMetricReader new.
	secondDeltaReader temporalitySelector: [ :instrument | #delta ].
	provider
		addMetricReader: firstDeltaReader;
		addMetricReader: secondDeltaReader.
	((provider meterNamed: 'demo.metrics') counterNamed: 'requests.total') add: 1.
	self assert: firstDeltaReader collectSnapshot metrics first points first value equals: 1.
	self assert: secondDeltaReader collectSnapshot metrics first points first value equals: 1.
	((provider meterNamed: 'demo.metrics') counterNamed: 'requests.total') add: 2.
	self assert: firstDeltaReader collectSnapshot metrics first points first value equals: 2.
	self assert: secondDeltaReader collectSnapshot metrics first points first value equals: 2
]

{ #category : 'tests' }
OTMeterProviderTest >> testMeterConfiguratorCanDisableExistingMeterInstruments [

	| instrument meter provider |
	provider := OTMeterProvider new.
	meter := provider meterNamed: 'demo.metrics'.
	instrument := meter counterNamed: 'requests.total'.
	self assert: instrument enabled.
	provider meterConfigurator: [ :scope | false ].
	self deny: instrument enabled
]

{ #category : 'tests' }
OTMeterProviderTest >> testMeterConfiguratorCanDisableSpecificMeters [

	| disabled enabled provider |
	provider := OTMeterProvider new.
	provider meterConfigurator: [ :scope |
			scope name = 'disabled.scope'
				ifTrue: [ OTMeterConfig enabled: false ]
				ifFalse: [ OTMeterConfig enabled: true ] ].
	disabled := (provider meterNamed: 'disabled.scope') counterNamed: 'requests.total'.
	enabled := (provider meterNamed: 'enabled.scope') counterNamed: 'requests.total'.
	self deny: disabled enabled.
	self assert: enabled enabled
]

{ #category : 'tests' }
OTMeterProviderTest >> testMeterConfiguratorNilResultFallsBackToDefaultEnabled [

	| instrument provider |
	provider := OTMeterProvider new.
	provider meterConfigurator: [ :scope | nil ].
	instrument := (provider meterNamed: 'demo.metrics') counterNamed: 'requests.total'.
	self assert: instrument enabled
]

{ #category : 'tests' }
OTMeterProviderTest >> testMeterCreationReturnsNoopInstruments [

	| meter |
	meter := OTMeterProvider current meterNamed: 'demo.metrics'.
	self assert: (meter counterNamed: 'requests') class identicalTo: OTCounter.
	self assert: (meter upDownCounterNamed: 'queue.depth') class identicalTo: OTUpDownCounter.
	self assert: (meter histogramNamed: 'request.duration') class identicalTo: OTHistogram.
	self assert: (meter gaugeNamed: 'cache.size') class identicalTo: OTGauge.
	self assert: (meter observableGaugeNamed: 'runtime.memory') class identicalTo: OTObservableGauge.
	self assert: (meter observableUpDownCounterNamed: 'workers') class identicalTo: OTObservableUpDownCounter
]

{ #category : 'tests' }
OTMeterProviderTest >> testMeterDelegatesResourceToProvider [

	| meter provider resource |
	resource := OTResource attributes: {
			            ('service.name' -> 'metrics-service').
			            ('service.version' -> '1.2.3') }.
	provider := OTMeterProvider new.
	provider resource: resource.
	meter := provider meterNamed: 'demo.metrics'.
	self assert: meter resource equals: resource
]

{ #category : 'tests' }
OTMeterProviderTest >> testMeterExposesInstrumentationScopeMetadata [

	| meter |
	meter := OTMeterProvider current
		         meterNamed: 'demo.metrics'
		         version: '1.2.3'
		         schemaUrl: 'https://opentelemetry.io/schemas/1.0.0'
		         attributes: self sampleAttributes.
	self assert: meter instrumentationName equals: 'demo.metrics'.
	self assert: meter instrumentationVersion equals: '1.2.3'.
	self assert: meter schemaUrl equals: 'https://opentelemetry.io/schemas/1.0.0'.
	self assert: (meter scopeAttributes at: 'scope.answer') equals: 42
]

{ #category : 'tests' }
OTMeterProviderTest >> testMeterProviderAcceptsRichMeterParametersWithoutValidation [

	| meter provider |
	provider := OTMeterProvider new.
	meter := provider
		         meterNamed: nil
		         version: 42
		         schemaUrl: Object new
		         attributes: {
				         ('scope.answer' -> 42).
				         (#component -> 'worker') }.
	self deny: meter isNoop
]

{ #category : 'tests' }
OTMeterProviderTest >> testMeterProviderCachesByFullInstrumentationScope [

	| first second third provider |
	provider := OTMeterProvider new.
	first := provider
		         meterNamed: 'demo.metrics'
		         version: '1.2.3'
		         schemaUrl: 'https://opentelemetry.io/schemas/1.0.0'
		         attributes: self sampleAttributes.
	second := provider
		          meterNamed: 'demo.metrics'
		          version: '1.2.3'
		          schemaUrl: 'https://opentelemetry.io/schemas/1.0.0'
		          attributes: self sampleAttributes.
	third := provider
		         meterNamed: 'demo.metrics'
		         version: '2.0.0'
		         schemaUrl: ''
		         attributes: #(  ).
	self assert: first identicalTo: second.
	self deny: first identicalTo: third
]

{ #category : 'tests' }
OTMeterProviderTest >> testMeterReturnsIdenticalInstrumentForIdenticalRegistration [

	| first second meter |
	meter := OTMeterProvider current meterNamed: 'demo.metrics'.
	first := meter
		         counterNamed: 'requests.total'
		         unit: '1'
		         description: 'Request count'
		         advice: { ('attributes' -> #( 'method' )) } asDictionary.
	second := meter
		          counterNamed: 'requests.total'
		          unit: '1'
		          description: 'Request count'
		          advice: { ('attributes' -> #( 'method' )) } asDictionary.
	self assert: first identicalTo: second
]

{ #category : 'tests' }
OTMeterProviderTest >> testMeterReturnsRealInstrumentMetadata [

	| instrument meter |
	meter := OTMeterProvider current meterNamed: 'demo.metrics'.
	instrument := meter
		              histogramNamed: 'request.duration'
		              unit: 'ms'
		              description: 'Request duration'
		              advice: { ('attributes' -> #( 'method' )) } asDictionary.
	self assert: instrument meter identicalTo: meter.
	self assert: instrument name equals: 'request.duration'.
	self assert: instrument unit equals: 'ms'.
	self assert: instrument description equals: 'Request duration'.
	self assert: (instrument advice at: 'attributes') equals: #( 'method' )
]

{ #category : 'tests' }
OTMeterProviderTest >> testMeterWarnsAndReusesFirstSeenAdviceForIdenticalInstrument [

	self withInstrumentWarningsDo: [ :warnings |
			| first second meter |
			meter := OTMeterProvider current meterNamed: 'demo.metrics'.
			first := meter
				         counterNamed: 'requests.total'
				         unit: '1'
				         description: 'Request count'
				         advice: { ('attributes' -> #( 'method' )) } asDictionary.
			second := meter
				          counterNamed: 'requests.total'
				          unit: '1'
				          description: 'Request count'
				          advice: { ('attributes' -> #( 'status' )) } asDictionary.
			self assert: second identicalTo: first.
			self assert: (second advice at: 'attributes') equals: #( 'method' ).
			self assert: warnings size equals: 1 ]
]

{ #category : 'tests' }
OTMeterProviderTest >> testMeterWarnsAndReusesFirstSeenNameCasing [

	self withInstrumentWarningsDo: [ :warnings |
			| first second meter |
			meter := OTMeterProvider current meterNamed: 'demo.metrics'.
			first := meter
				         counterNamed: 'requestCount'
				         unit: '1'
				         description: ''
				         advice: Dictionary new.
			second := meter
				          counterNamed: 'RequestCount'
				          unit: '1'
				          description: ''
				          advice: Dictionary new.
			self assert: second identicalTo: first.
			self assert: second name equals: 'requestCount'.
			self assert: warnings size equals: 1 ]
]

{ #category : 'tests' }
OTMeterProviderTest >> testMeterWarnsOnDuplicateInstrumentRegistrationWithDifferentDescription [

	self withInstrumentWarningsDo: [ :warnings |
			| first second meter |
			meter := OTMeterProvider current meterNamed: 'demo.metrics'.
			first := meter
				         counterNamed: 'requests.total'
				         unit: '1'
				         description: 'First'
				         advice: Dictionary new.
			second := meter
				          counterNamed: 'requests.total'
				          unit: '1'
				          description: 'Second'
				          advice: Dictionary new.
			self deny: second identicalTo: first.
			self assert: warnings size equals: 1 ]
]

{ #category : 'tests' }
OTMeterProviderTest >> testMeterWarnsOnInvalidInstrumentNamesAndPreservesOriginalText [

	self withInstrumentWarningsDo: [ :warnings |
			| instrument meter |
			meter := OTMeterProvider current meterNamed: 'demo.metrics'.
			instrument := meter
				              counterNamed: '1 requests'
				              unit: '1'
				              description: ''
				              advice: Dictionary new.
			self assert: instrument name equals: '1 requests'.
			self assert: warnings size equals: 1 ]
]

{ #category : 'tests' }
OTMeterProviderTest >> testMetricReaderCollectSnapshotIncludesResourceAndMeasurements [

	| provider reader resource snapshot |
	resource := OTResource attributes: {
			            ('service.name' -> 'metrics-service').
			            ('service.version' -> '1.2.3') }.
	provider := OTMeterProvider new.
	provider resource: resource.
	reader := OTInMemoryMetricReader new.
	provider addMetricReader: reader.
	((provider meterNamed: 'demo.metrics') counterNamed: 'requests.total') add: 1 attributes: { ('method' -> 'GET') }.
	snapshot := reader collectSnapshot.
	self assert: snapshot resource equals: resource.
	self assert: snapshot measurements size equals: 1
]

{ #category : 'tests' }
OTMeterProviderTest >> testMetricReaderRejectsRegistrationWithDifferentProvider [

	| firstProvider secondProvider reader |
	firstProvider := OTMeterProvider new.
	secondProvider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	firstProvider addMetricReader: reader.
	self should: [ secondProvider addMetricReader: reader ] raise: Error
]

{ #category : 'tests' }
OTMeterProviderTest >> testMetricSnapshotAggregatesCounterMeasurementsAsMonotonicSums [

	| metric point provider reader snapshot |
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	provider addMetricReader: reader.
	((provider meterNamed: 'demo.metrics') counterNamed: 'requests.total') add: 1 attributes: { ('method' -> 'GET') }.
	((provider meterNamed: 'demo.metrics') counterNamed: 'requests.total') add: 2 attributes: { ('method' -> 'GET') }.
	snapshot := reader collectSnapshot.
	self assert: snapshot metrics size equals: 1.
	metric := snapshot metrics first.
	self assert: metric class identicalTo: OTSumMetricData.
	self assert: metric monotonic.
	self assert: metric temporality equals: #cumulative.
	point := metric points first.
	self assert: point value equals: 3.
	self assert: point startTimestamp equals: provider measurements first timestamp.
	self assert: point timestamp equals: snapshot collectedAt.
	self assert: (point attributes at: 'method') equals: 'GET'
]

{ #category : 'tests' }
OTMeterProviderTest >> testMetricSnapshotAggregatesGaugeMeasurementsAsLastValue [

	| gaugeMetric point provider reader snapshot |
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	provider addMetricReader: reader.
	((provider meterNamed: 'demo.metrics') gaugeNamed: 'queue.depth') record: 3 attributes: { ('queue' -> 'main') }.
	((provider meterNamed: 'demo.metrics') gaugeNamed: 'queue.depth') record: 7 attributes: { ('queue' -> 'main') }.
	snapshot := reader collectSnapshot.
	gaugeMetric := snapshot metrics first.
	self assert: gaugeMetric class identicalTo: OTGaugeMetricData.
	point := gaugeMetric points first.
	self assert: point value equals: 7
]

{ #category : 'tests' }
OTMeterProviderTest >> testMetricSnapshotAggregatesHistogramMeasurementsWithExplicitBucketBoundaries [

	| histogramMetric point provider reader snapshot |
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	provider addMetricReader: reader.
	((provider meterNamed: 'demo.metrics')
		 histogramNamed: 'request.duration'
		 unit: 'ms'
		 description: 'Request duration'
		 advice: { ('ExplicitBucketBoundaries' -> #( 10 20 )) } asDictionary) record: 5.
	((provider meterNamed: 'demo.metrics')
		 histogramNamed: 'request.duration'
		 unit: 'ms'
		 description: 'Request duration'
		 advice: { ('ExplicitBucketBoundaries' -> #( 10 20 )) } asDictionary) record: 15.
	((provider meterNamed: 'demo.metrics')
		 histogramNamed: 'request.duration'
		 unit: 'ms'
		 description: 'Request duration'
		 advice: { ('ExplicitBucketBoundaries' -> #( 10 20 )) } asDictionary) record: 25.
	snapshot := reader collectSnapshot.
	histogramMetric := snapshot metrics first.
	self assert: histogramMetric class identicalTo: OTHistogramMetricData.
	self assert: histogramMetric temporality equals: #cumulative.
	point := histogramMetric points first.
	self assert: point count equals: 3.
	self assert: point sum equals: 45.
	self assert: point min equals: 5.
	self assert: point max equals: 25.
	self assert: point timestamp equals: snapshot collectedAt.
	self assert: point explicitBounds equals: #( 10.0 20.0 ).
	self assert: point bucketCounts equals: #( 1 1 1 )
]

{ #category : 'tests' }
OTMeterProviderTest >> testMetricSnapshotIgnoresInvalidExplicitBucketBoundariesAdviceAndWarns [

	self withInstrumentWarningsDo: [ :warnings |
			| histogramMetric instrument point provider reader snapshot |
			provider := OTMeterProvider new.
			reader := OTInMemoryMetricReader new.
			provider addMetricReader: reader.
			instrument := (provider meterNamed: 'demo.metrics')
				              histogramNamed: 'request.duration'
				              unit: 'ms'
				              description: 'Request duration'
				              advice: { ('ExplicitBucketBoundaries' -> #( 10 5 )) } asDictionary.
			instrument record: 7.
			snapshot := reader collectSnapshot.
			histogramMetric := snapshot metrics first.
			point := histogramMetric points first.
			self deny: (instrument advice includesKey: 'ExplicitBucketBoundaries').
			self assert: point explicitBounds equals: #( 0.0 5.0 10.0 25.0 50.0 75.0 100.0 250.0 500.0 750.0 1000.0 2500.0 5000.0 7500.0 10000.0 ).
			self assert: warnings size equals: 1.
			self assert: (warnings first includesSubstring: 'ExplicitBucketBoundaries').
			self assert: (warnings first includesSubstring: 'invalid and has been ignored') ]
]

{ #category : 'tests' }
OTMeterProviderTest >> testMetricSnapshotUsesAdvisedAttributeSubsetWhenAggregating [

	| metric point provider reader snapshot |
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	provider addMetricReader: reader.
	((provider meterNamed: 'demo.metrics')
		 counterNamed: 'requests.total'
		 unit: '1'
		 description: 'Request count'
		 advice: { ('Attributes' -> #( 'method' )) } asDictionary) add: 1 attributes: {
			('method' -> 'GET').
			('status' -> 200) }.
	snapshot := reader collectSnapshot.
	metric := snapshot metrics first.
	point := metric points first.
	self assert: point attributes size equals: 1.
	self assert: (point attributes at: 'method') equals: 'GET'
]

{ #category : 'tests' }
OTMeterProviderTest >> testNewProviderDefaultsResourceToEmpty [

	self assert: OTMeterProvider new resource equals: OTResource empty
]

{ #category : 'tests' }
OTMeterProviderTest >> testNilAndEmptyMeterNamesReturnDistinctMeters [

	| emptyMeter nilMeter provider |
	provider := OTMeterProvider new.
	nilMeter := provider meterNamed: nil.
	emptyMeter := provider meterNamed: ''.
	self deny: nilMeter identicalTo: emptyMeter.
	self assert: nilMeter instrumentationName isNil.
	self assert: emptyMeter instrumentationName equals: ''
]

{ #category : 'tests' }
OTMeterProviderTest >> testNilMeterNameReturnsFallbackMeterAndWarns [

	self withMeterNameWarningsDo: [ :warnings |
			| meter provider |
			provider := OTMeterProvider new.
			meter := provider meterNamed: nil.
			self assert: meter instrumentationName isNil.
			self assert: warnings asArray equals: #( 'OpenTelemetry meter name was invalid: nil' ) ]
]

{ #category : 'tests' }
OTMeterProviderTest >> testNoopAsyncInstrumentDoesNotRetainCallbacks [

	| instrument meter |
	meter := OTNoopMeter instance.
	instrument := meter
		              observableGaugeNamed: 'runtime.memory'
		              callbacks: { [ :observer | observer observe: 42 ] }
		              unit: 'By'
		              description: 'Runtime memory'
		              advice: Dictionary new.
	self assert: instrument class identicalTo: OTNoopObservableGauge.
	self assert: instrument callbacks isEmpty
]

{ #category : 'tests' }
OTMeterProviderTest >> testNoopInstrumentOperationsAreSafeConcurrently [

	| counter errors gauge histogram observableGauge operations outcome results upDownCounter |
	counter := OTCounter noop.
	upDownCounter := OTUpDownCounter noop.
	histogram := OTHistogram noop.
	gauge := OTGauge noop.
	observableGauge := OTObservableGauge noop.
	operations := {
		              (#bind -> [ counter bind: { ('method' -> 'GET') } ]).
		              (#enabled -> [ counter enabled ]).
		              (#add -> [ counter add: 1 ]).
		              (#addAttributes -> [ counter add: 1 attributes: { ('method' -> 'GET') } ]).
		              (#upDown -> [ upDownCounter add: -1 ]).
		              (#recordHistogram -> [ histogram record: 12.5 ]).
		              (#recordGauge -> [ gauge record: 7 ]).
		              (#observe -> [ observableGauge observe: 42 ]).
		              (#observeAttributes -> [ observableGauge observe: 42 attributes: { ('state' -> 'used') } ]).
		              (#callbacks -> [ observableGauge callbacks ]) }.
	outcome := self runConcurrentOperations: operations.
	results := outcome first.
	errors := outcome second.
	self assert: errors isEmpty.
	self assert: ((results select: [ :each | each key = #bind ]) allSatisfy: [ :each | each value == counter ]).
	self assert: ((results select: [ :each | each key = #enabled ]) allSatisfy: [ :each | each value not ]).
	self assert: ((results select: [ :each | each key = #callbacks ]) allSatisfy: [ :each | each value isEmpty ])
]

{ #category : 'tests' }
OTMeterProviderTest >> testNoopMeterDoesNotWarnOnInvalidInstrumentNames [

	self withInstrumentWarningsDo: [ :warnings |
			| counter gauge histogram meter |
			meter := OTNoopMeter instance.
			counter := meter
				           counterNamed: '1 requests'
				           unit: nil
				           description: nil
				           advice: { ('attributes' -> #( 'bad key' )) } asDictionary.
			gauge := meter
				         gaugeNamed: nil
				         unit: nil
				         description: nil
				         advice: nil.
			histogram := meter
				             histogramNamed: ''
				             unit: nil
				             description: nil
				             advice: nil.
			self assert: counter identicalTo: OTNoopCounter instance.
			self assert: gauge identicalTo: OTNoopGauge instance.
			self assert: histogram identicalTo: OTNoopHistogram instance.
			self assert: warnings isEmpty ]
]

{ #category : 'tests' }
OTMeterProviderTest >> testNoopMeterInstrumentCreationIsSafeConcurrently [

	| errors meter operations outcome results |
	meter := OTNoopMeter instance.
	operations := {
		              (#counter -> [
			               meter
				               counterNamed: '1 requests'
				               unit: nil
				               description: nil
				               advice: { ('attributes' -> #( 'bad key' )) } asDictionary ]).
		              (#upDownCounter -> [
			               meter
				               upDownCounterNamed: nil
				               unit: nil
				               description: nil
				               advice: nil ]).
		              (#histogram -> [
			               meter
				               histogramNamed: ''
				               unit: nil
				               description: nil
				               advice: nil ]).
		              (#gauge -> [
			               meter
				               gaugeNamed: nil
				               unit: nil
				               description: nil
				               advice: nil ]).
		              (#observableCounter -> [
			               meter
				               observableCounterNamed: 'runtime.cpu'
				               callbacks: { [ :observer | observer observe: 42 ] }
				               unit: '1'
				               description: 'CPU'
				               advice: Dictionary new ]).
		              (#observableGauge -> [
			               meter
				               observableGaugeNamed: ''
				               callbacks: { [ :observer | observer observe: 7 ] }
				               unit: nil
				               description: nil
				               advice: nil ]).
		              (#observableUpDownCounter -> [
			               meter
				               observableUpDownCounterNamed: nil
				               callbacks: { [ :observer | observer observe: -1 ] }
				               unit: nil
				               description: nil
				               advice: nil ]) }.
	outcome := self runConcurrentOperations: operations.
	results := outcome first.
	errors := outcome second.
	self assert: errors isEmpty.
	self assert: ((results select: [ :each | each key = #counter ]) allSatisfy: [ :each | each value == OTNoopCounter instance ]).
	self assert:
		((results select: [ :each | each key = #upDownCounter ]) allSatisfy: [ :each | each value == OTNoopUpDownCounter instance ]).
	self assert: ((results select: [ :each | each key = #histogram ]) allSatisfy: [ :each | each value == OTNoopHistogram instance ]).
	self assert: ((results select: [ :each | each key = #gauge ]) allSatisfy: [ :each | each value == OTNoopGauge instance ]).
	self assert: ((results select: [ :each | each key = #observableCounter ]) allSatisfy: [ :each |
			 each value == OTNoopObservableCounter instance and: [ each value callbacks isEmpty ] ]).
	self assert: ((results select: [ :each | each key = #observableGauge ]) allSatisfy: [ :each |
			 each value == OTNoopObservableGauge instance and: [ each value callbacks isEmpty ] ]).
	self assert: ((results select: [ :each | each key = #observableUpDownCounter ]) allSatisfy: [ :each |
			 each value == OTNoopObservableUpDownCounter instance and: [ each value callbacks isEmpty ] ])
]

{ #category : 'tests' }
OTMeterProviderTest >> testNoopProviderDoesNotWarnOnInvalidMeterNames [

	self withMeterNameWarningsDo: [ :warnings |
			| firstMeter secondMeter provider |
			provider := OTNoopMeterProvider instance.
			firstMeter := provider
				              meterNamed: nil
				              version: nil
				              schemaUrl: nil
				              attributes: nil.
			secondMeter := provider
				               meterNamed: ''
				               version: nil
				               schemaUrl: nil
				               attributes: { ('scope.answer' -> 42) }.
			self assert: firstMeter identicalTo: OTNoopMeter instance.
			self assert: secondMeter identicalTo: OTNoopMeter instance.
			self assert: warnings isEmpty ]
]

{ #category : 'tests' }
OTMeterProviderTest >> testNoopProviderOperationsAreSafeConcurrently [

	| errors operations outcome provider results |
	provider := OTNoopMeterProvider instance.
	operations := {
		              (#meter -> [
			               provider
				               meterNamed: nil
				               version: nil
				               schemaUrl: nil
				               attributes: nil ]).
		              (#meter -> [
			               provider
				               meterNamed: 'demo.metrics'
				               version: '1.2.3'
				               schemaUrl: 'https://example.com/schema'
				               attributes: self sampleAttributes ]).
		              (#forceFlush -> [ provider forceFlush ]).
		              (#forceFlush -> [ provider forceFlush ]).
		              (#shutdown -> [ provider shutdown ]).
		              (#shutdown -> [ provider shutdown ]) }.
	outcome := self runConcurrentOperations: operations.
	results := outcome first.
	errors := outcome second.
	self assert: errors isEmpty.
	self assert: ((results select: [ :each | each key = #meter ]) allSatisfy: [ :each | each value == OTNoopMeter instance ]).
	self assert: ((results select: [ :each | each key = #forceFlush ]) allSatisfy: [ :each | each value ]).
	self assert: ((results select: [ :each | each key = #shutdown ]) allSatisfy: [ :each | each value ])
]

{ #category : 'tests' }
OTMeterProviderTest >> testNoopProviderReturnsStatelessNoopMeter [

	| meter noopProvider |
	noopProvider := OTNoopMeterProvider instance.
	meter := noopProvider
		         meterNamed: 'demo.metrics'
		         version: '1.2.3'
		         schemaUrl: 'https://example.com/schema'
		         attributes: self sampleAttributes.
	self assert: meter class identicalTo: OTNoopMeter.
	self assert: meter provider isNil.
	self assert: meter instrumentationName equals: ''.
	self assert: meter instrumentationVersion equals: ''.
	self assert: meter schemaUrl equals: ''.
	self assert: meter scopeAttributes isEmpty.
	self assert: meter registeredMetricInstruments isEmpty
]

{ #category : 'tests' }
OTMeterProviderTest >> testNoopTypesDoNotDeclareInstanceState [

	self assert: OTNoopMeterProvider allInstVarNames isEmpty.
	self assert: OTNoopMeter allInstVarNames isEmpty.
	self assert: OTNoopMetricInstrument allInstVarNames isEmpty.
	self assert: OTNoopSynchronousMetricInstrument allInstVarNames isEmpty.
	self assert: OTNoopAsynchronousMetricInstrument allInstVarNames isEmpty.
	self assert: OTNoopCounter allInstVarNames isEmpty.
	self assert: OTNoopUpDownCounter allInstVarNames isEmpty.
	self assert: OTNoopHistogram allInstVarNames isEmpty.
	self assert: OTNoopGauge allInstVarNames isEmpty.
	self assert: OTNoopObservableCounter allInstVarNames isEmpty.
	self assert: OTNoopObservableUpDownCounter allInstVarNames isEmpty.
	self assert: OTNoopObservableGauge allInstVarNames isEmpty
]

{ #category : 'tests' }
OTMeterProviderTest >> testObservableGaugeAggregationUsesCollectionTimeAsPointTimestamp [

	| collectedAt context gauge measurement metric point provider |
	provider := OTMeterProvider new.
	gauge := (provider meterNamed: 'demo.metrics')
		         observableGaugeNamed: 'runtime.memory'
		         callbacks: #(  )
		         unit: 'By'
		         description: 'Runtime memory'
		         advice: Dictionary new.
	measurement := OTMetricMeasurement instrument: gauge value: 42 attributes: { ('state' -> 'used') }.
	measurement timestamp: DateAndTime unixEpoch + (Duration seconds: 5).
	collectedAt := DateAndTime unixEpoch + (Duration seconds: 10).
	context := OTMetricAggregationContext collectedAt: collectedAt startTimestamp: nil temporality: #cumulative.
	metric := gauge metricDataFromMeasurements: { measurement } using: context.
	point := metric points first.
	self assert: point value equals: 42.
	self assert: point startTimestamp equals: measurement timestamp.
	self assert: point timestamp equals: collectedAt
]

{ #category : 'tests' }
OTMeterProviderTest >> testOpenTelemetryMeterNamedDelegatesToCurrentMeterProvider [

	| meter |
	meter := OpenTelemetry
		         meterNamed: 'demo.metrics'
		         version: '1.0.0'
		         schemaUrl: 'https://opentelemetry.io/schemas/1.0.0'
		         attributes: { ('component' -> 'worker') }.
	self assert: meter instrumentationName equals: 'demo.metrics'
]

{ #category : 'tests' }
OTMeterProviderTest >> testOpenTelemetryMeterProviderUsesCurrentGlobalSingleton [

	self assert: OpenTelemetry meterProvider identicalTo: OTMeterProvider current
]

{ #category : 'tests' }
OTMeterProviderTest >> testPeriodicExportingMetricReaderCollectExportsSnapshot [

	| exporter provider reader snapshot |
	exporter := OTInMemoryMetricExporter new.
	provider := OTMeterProvider new.
	reader := OTPeriodicExportingMetricReader exporter: exporter.
	reader exportIntervalMillis: 1000000.
	provider addMetricReader: reader.
	((provider meterNamed: 'demo.metrics') counterNamed: 'requests.total') add: 1 attributes: { ('method' -> 'GET') }.
	snapshot := reader collect.
	self assert: exporter exports size equals: 1.
	self assert: exporter exports first identicalTo: snapshot.
	self assert: snapshot measurements size equals: 1.
	self assert: snapshot resource equals: provider resource
]

{ #category : 'tests' }
OTMeterProviderTest >> testPeriodicExportingMetricReaderCollectHonorsExportTimeoutMillis [

	| durationMillis exporter provider reader snapshot startedAt |
	exporter := OTBlockingMetricExporter new.
	provider := OTMeterProvider new.
	reader := OTPeriodicExportingMetricReader exporter: exporter.
	reader
		exportIntervalMillis: 1000000;
		exportTimeoutMillis: 50.
	provider addMetricReader: reader.
	((provider meterNamed: 'demo.metrics') counterNamed: 'requests.total') add: 1.
	startedAt := Time millisecondClockValue.
	[ snapshot := reader collect ] ensure: [ exporter allowExportToContinue ].
	durationMillis := Time millisecondClockValue - startedAt.
	self assert: (exporter waitForExportEntryWithin: 10).
	self assert: snapshot metrics size equals: 1.
	self assert: durationMillis < 500
]

{ #category : 'tests' }
OTMeterProviderTest >> testPeriodicExportingMetricReaderCollectReturnsEmptySnapshotAfterShutdown [

	| exporter provider reader snapshot |
	exporter := OTInMemoryMetricExporter new.
	provider := OTMeterProvider new.
	reader := OTPeriodicExportingMetricReader exporter: exporter.
	reader exportIntervalMillis: 1000000.
	provider addMetricReader: reader.
	self assert: reader shutdown.
	snapshot := reader collect.
	self assert: snapshot metrics isEmpty.
	self assert: snapshot measurements isEmpty.
	self assert: exporter exports isEmpty
]

{ #category : 'tests' }
OTMeterProviderTest >> testPeriodicExportingMetricReaderCollectSplitsExportBatchesByMetricDataPointCount [

	| exporter metric provider reader snapshot |
	exporter := OTInMemoryMetricExporter new.
	provider := OTMeterProvider new.
	reader := OTPeriodicExportingMetricReader exporter: exporter.
	reader
		exportIntervalMillis: 1000000;
		maxExportBatchSize: 2.
	provider addMetricReader: reader.
	((provider meterNamed: 'demo.metrics') counterNamed: 'requests.total')
		add: 1 attributes: { ('method' -> 'GET') };
		add: 1 attributes: { ('method' -> 'POST') };
		add: 1 attributes: { ('method' -> 'PUT') }.
	snapshot := reader collect.
	metric := snapshot metrics first.
	self assert: metric points size equals: 3.
	self assert: exporter exports size equals: 2.
	self assert: exporter exports first metrics first name equals: 'requests.total'.
	self assert: exporter exports first metrics first points size equals: 2.
	self assert: exporter exports second metrics first points size equals: 1
]

{ #category : 'tests' }
OTMeterProviderTest >> testPeriodicExportingMetricReaderDefaultsAggregationFromExporter [

	| exporter metric provider reader snapshot |
	exporter := OTInMemoryMetricExporter new.
	exporter aggregationSelector: [ :instrument | #sum ].
	provider := OTMeterProvider new.
	reader := OTPeriodicExportingMetricReader exporter: exporter.
	reader exportIntervalMillis: 1000000.
	provider addMetricReader: reader.
	((provider meterNamed: 'demo.metrics') histogramNamed: 'request.duration' unit: 'ms' description: 'Request duration')
		record: 2;
		record: 3.
	snapshot := reader collect.
	metric := snapshot metrics first.
	self assert: metric class identicalTo: OTSumMetricData.
	self assert: metric points first value equals: 5
]

{ #category : 'tests' }
OTMeterProviderTest >> testPeriodicExportingMetricReaderDefaultsTemporalityFromExporter [

	| exporter metric provider reader snapshot |
	exporter := OTInMemoryMetricExporter new.
	exporter temporalitySelector: [ :instrument | #delta ].
	provider := OTMeterProvider new.
	reader := OTPeriodicExportingMetricReader exporter: exporter.
	reader exportIntervalMillis: 1000000.
	provider addMetricReader: reader.
	((provider meterNamed: 'demo.metrics') counterNamed: 'requests.total') add: 1.
	snapshot := reader collect.
	metric := snapshot metrics first.
	self assert: metric temporality equals: #delta
]

{ #category : 'tests' }
OTMeterProviderTest >> testPeriodicExportingMetricReaderForceFlushDelegatesToExporter [

	| exporter provider reader |
	exporter := OTInMemoryMetricExporter new.
	provider := OTMeterProvider new.
	reader := OTPeriodicExportingMetricReader exporter: exporter.
	reader exportIntervalMillis: 1000000.
	provider addMetricReader: reader.
	((provider meterNamed: 'demo.metrics') counterNamed: 'requests.total') add: 1 attributes: { ('method' -> 'GET') }.
	self assert: reader forceFlush.
	self assert: exporter exports size equals: 1.
	self assert: exporter forceFlushCount equals: 1
]

{ #category : 'tests' }
OTMeterProviderTest >> testPeriodicExportingMetricReaderForceFlushHonorsExportTimeoutMillis [

	| exporter provider reader |
	exporter := OTBlockingMetricExporter new.
	provider := OTMeterProvider new.
	reader := OTPeriodicExportingMetricReader exporter: exporter.
	reader
		exportIntervalMillis: 1000000;
		exportTimeoutMillis: 50.
	provider addMetricReader: reader.
	((provider meterNamed: 'demo.metrics') counterNamed: 'requests.total') add: 1.
	[
		self deny: reader forceFlush.
		self assert: exporter forceFlushCount equals: 1 ] ensure: [ exporter allowExportToContinue ]
]

{ #category : 'tests' }
OTMeterProviderTest >> testPeriodicExportingMetricReaderForceFlushSplitsExportBatchesByMetricDataPointCount [

	| exporter provider reader |
	exporter := OTInMemoryMetricExporter new.
	provider := OTMeterProvider new.
	reader := OTPeriodicExportingMetricReader exporter: exporter.
	reader
		exportIntervalMillis: 1000000;
		maxExportBatchSize: 2.
	provider addMetricReader: reader.
	((provider meterNamed: 'demo.metrics') counterNamed: 'requests.total')
		add: 1 attributes: { ('method' -> 'GET') };
		add: 1 attributes: { ('method' -> 'POST') };
		add: 1 attributes: { ('method' -> 'PUT') }.
	self assert: reader forceFlush.
	self assert: exporter exports size equals: 2.
	self assert: exporter exports first metrics first points size equals: 2.
	self assert: exporter exports second metrics first points size equals: 1.
	self assert: exporter forceFlushCount equals: 1
]

{ #category : 'tests' }
OTMeterProviderTest >> testPeriodicExportingMetricReaderOverrideWinsOverExporterAggregation [

	| exporter metric provider reader snapshot |
	exporter := OTInMemoryMetricExporter new.
	exporter aggregationSelector: [ :instrument | #sum ].
	provider := OTMeterProvider new.
	reader := OTPeriodicExportingMetricReader exporter: exporter.
	reader
		exportIntervalMillis: 1000000;
		aggregationSelector: [ :instrument | #default ].
	provider addMetricReader: reader.
	((provider meterNamed: 'demo.metrics') histogramNamed: 'request.duration' unit: 'ms' description: 'Request duration')
		record: 2;
		record: 3.
	snapshot := reader collect.
	metric := snapshot metrics first.
	self assert: metric class identicalTo: OTHistogramMetricData.
	self assert: metric points first count equals: 2.
	self assert: metric points first sum equals: 5
]

{ #category : 'tests' }
OTMeterProviderTest >> testPeriodicExportingMetricReaderOverrideWinsOverExporterTemporality [

	| exporter metric provider reader snapshot |
	exporter := OTInMemoryMetricExporter new.
	exporter temporalitySelector: [ :instrument | #delta ].
	provider := OTMeterProvider new.
	reader := OTPeriodicExportingMetricReader exporter: exporter.
	reader
		exportIntervalMillis: 1000000;
		temporalitySelector: [ :instrument | #cumulative ].
	provider addMetricReader: reader.
	((provider meterNamed: 'demo.metrics') counterNamed: 'requests.total') add: 1.
	snapshot := reader collect.
	metric := snapshot metrics first.
	self assert: metric temporality equals: #cumulative
]

{ #category : 'tests' }
OTMeterProviderTest >> testPeriodicExportingMetricReaderSerializesConcurrentCollectExports [

	| done errors exporter firstSnapshot secondSnapshot provider reader |
	exporter := OTBlockingMetricExporter new.
	provider := OTMeterProvider new.
	reader := OTPeriodicExportingMetricReader exporter: exporter.
	reader exportIntervalMillis: 1000000.
	provider addMetricReader: reader.
	((provider meterNamed: 'demo.metrics') counterNamed: 'requests.total') add: 1.
	done := Semaphore new.
	errors := OrderedCollection new.
	[
		[ firstSnapshot := reader collect ]
			on: Error
			do: [ :anError | errors add: anError ].
		done signal ] forkAt: Processor userBackgroundPriority.
	self assert: (exporter waitForExportEntryWithin: 100).
	[
		[ secondSnapshot := reader collect ]
			on: Error
			do: [ :anError | errors add: anError ].
		done signal ] forkAt: Processor userBackgroundPriority.
	self assert: (exporter waitForExportEntryWithin: 20) not.
	exporter allowExportToContinue.
	self assert: (exporter waitForExportEntryWithin: 100).
	exporter allowExportToContinue.
	self assert: (done waitTimeoutMilliseconds: 1000) not.
	self assert: (done waitTimeoutMilliseconds: 1000) not.
	self assert: errors isEmpty.
	self assert: firstSnapshot metrics size equals: 1.
	self assert: secondSnapshot metrics size equals: 1
]

{ #category : 'tests' }
OTMeterProviderTest >> testPeriodicExportingMetricReaderShutdownShutsDownExporter [

	| exporter provider reader |
	exporter := OTInMemoryMetricExporter new.
	provider := OTMeterProvider new.
	reader := OTPeriodicExportingMetricReader exporter: exporter.
	reader exportIntervalMillis: 1000000.
	provider addMetricReader: reader.
	self assert: reader exportProcess notNil.
	self assert: reader shutdown.
	self assert: exporter isShutdown.
	self assert: reader isShutdown.
	self assert: reader exportProcess isNil
]

{ #category : 'tests' }
OTMeterProviderTest >> testPeriodicExportingMetricReaderUsesConfiguredTemporalityFromConsoleExporter [

	| exporter firstPoint provider reader secondPoint stream |
	exporter := OTConsoleMetricExporter new.
	stream := String new writeStream.
	exporter
		outputStream: stream;
		temporalitySelector: [ :instrument | #delta ].
	provider := OTMeterProvider new.
	reader := OTPeriodicExportingMetricReader exporter: exporter.
	reader exportIntervalMillis: 1000000.
	provider addMetricReader: reader.
	((provider meterNamed: 'demo.metrics') counterNamed: 'requests.total') add: 1.
	firstPoint := reader collect metrics first points first.
	((provider meterNamed: 'demo.metrics') counterNamed: 'requests.total') add: 2.
	secondPoint := reader collect metrics first points first.
	self assert: firstPoint value equals: 1.
	self assert: secondPoint value equals: 2.
	self assert: secondPoint startTimestamp equals: firstPoint timestamp.
	self assert: stream contents isNotEmpty
]

{ #category : 'tests' }
OTMeterProviderTest >> testPeriodicExportingMetricReaderUsesCumulativeTemporalityFromConsoleExporterByDefault [

	| exporter metric provider reader stream |
	exporter := OTConsoleMetricExporter new.
	stream := String new writeStream.
	exporter outputStream: stream.
	provider := OTMeterProvider new.
	reader := OTPeriodicExportingMetricReader exporter: exporter.
	reader exportIntervalMillis: 1000000.
	provider addMetricReader: reader.
	((provider meterNamed: 'demo.metrics') counterNamed: 'requests.total') add: 1.
	metric := reader collect metrics first.
	self assert: metric temporality equals: #cumulative.
	self assert: metric points first value equals: 1.
	self assert: stream contents isNotEmpty
]

{ #category : 'tests' }
OTMeterProviderTest >> testPeriodicExportingMetricReaderUsesCumulativeTemporalityFromInMemoryExporterByDefault [

	| exporter metric provider reader |
	exporter := OTInMemoryMetricExporter new.
	provider := OTMeterProvider new.
	reader := OTPeriodicExportingMetricReader exporter: exporter.
	reader exportIntervalMillis: 1000000.
	provider addMetricReader: reader.
	((provider meterNamed: 'demo.metrics') counterNamed: 'requests.total') add: 1.
	metric := reader collect metrics first.
	self assert: metric temporality equals: #cumulative.
	self assert: metric points first value equals: 1
]

{ #category : 'tests' }
OTMeterProviderTest >> testPeriodicExportingMetricReaderUsesDefaultAggregationFromInMemoryExporterByDefault [

	| exporter metric provider reader |
	exporter := OTInMemoryMetricExporter new.
	provider := OTMeterProvider new.
	reader := OTPeriodicExportingMetricReader exporter: exporter.
	reader exportIntervalMillis: 1000000.
	provider addMetricReader: reader.
	((provider meterNamed: 'demo.metrics') histogramNamed: 'request.duration' unit: 'ms' description: 'Request duration')
		record: 2;
		record: 3.
	metric := reader collect metrics first.
	self assert: metric class identicalTo: OTHistogramMetricData.
	self assert: metric points first count equals: 2.
	self assert: metric points first sum equals: 5
]

{ #category : 'tests' }
OTMeterProviderTest >> testPeriodicExportingMetricReadersSerializeSharedExporterExports [

	| done errors exporter firstReader firstSnapshot provider secondReader secondSnapshot |
	exporter := OTBlockingMetricExporter new.
	provider := OTMeterProvider new.
	firstReader := OTPeriodicExportingMetricReader exporter: exporter.
	secondReader := OTPeriodicExportingMetricReader exporter: exporter.
	firstReader exportIntervalMillis: 1000000.
	secondReader exportIntervalMillis: 1000000.
	provider
		addMetricReader: firstReader;
		addMetricReader: secondReader.
	((provider meterNamed: 'demo.metrics') counterNamed: 'requests.total') add: 1.
	done := Semaphore new.
	errors := OrderedCollection new.
	[
		[ firstSnapshot := firstReader collect ]
			on: Error
			do: [ :anError | errors add: anError ].
		done signal ] forkAt: Processor userBackgroundPriority.
	self assert: (exporter waitForExportEntryWithin: 100).
	[
		[ secondSnapshot := secondReader collect ]
			on: Error
			do: [ :anError | errors add: anError ].
		done signal ] forkAt: Processor userBackgroundPriority.
	self assert: (exporter waitForExportEntryWithin: 20) not.
	exporter allowExportToContinue.
	self assert: (exporter waitForExportEntryWithin: 100).
	exporter allowExportToContinue.
	self assert: (done waitTimeoutMilliseconds: 1000) not.
	self assert: (done waitTimeoutMilliseconds: 1000) not.
	self assert: errors isEmpty.
	self assert: firstSnapshot metrics size equals: 1.
	self assert: secondSnapshot metrics size equals: 1
]

{ #category : 'tests' }
OTMeterProviderTest >> testProviderAddMetricReaderAssignsProvider [

	| provider reader |
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	provider addMetricReader: reader.
	self assert: reader provider identicalTo: provider.
	self assert: provider metricReaders size equals: 1
]

{ #category : 'tests' }
OTMeterProviderTest >> testProviderBackedCounterRecordsMeasurements [

	| counter measurement provider |
	provider := OTMeterProvider new.
	counter := (provider meterNamed: 'demo.metrics')
		           counterNamed: 'requests.total'
		           unit: '1'
		           description: 'Request count'
		           advice: Dictionary new.
	counter add: 1 attributes: { ('method' -> 'GET') }.
	self assert: provider measurements size equals: 1.
	measurement := provider measurements first.
	self assert: measurement instrument name equals: 'requests.total'.
	self assert: measurement value equals: 1.
	self assert: (measurement attributes at: 'method') equals: 'GET'
]

{ #category : 'tests' }
OTMeterProviderTest >> testProviderBackedSynchronousInstrumentBindReturnsBoundWrapper [

	| bound counter meter |
	meter := OTMeterProvider current meterNamed: 'demo.metrics'.
	counter := meter counterNamed: 'requests.total'.
	bound := counter bind: { ('method' -> 'GET') }.
	self assert: bound class identicalTo: OTBoundMetricInstrument.
	self assert: bound instrument identicalTo: counter.
	self assert: (bound attributes at: 'method') equals: 'GET'.
	self assert: bound enabled
]

{ #category : 'tests' }
OTMeterProviderTest >> testProviderBackedSynchronousInstrumentIsEnabled [

	| instrument meter |
	meter := OTMeterProvider current meterNamed: 'demo.metrics'.
	instrument := meter counterNamed: 'requests.total'.
	self assert: instrument enabled
]

{ #category : 'tests' }
OTMeterProviderTest >> testProviderShutdownShutsDownMetricReaders [

	| provider reader |
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	provider addMetricReader: reader.
	self assert: provider shutdown.
	self assert: reader isShutdown.
	self assert: reader collect isEmpty
]

{ #category : 'tests' }
OTMeterProviderTest >> testShutdownMakesFutureMetersNoop [

	| meter provider |
	provider := OTMeterProvider new.
	self assert: provider shutdown.
	meter := provider
		         meterNamed: 'demo.metrics'
		         version: '1.2.3'
		         schemaUrl: 'https://opentelemetry.io/schemas/1.0.0'
		         attributes: self sampleAttributes.
	self assert: meter class identicalTo: OTNoopMeter.
	self assert: meter isNoop.
	self assert: meter instrumentationName equals: ''.
	self assert: meter instrumentationVersion equals: ''
]

{ #category : 'tests' }
OTMeterProviderTest >> testSynchronousInstrumentIsDisabledWhenAllMatchingViewsDrop [

	| instrument provider |
	provider := OTMeterProvider new.
	provider addView: ((OTMetricView named: 'requests.total')
			 aggregation: #drop;
			 yourself).
	instrument := (provider meterNamed: 'demo.metrics') counterNamed: 'requests.total'.
	self deny: instrument enabled.
	instrument add: 1 attributes: { ('method' -> 'GET') }.
	self assert: provider measurements isEmpty
]

{ #category : 'tests' }
OTMeterProviderTest >> testSynchronousInstrumentStaysEnabledWhenAnyMatchingViewExports [

	| instrument provider |
	provider := OTMeterProvider new.
	provider
		addView: ((OTMetricView named: 'requests.total')
				 aggregation: #sum;
				 yourself);
		addView: (OTMetricView all
				 aggregation: #drop;
				 yourself).
	instrument := (provider meterNamed: 'demo.metrics') counterNamed: 'requests.total'.
	self assert: instrument enabled.
	instrument add: 1 attributes: { ('method' -> 'GET') }.
	self assert: provider measurements size equals: 1
]

{ #category : 'tests' }
OTMeterProviderTest >> testSynchronousInstrumentsIgnoreNonFiniteMeasurements [

	| measurements meter provider valuesByName |
	provider := OTMeterProvider new.
	meter := provider meterNamed: 'demo.metrics'.
	(meter counterNamed: 'requests.total')
		add: Float nan;
		add: 3.
	(meter upDownCounterNamed: 'queue.depth')
		add: Float infinity;
		add: -2.
	(meter gaugeNamed: 'temperature')
		record: Float negativeInfinity;
		record: 7.
	(meter histogramNamed: 'latency')
		record: Float nan;
		record: 5.
	measurements := provider measurements.
	self assert: measurements size equals: 4.
	valuesByName := measurements inject: Dictionary new into: [ :dictionary :each |
			                dictionary at: each instrument name put: each value.
			                dictionary ].
	self assert: (valuesByName at: 'requests.total') equals: 3.
	self assert: (valuesByName at: 'queue.depth') equals: -2.
	self assert: (valuesByName at: 'temperature') equals: 7.
	self assert: (valuesByName at: 'latency') equals: 5
]

{ #category : 'tests' }
OTMeterProviderTest >> testSynchronousNoopInstrumentOperationsAreSafe [

	| counter gauge histogram upDownCounter |
	counter := OTCounter noop.
	upDownCounter := OTUpDownCounter noop.
	histogram := OTHistogram noop.
	gauge := OTGauge noop.
	self assert: counter class identicalTo: OTNoopCounter.
	self assert: upDownCounter class identicalTo: OTNoopUpDownCounter.
	self assert: histogram class identicalTo: OTNoopHistogram.
	self assert: gauge class identicalTo: OTNoopGauge.
	self deny: counter enabled.
	self assert: (counter bind: { ('method' -> 'GET') }) identicalTo: counter.
	self shouldnt: [ counter add: 1 ] raise: Error.
	self shouldnt: [ counter add: 1 attributes: { ('method' -> 'GET') } ] raise: Error.
	self shouldnt: [ upDownCounter add: -1 ] raise: Error.
	self shouldnt: [ histogram record: 12.5 ] raise: Error.
	self shouldnt: [ gauge record: 7 ] raise: Error
]

{ #category : 'tests' }
OTMeterProviderTest >> testWhitespaceMeterNameIsPreservedWithoutWarning [

	self withMeterNameWarningsDo: [ :warnings |
			| meter provider |
			provider := OTMeterProvider new.
			meter := provider meterNamed: '   '.
			self assert: meter instrumentationName equals: '   '.
			self assert: warnings isEmpty ]
]

{ #category : 'private' }
OTMeterProviderTest >> withInstrumentWarningsDo: aBlock [

	| warnings |
	warnings := OrderedCollection new.
	OTMeter instrumentWarningSink: [ :message | warnings add: message ].
	[ ^ aBlock value: warnings ] ensure: [ OTMeter instrumentWarningSink: nil ]
]

{ #category : 'private' }
OTMeterProviderTest >> withMeterNameWarningsDo: aBlock [

	| warnings |
	warnings := OrderedCollection new.
	OTMeterProvider meterNameWarningSink: [ :message | warnings add: message ].
	[ ^ aBlock value: warnings ] ensure: [ OTMeterProvider meterNameWarningSink: nil ]
]
