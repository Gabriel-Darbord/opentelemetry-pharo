Class {
	#name : 'OTTracerProviderTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'private' }
OTTracerProviderTest >> sampleAttributes [

	^ OrderedDictionary new
		at: 'scope.answer' put: 42;
		yourself
]

{ #category : 'running' }
OTTracerProviderTest >> setUp [

	super setUp.
	OTTracerProvider current: nil.
	OTSpanProcessor current: nil.
	OTSpanExporter current: nil.
	OTSpan reset
]

{ #category : 'running' }
OTTracerProviderTest >> tearDown [

	[
		OTTracerProvider current: nil.
		OTTracerProvider tracerNameWarningSink: nil.
		OTSpanProcessor current: nil.
		OTSpanExporter current: nil.
		OTSpan reset ]
		ensure: [ super tearDown ]
]

{ #category : 'private' }
OTTracerProviderTest >> withTracerNameWarningsDo: aBlock [

	| warnings |
	warnings := OrderedCollection new.
	OTTracerProvider tracerNameWarningSink: [ :message | warnings add: message ].
	[
		^ aBlock value: warnings ]
		ensure: [ OTTracerProvider tracerNameWarningSink: nil ]
]

{ #category : 'tests' }
OTTracerProviderTest >> testRecordingSpanInheritsProviderResourceAndScope [

	| provider tracer span resource |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	resource := OTResource attributes: (OrderedDictionary new
		at: 'service.name' put: 'spec-service';
		yourself).
	provider resource: resource.
	tracer := provider
		tracerNamed: 'demo.scope'
		version: '1.2.3'
		schemaUrl: 'https://opentelemetry.io/schemas/1.0.0'
		attributes: self sampleAttributes.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	self assert: span resource equals: resource.
	self assert: span instrumentationScope name equals: 'demo.scope'.
	self assert: span instrumentationScope version equals: '1.2.3'.
	self assert: span instrumentationScope schemaUrl equals: 'https://opentelemetry.io/schemas/1.0.0'.
	self assert: (span instrumentationScope attributeAt: 'scope.answer') equals: 42
]

{ #category : 'tests' }
OTTracerProviderTest >> testTracerNamedEmptyStringReturnsWorkingTracerWithEmptyNameAndWarning [

	self
		withTracerNameWarningsDo: [ :warnings |
			| provider tracer |
			provider := OTTracerProvider new.
			provider spanProcessor: OTSimpleSpanProcessor new.
			tracer := provider tracerNamed: ''.
			self assert: tracer instrumentationName equals: ''.
			self assert: warnings size equals: 1.
			self assert: warnings first equals:
				'OpenTelemetry tracer name was invalid and has been normalized to an empty string: ''''' ]
]

{ #category : 'tests' }
OTTracerProviderTest >> testTracerNamedNilReturnsWorkingTracerWithEmptyNameAndWarning [

	self
		withTracerNameWarningsDo: [ :warnings |
			| provider tracer |
			provider := OTTracerProvider new.
			provider spanProcessor: OTSimpleSpanProcessor new.
			tracer := provider tracerNamed: nil.
			self assert: tracer instrumentationName equals: ''.
			self assert: warnings size equals: 1.
			self assert: warnings first equals:
				'OpenTelemetry tracer name was invalid and has been normalized to an empty string: nil' ]
]

{ #category : 'tests' }
OTTracerProviderTest >> testTracerNamedWhitespaceOnlyStringNormalizesToEmptyName [

	self
		withTracerNameWarningsDo: [ :warnings |
			| provider tracer |
			provider := OTTracerProvider new.
			provider spanProcessor: OTSimpleSpanProcessor new.
			tracer := provider tracerNamed: '   '.
			self assert: tracer instrumentationName equals: ''.
			self assert: warnings size equals: 1 ]
]

{ #category : 'tests' }
OTTracerProviderTest >> testRecordingSpanSamplerCanExplicitlyClearParentTraceState [

	| parentContext provider sampler span |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	sampler := OTSamplingResultSampler result: (OTSamplingResult
		decision: #recordAndSample
		attributes: #()
		traceState: OTTraceState empty).
	provider sampler: sampler.
	parentContext := OTContext new
		withSpan: ((OTSpanContext
			traceId: '00112233445566778899aabbccddeeff'
			spanId: '1122334455667788'
			traceFlags: '03'
			traceState: 'vendor=value'
			remote: true) asNonRecordingSpan).
	span := (((provider tracerNamed: 'demo.scope') spanBuilderNamed: 'child')
		inContext: parentContext;
		startSpan).
	self assert: span spanContext traceState class identicalTo: OTTraceState.
	self assert: span spanContext traceState isEmpty
]

{ #category : 'tests' }
OTTracerProviderTest >> testRootSpanMarksGeneratedTraceIdsAsRandom [

	| provider tracer span |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	self assert: span spanContext traceFlags equals: '03'.
	self assert: span spanContext isRandom
]

{ #category : 'tests' }
OTTracerProviderTest >> testShutdownMakesReturnedTracerBehaveAsNoop [

	| provider span |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	self assert: provider shutdown.
	span := (provider tracerNamed: 'demo.scope')
		startSpanNamed: 'operation'
		in: OTContext new.
	self assert: span class identicalTo: OTNonRecordingSpan.
	self deny: span spanContext isValid
]

{ #category : 'tests' }
OTTracerProviderTest >> testNonRecordingSpanSamplerCanExplicitlyClearParentTraceState [

	| parentContext provider sampler span |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	sampler := OTSamplingResultSampler result: (OTSamplingResult
		decision: #drop
		attributes: #()
		traceState: OTTraceState empty).
	provider sampler: sampler.
	parentContext := OTContext new
		withSpan: ((OTSpanContext
			traceId: '00112233445566778899aabbccddeeff'
			spanId: '1122334455667788'
			traceFlags: '03'
			traceState: 'vendor=value'
			remote: true) asNonRecordingSpan).
	span := (((provider tracerNamed: 'demo.scope') spanBuilderNamed: 'child')
		inContext: parentContext;
		startSpan).
	self assert: span class identicalTo: OTNonRecordingSpan.
	self assert: span spanContext traceState class identicalTo: OTTraceState.
	self assert: span spanContext traceState isEmpty
]

{ #category : 'tests' }
OTTracerProviderTest >> testUnsampledChildSpanPreservesParentRandomFlag [

	| provider tracer parentContext span |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	parentContext := OTContext new
		withSpan: ((OTSpanContext
			traceId: '00112233445566778899aabbccddeeff'
			spanId: '1122334455667788'
			traceFlags: '02'
			traceState: nil
			remote: true) asNonRecordingSpan).
	span := ((tracer spanBuilderNamed: 'child')
		inContext: parentContext;
		startSpan).
	self assert: span class identicalTo: OTNonRecordingSpan.
	self assert: span spanContext traceFlags equals: '02'.
	self assert: span spanContext isRandom
]

{ #category : 'tests' }
OTTracerProviderTest >> testTracerCachesByFullInstrumentationScope [

	| provider first second third |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	first := provider
		tracerNamed: 'demo.scope'
		version: '1.2.3'
		schemaUrl: 'https://opentelemetry.io/schemas/1.0.0'
		attributes: self sampleAttributes.
	second := provider
		tracerNamed: 'demo.scope'
		version: '1.2.3'
		schemaUrl: 'https://opentelemetry.io/schemas/1.0.0'
		attributes: self sampleAttributes.
	third := provider
		tracerNamed: 'demo.scope'
		version: '2.0.0'
		schemaUrl: 'https://opentelemetry.io/schemas/1.0.0'
		attributes: self sampleAttributes.
	self assert: first identicalTo: second.
	self deny: first identicalTo: third
]

{ #category : 'tests' }
OTTracerProviderTest >> testTracerWithoutProcessorsReturnsNonRecordingSpan [

	| provider span |
	provider := OTTracerProvider new.
	span := (provider tracerNamed: 'demo.scope')
		startSpanNamed: 'operation'
		in: OTContext new.
	self assert: span class identicalTo: OTNonRecordingSpan.
	self deny: span spanContext isValid
]
