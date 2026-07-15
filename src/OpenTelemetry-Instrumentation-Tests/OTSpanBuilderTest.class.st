Class {
	#name : 'OTSpanBuilderTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'private' }
OTSpanBuilderTest >> sampledParentSpan [

	^ (OTSpanContext
		traceId: '00112233445566778899aabbccddeeff'
		spanId: '1122334455667788'
		traceFlags: '03'
		traceState: 'rojo=1'
		remote: false) asNonRecordingSpan
]

{ #category : 'running' }
OTSpanBuilderTest >> setUp [

	super setUp.
	OTTracerProvider current: nil.
	OTSpanProcessor current: nil.
	OTSpanExporter current: nil.
	OTSpanBuilder parentContextWarningSink: nil.
	OTSpan reset
]

{ #category : 'running' }
OTSpanBuilderTest >> tearDown [

	[
		OpenTelemetry resetCurrentContext.
		OTTracerProvider current: nil.
		OTSpanProcessor current: nil.
		OTSpanExporter current: nil.
		OTSpanBuilder parentContextWarningSink: nil.
		OTSpan reset ]
		ensure: [ super tearDown ]
]

{ #category : 'tests' }
OTSpanBuilderTest >> testAsRootIgnoresImplicitCurrentSpan [

	| currentContext parentSpan provider rootSpan tracer |
	provider := OTTracerProvider new.
	provider
		spanProcessor: OTSimpleSpanProcessor new;
		sampler: (OTParentBasedSampler default
			rootSampler: OTAlwaysOffSampler new;
			yourself).
	tracer := provider tracerNamed: 'demo.scope'.
	parentSpan := self sampledParentSpan.
	currentContext := OTContext new withSpan: parentSpan.
	OpenTelemetry
		useContext: currentContext
		during: [
			rootSpan := ((tracer spanBuilderNamed: 'root')
				inCurrentContext;
				asRoot;
				startSpan) ].
	self assert: rootSpan class identicalTo: OTNonRecordingSpan.
	self assert: rootSpan spanContext isValid.
	self assert: rootSpan parent isNil.
	self deny: rootSpan traceId equals: parentSpan traceId
]

{ #category : 'tests' }
OTSpanBuilderTest >> testEndedSpanCanStillBeUsedAsParentThroughContext [

	| childSpan parentSpan provider tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	parentSpan := (tracer spanBuilderNamed: 'parent') startSpan.
	parentSpan end.
	childSpan := ((tracer spanBuilderNamed: 'child')
		inContext: (parentSpan inContext: OTContext new);
		startSpan).
	self assert: childSpan parent identicalTo: parentSpan.
	self assert: childSpan traceId equals: parentSpan traceId
]

{ #category : 'tests' }
OTSpanBuilderTest >> testInContextIgnoresInvalidSpanAsParentContext [

	self
		withParentContextWarningsDo: [ :warnings |
			| parentSpan provider span tracer |
			provider := OTTracerProvider new.
			provider spanProcessor: OTSimpleSpanProcessor new.
			tracer := provider tracerNamed: 'demo.scope'.
			parentSpan := (OTSpanContext
				traceId: '00112233445566778899aabbccddeeff'
				spanId: '1122334455667788'
				traceFlags: '03'
				traceState: nil
				remote: true) asNonRecordingSpan.
			span := ((tracer spanBuilderNamed: 'operation')
				inContext: parentSpan;
				startSpan).
			self assert: span parent isNil.
			self assert: warnings size equals: 1.
			self assert: warnings first equals:
				'OpenTelemetry span builder ignored an invalid parent context and used a root context instead: '
					, parentSpan printString ]
]

{ #category : 'tests' }
OTSpanBuilderTest >> testInContextIgnoresInvalidSpanContextAsParentContext [

	self
		withParentContextWarningsDo: [ :warnings |
			| provider span spanContext tracer |
			provider := OTTracerProvider new.
			provider spanProcessor: OTSimpleSpanProcessor new.
			tracer := provider tracerNamed: 'demo.scope'.
			spanContext := OTSpanContext
				traceId: '00112233445566778899aabbccddeeff'
				spanId: '1122334455667788'
				traceFlags: '03'
				traceState: nil
				remote: true.
			span := ((tracer spanBuilderNamed: 'operation')
				inContext: spanContext;
				startSpan).
			self assert: span parent isNil.
			self assert: warnings size equals: 1.
			self assert: warnings first equals:
				'OpenTelemetry span builder ignored an invalid parent context and used a root context instead: '
					, spanContext printString ]
]

{ #category : 'tests' }
OTSpanBuilderTest >> testInContextNilUsesEmptyContextWithoutWarning [

	self
		withParentContextWarningsDo: [ :warnings |
			| provider span tracer |
			provider := OTTracerProvider new.
			provider spanProcessor: OTSimpleSpanProcessor new.
			tracer := provider tracerNamed: 'demo.scope'.
			span := ((tracer spanBuilderNamed: 'operation')
				inContext: nil;
				startSpan).
			self assert: span parent isNil.
			self assert: warnings isEmpty ]
]

{ #category : 'tests' }
OTSpanBuilderTest >> testInCurrentContextUsesImplicitCurrentSpanAsParent [

	| currentContext parentSpan provider span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	parentSpan := (OTSpanContext
		traceId: '00112233445566778899aabbccddeeff'
		spanId: '1122334455667788'
		traceFlags: '03'
		traceState: nil
		remote: false) asNonRecordingSpan.
	currentContext := OTContext new withSpan: parentSpan.
	OpenTelemetry
		useContext: currentContext
		during: [
			span := ((tracer spanBuilderNamed: 'operation')
				inCurrentContext;
				startSpan) ].
	self assert: span parent identicalTo: parentSpan.
	self assert: span traceId equals: parentSpan traceId
]

{ #category : 'tests' }
OTSpanBuilderTest >> testNoParentIgnoresParentContextForSamplingAndTraceIdentity [

	| baggage context parentSpan provider rootSpan tracedChild tracer |
	provider := OTTracerProvider new.
	provider
		spanProcessor: OTSimpleSpanProcessor new;
		sampler: (OTParentBasedSampler default
			rootSampler: OTAlwaysOffSampler new;
			yourself).
	tracer := provider tracerNamed: 'demo.scope'.
	parentSpan := self sampledParentSpan.
	baggage := OTBaggage empty withEntryNamed: 'tenant.id' value: 'acme'.
	context := (OTContext new withSpan: parentSpan) withBaggage: baggage.
	tracedChild := ((tracer spanBuilderNamed: 'child')
		inContext: context;
		startSpan).
	rootSpan := ((tracer spanBuilderNamed: 'root')
		inContext: context;
		noParent;
		startSpan).
	self assert: tracedChild isRecording.
	self assert: tracedChild traceId equals: parentSpan traceId.
	self assert: rootSpan class identicalTo: OTNonRecordingSpan.
	self assert: rootSpan spanContext isValid.
	self assert: rootSpan parent isNil.
	self deny: rootSpan traceId equals: parentSpan traceId.
	self assert: rootSpan context baggage equals: baggage
]

{ #category : 'tests' }
OTSpanBuilderTest >> testRecordingSpanCanAddLinkFromAnotherSpan [

	| linkedSpan provider span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	linkedSpan := (tracer spanBuilderNamed: 'linked') startSpan.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	span addLinkSpan: linkedSpan attributes: (OrderedDictionary new
		at: 'link.kind' put: 'follows_from';
		yourself).
	self assert: span links size equals: 1.
	self assert: span links first spanContext equals: linkedSpan spanContext.
	self assert: (span links first attributes at: 'link.kind') equals: 'follows_from'
]

{ #category : 'tests' }
OTSpanBuilderTest >> testRecordingSpanReturnsStableSpanContextAcrossLifecycle [

	| firstContext provider secondContext span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	firstContext := span spanContext.
	secondContext := span spanContext.
	self assert: secondContext identicalTo: firstContext.
	span end.
	self assert: span spanContext identicalTo: firstContext
]

{ #category : 'tests' }
OTSpanBuilderTest >> testSpanBuilderCanAddLinkFromAnotherSpan [

	| linkedSpan provider span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	linkedSpan := (tracer spanBuilderNamed: 'linked') startSpan.
	span := ((tracer spanBuilderNamed: 'operation')
		addLinkSpan: linkedSpan attributes: (OrderedDictionary new
			at: 'link.kind' put: 'caused_by';
			yourself);
		startSpan).
	self assert: span links size equals: 1.
	self assert: span links first spanContext equals: linkedSpan spanContext.
	self assert: (span links first attributes at: 'link.kind') equals: 'caused_by'
]

{ #category : 'tests' }
OTSpanBuilderTest >> testTracerStartSpanNamedUsesImplicitCurrentContext [

	| currentContext parentSpan provider span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	parentSpan := (OTSpanContext
		traceId: '00112233445566778899aabbccddeeff'
		spanId: '1122334455667788'
		traceFlags: '03'
		traceState: nil
		remote: false) asNonRecordingSpan.
	currentContext := OTContext new withSpan: parentSpan.
	OpenTelemetry
		useContext: currentContext
		during: [ span := tracer startSpanNamed: 'operation' ].
	self assert: span parent identicalTo: parentSpan.
	self assert: span traceId equals: parentSpan traceId
]

{ #category : 'private' }
OTSpanBuilderTest >> withParentContextWarningsDo: aBlock [

	| warnings |
	warnings := OrderedCollection new.
	OTSpanBuilder parentContextWarningSink: [ :message | warnings add: message ].
	[
		^ aBlock value: warnings ]
		ensure: [ OTSpanBuilder parentContextWarningSink: nil ]
]
