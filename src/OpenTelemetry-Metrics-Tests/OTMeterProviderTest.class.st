Class {
	#name : 'OTMeterProviderTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Metrics-Tests',
	#package : 'OpenTelemetry-Metrics-Tests'
}

{ #category : 'running' }
OTMeterProviderTest >> tearDown [

	[
		OpenTelemetry meterProvider: nil.
		OTMeterProvider reset ]
		ensure: [ super tearDown ]
]

{ #category : 'tests' }
OTMeterProviderTest >> testAsynchronousInstrumentCreationAcceptsCallbacksWithoutInvokingThem [

	| callbackCount instrument meter |
	callbackCount := 0.
	meter := OTMeterProvider current meterNamed: 'demo.metrics'.
	instrument := meter
		observableCounterNamed: 'runtime.cpu'
		callbacks: {
			[ callbackCount := callbackCount + 1 ] }
		unit: '1'
		description: 'CPU'
		advice: { 'attributes' -> #( 'state' ) } asDictionary.
	self assert: instrument class identicalTo: OTObservableCounter.
	self assert: callbackCount equals: 0
]

{ #category : 'tests' }
OTMeterProviderTest >> testAsynchronousNoopInstrumentOperationsAreSafe [

	| instrument |
	instrument := OTObservableGauge noop.
	self deny: instrument enabled.
	self assert: (instrument bind: { 'key' -> 'value' }) identicalTo: instrument.
	self shouldnt: [ instrument observe: 42 ] raise: Error.
	self shouldnt: [ instrument observe: 42 attributes: { 'key' -> 'value' } ]
		raise: Error
]

{ #category : 'tests' }
OTMeterProviderTest >> testExplicitMeterProviderCanBeInstalledGlobally [

	| provider |
	provider := OTMeterProvider new.
	OpenTelemetry meterProvider: provider.
	self assert: OpenTelemetry meterProvider identicalTo: provider
]

{ #category : 'tests' }
OTMeterProviderTest >> testMeterCreationReturnsNoopInstruments [

	| meter |
	meter := OTMeterProvider current meterNamed: 'demo.metrics'.
	self assert: (meter counterNamed: 'requests') class identicalTo: OTCounter.
	self
		assert: (meter upDownCounterNamed: 'queue.depth') class
		identicalTo: OTUpDownCounter.
	self
		assert: (meter histogramNamed: 'request.duration') class
		identicalTo: OTHistogram.
	self assert: (meter gaugeNamed: 'cache.size') class identicalTo: OTGauge.
	self
		assert: (meter observableGaugeNamed: 'runtime.memory') class
		identicalTo: OTObservableGauge.
	self
		assert: (meter observableUpDownCounterNamed: 'workers') class
		identicalTo: OTObservableUpDownCounter
]

{ #category : 'tests' }
OTMeterProviderTest >> testMeterProviderAcceptsRichMeterParametersWithoutValidation [

	| meter provider |
	provider := OTMeterProvider new.
	meter := provider
		meterNamed: nil
		version: 42
		schemaUrl: Object new
		attributes: { 1 -> 2. #x -> nil }.
	self assert: meter identicalTo: OTMeter noop
]

{ #category : 'tests' }
OTMeterProviderTest >> testMeterProviderMayReturnSameMeterForDistinctRequests [

	| first second provider |
	provider := OTMeterProvider new.
	first := provider meterNamed: 'first'.
	second := provider
		meterNamed: 'second'
		version: '1.2.3'
		schemaUrl: 'https://opentelemetry.io/schemas/1.0.0'
		attributes: { 'component' -> 'worker' }.
	self assert: first identicalTo: second
]

{ #category : 'tests' }
OTMeterProviderTest >> testOpenTelemetryMeterNamedDelegatesToCurrentMeterProvider [

	| meter |
	meter := OpenTelemetry
		meterNamed: 'demo.metrics'
		version: '1.0.0'
		schemaUrl: 'https://opentelemetry.io/schemas/1.0.0'
		attributes: { 'component' -> 'worker' }.
	self assert: meter identicalTo: OTMeter noop
]

{ #category : 'tests' }
OTMeterProviderTest >> testOpenTelemetryMeterProviderUsesCurrentGlobalSingleton [

	self assert: OpenTelemetry meterProvider identicalTo: OTMeterProvider current
]

{ #category : 'tests' }
OTMeterProviderTest >> testSynchronousNoopInstrumentOperationsAreSafe [

	| counter gauge histogram upDownCounter |
	counter := OTCounter noop.
	upDownCounter := OTUpDownCounter noop.
	histogram := OTHistogram noop.
	gauge := OTGauge noop.
	self deny: counter enabled.
	self assert: (counter bind: { 'method' -> 'GET' }) identicalTo: counter.
	self shouldnt: [ counter add: 1 ] raise: Error.
	self shouldnt: [ counter add: 1 attributes: { 'method' -> 'GET' } ]
		raise: Error.
	self shouldnt: [ upDownCounter add: -1 ] raise: Error.
	self shouldnt: [ histogram record: 12.5 ] raise: Error.
	self shouldnt: [ gauge record: 7 ] raise: Error
]
