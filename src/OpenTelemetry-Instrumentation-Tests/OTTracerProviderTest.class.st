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
		OTSpanProcessor current: nil.
		OTSpanExporter current: nil.
		OTSpan reset ]
		ensure: [ super tearDown ]
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
