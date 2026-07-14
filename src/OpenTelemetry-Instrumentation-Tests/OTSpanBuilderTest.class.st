Class {
	#name : 'OTSpanBuilderTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

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
		OTTracerProvider current: nil.
		OTSpanProcessor current: nil.
		OTSpanExporter current: nil.
		OTSpanBuilder parentContextWarningSink: nil.
		OTSpan reset ]
		ensure: [ super tearDown ]
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
