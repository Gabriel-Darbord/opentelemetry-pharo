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
		OTMeter instrumentWarningSink: nil.
		OTMeterProvider meterNameWarningSink: nil.
		OTMeterProvider reset ]
		ensure: [ super tearDown ]
]

{ #category : 'private' }
OTMeterProviderTest >> sampleAttributes [

	^ OrderedDictionary new
		at: 'scope.answer' put: 42;
		yourself
]

{ #category : 'private' }
OTMeterProviderTest >> withMeterNameWarningsDo: aBlock [

	| warnings |
	warnings := OrderedCollection new.
	OTMeterProvider meterNameWarningSink: [ :message | warnings add: message ].
	[
		^ aBlock value: warnings ]
		ensure: [ OTMeterProvider meterNameWarningSink: nil ]
}

{ #category : 'private' }
OTMeterProviderTest >> withInstrumentWarningsDo: aBlock [

	| warnings |
	warnings := OrderedCollection new.
	OTMeter instrumentWarningSink: [ :message | warnings add: message ].
	[
		^ aBlock value: warnings ]
		ensure: [ OTMeter instrumentWarningSink: nil ]
}

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
	self deny: instrument enabled.
	self assert: (instrument bind: { 'key' -> 'value' }) identicalTo: instrument.
	self shouldnt: [ instrument observe: 42 ] raise: Error.
	self shouldnt: [ instrument observe: 42 attributes: { 'key' -> 'value' } ]
		raise: Error
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
		attributes: { 'component' -> 'worker' }.
	self deny: first identicalTo: second
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
OTMeterProviderTest >> testMeterReturnsIdenticalInstrumentForIdenticalRegistration [

	| first second meter |
	meter := OTMeterProvider current meterNamed: 'demo.metrics'.
	first := meter
		counterNamed: 'requests.total'
		unit: '1'
		description: 'Request count'
		advice: { 'attributes' -> #( 'method' ) } asDictionary.
	second := meter
		counterNamed: 'requests.total'
		unit: '1'
		description: 'Request count'
		advice: { 'attributes' -> #( 'method' ) } asDictionary.
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
		advice: { 'attributes' -> #( 'method' ) } asDictionary.
	self assert: instrument meter identicalTo: meter.
	self assert: instrument name equals: 'request.duration'.
	self assert: instrument unit equals: 'ms'.
	self assert: instrument description equals: 'Request duration'.
	self
		assert: (instrument advice at: 'attributes')
		equals: #( 'method' )
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
OTMeterProviderTest >> testMeterWarnsAndReusesFirstSeenAdviceForIdenticalInstrument [

	self withInstrumentWarningsDo: [ :warnings |
		| first second meter |
		meter := OTMeterProvider current meterNamed: 'demo.metrics'.
		first := meter
			counterNamed: 'requests.total'
			unit: '1'
			description: 'Request count'
			advice: { 'attributes' -> #( 'method' ) } asDictionary.
		second := meter
			counterNamed: 'requests.total'
			unit: '1'
			description: 'Request count'
			advice: { 'attributes' -> #( 'status' ) } asDictionary.
		self assert: second identicalTo: first.
		self
			assert: (second advice at: 'attributes')
			equals: #( 'method' ).
		self assert: warnings size equals: 1 ]
}

{ #category : 'tests' }
OTMeterProviderTest >> testMeterProviderAcceptsRichMeterParametersWithoutValidation [

	| meter provider |
	provider := OTMeterProvider new.
	meter := provider
		meterNamed: nil
		version: 42
		schemaUrl: Object new
		attributes: { 'scope.answer' -> 42. #component -> 'worker' }.
	self deny: meter isNoop
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
}

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
		attributes: #().
	self assert: first identicalTo: second.
	self deny: first identicalTo: third
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
}

{ #category : 'tests' }
OTMeterProviderTest >> testOpenTelemetryMeterNamedDelegatesToCurrentMeterProvider [

	| meter |
	meter := OpenTelemetry
		meterNamed: 'demo.metrics'
		version: '1.0.0'
		schemaUrl: 'https://opentelemetry.io/schemas/1.0.0'
		attributes: { 'component' -> 'worker' }.
	self assert: meter instrumentationName equals: 'demo.metrics'
]

{ #category : 'tests' }
OTMeterProviderTest >> testOpenTelemetryMeterProviderUsesCurrentGlobalSingleton [

	self assert: OpenTelemetry meterProvider identicalTo: OTMeterProvider current
]

{ #category : 'tests' }
OTMeterProviderTest >> testShutdownMakesFutureMetersNoopButPreservesScope [

	| meter provider |
	provider := OTMeterProvider new.
	self assert: provider shutdown.
	meter := provider
		meterNamed: 'demo.metrics'
		version: '1.2.3'
		schemaUrl: 'https://opentelemetry.io/schemas/1.0.0'
		attributes: self sampleAttributes.
	self assert: meter isNoop.
	self assert: meter instrumentationName equals: 'demo.metrics'.
	self assert: meter instrumentationVersion equals: '1.2.3'
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
}

{ #category : 'tests' }
OTMeterProviderTest >> testWarnsAndNormalizesInvalidMeterNames [

	self withMeterNameWarningsDo: [ :warnings |
		| meter provider |
		provider := OTMeterProvider new.
		meter := provider meterNamed: '   '.
		self assert: meter instrumentationName equals: ''.
		self
			assert: warnings asArray
			equals: {
				'OpenTelemetry meter name was invalid and has been normalized to an empty string: ''   ''' } ]
}
