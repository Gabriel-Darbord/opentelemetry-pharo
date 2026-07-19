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

	| parentSpan provider tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	parentSpan := (OTSpanContext
		               traceId: '00112233445566778899aabbccddeeff'
		               spanId: '1122334455667788'
		               traceFlags: '03'
		               traceState: nil
		               remote: true) asNonRecordingSpan.
	self should: [ (tracer spanBuilderNamed: 'operation') inContext: parentSpan ] raise: Error
]

{ #category : 'tests' }
OTSpanBuilderTest >> testInContextIgnoresInvalidSpanContextAsParentContext [

	| provider spanContext tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	spanContext := OTSpanContext
		               traceId: '00112233445566778899aabbccddeeff'
		               spanId: '1122334455667788'
		               traceFlags: '03'
		               traceState: nil
		               remote: true.
	self should: [ (tracer spanBuilderNamed: 'operation') inContext: spanContext ] raise: Error
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
OTSpanBuilderTest >> testDirectStatusMutatorsAreRejected [

	| provider span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	self should: [ span status: OTSpan error ] raise: Error.
	self should: [ span statusDescription: 'boom' ] raise: Error.
	self assert: span status equals: OTSpan unset.
	self assert: span statusDescription isNil
]

{ #category : 'tests' }
OTSpanBuilderTest >> testDirectTimestampMutatorsAreRejectedAfterStart [

	| originalStartTime provider span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	originalStartTime := span startTime.
	self should: [ span startTime: DateAndTime unixEpoch ] raise: Error.
	self should: [ span endTime: DateAndTime unixEpoch ] raise: Error.
	self assert: span startTime equals: originalStartTime.
	self assert: span endTime isNil
]

{ #category : 'tests' }
OTSpanBuilderTest >> testRecordExceptionDoesNotImplicitlySetErrorStatus [

	| provider span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	[ Error signal: 'boom' ]
		on: Error
		do: [ :error | span recordException: error ].
	self assert: span status equals: OTSpan unset.
	self assert: span statusDescription isNil.
	self assert: span events size equals: 1.
	self assert: span events first name equals: 'exception'.
	self assert: (span events first attributes at: 'exception.message') equals: 'boom'
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
	self deny: firstContext isRemote.
	self assert: firstContext traceId equals: span traceId.
	self assert: firstContext spanId equals: span spanId.
	self assert: firstContext traceFlags equals: span traceFlags.
	self assert: firstContext traceState equals: span traceState.
	span end.
	self assert: span spanContext identicalTo: firstContext
]

{ #category : 'tests' }
OTSpanBuilderTest >> testSpanBuilderStartTimestampControlsRecordedStartTime [

	| provider requestedStartTime span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	requestedStartTime := DateAndTime unixEpoch + (Duration milliSeconds: 123).
	span := ((tracer spanBuilderNamed: 'operation')
		startTimestamp: requestedStartTime;
		startSpan).
	self assert: span startTime equals: requestedStartTime
]

{ #category : 'tests' }
OTSpanBuilderTest >> testUpdateNameChangesRecordingSpanName [

	| provider span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'original') startSpan.
	span updateName: 'renamed'.
	self assert: span name equals: 'renamed'
]

{ #category : 'tests' }
OTSpanBuilderTest >> testUpdateNameDoesNothingAfterEnd [

	| provider span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'original') startSpan.
	span end.
	span updateName: 'renamed'.
	self assert: span name equals: 'original'
]

{ #category : 'tests' }
OTSpanBuilderTest >> testStonRoundTripPreservesErrorStatusDescription [

	| provider roundTripped span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	span setErrorStatusDescription: 'boom'.
	roundTripped := STON fromString: (STON toString: span).
	self assert: roundTripped status equals: OTSpan error.
	self assert: roundTripped statusDescription equals: 'boom'
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
OTSpanBuilderTest >> testSpanBuilderDefersImplicitCurrentContextUntilStart [

	| builder currentContext parentSpan provider span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	builder := tracer spanBuilderNamed: 'operation'.
	parentSpan := (OTSpanContext
		traceId: '00112233445566778899aabbccddeeff'
		spanId: '1122334455667788'
		traceFlags: '03'
		traceState: nil
		remote: false) asNonRecordingSpan.
	currentContext := OTContext new withSpan: parentSpan.
	OpenTelemetry
		useContext: currentContext
		during: [ span := builder startSpan ].
	self assert: span parent identicalTo: parentSpan.
	self assert: span traceId equals: parentSpan traceId
]

{ #category : 'tests' }
OTSpanBuilderTest >> testSpanBuilderUsesImplicitCurrentContextByDefault [

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
		during: [ span := (tracer spanBuilderNamed: 'operation') startSpan ].
	self assert: span parent identicalTo: parentSpan.
	self assert: span traceId equals: parentSpan traceId
]

{ #category : 'tests' }
OTSpanBuilderTest >> testSpanClassNewIsRejected [

	self should: [ OTSpan new ] raise: Error
]

{ #category : 'tests' }
OTSpanBuilderTest >> testSpanClassRootInIsRejected [

	self should: [ OTSpan rootIn: OTContext new ] raise: Error
]

{ #category : 'tests' }
OTSpanBuilderTest >> testSpanClassUnderIsRejected [

	| parentSpan |
	parentSpan := (OTSpanContext
		               traceId: '00112233445566778899aabbccddeeff'
		               spanId: '1122334455667788'
		               traceFlags: '01'
		               traceState: nil
		               remote: false) asNonRecordingSpan.
	self should: [ OTSpan under: parentSpan ] raise: Error
]

{ #category : 'tests' }
OTSpanBuilderTest >> testStartedSpanExposesRemoteParentSpanContext [

	| parentContext provider span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	parentContext := OTSpanContext
		traceId: '00112233445566778899aabbccddeeff'
		spanId: '1122334455667788'
		traceFlags: '03'
		traceState: 'upstream=value'
		remote: true.
	span := ((tracer spanBuilderNamed: 'operation')
		inContext: (OTContext new withSpan: parentContext asNonRecordingSpan);
		startSpan).
	self assert: span parentSpanContext equals: parentContext.
	self assert: span parentSpanContext isRemote
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
