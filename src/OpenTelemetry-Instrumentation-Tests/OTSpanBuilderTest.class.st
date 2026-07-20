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
	OpenTelemetry useContext: currentContext during: [
			rootSpan := (tracer spanBuilderNamed: 'root')
				            inCurrentContext;
				            asRoot;
				            startSpan ].
	self assert: rootSpan class identicalTo: OTNonRecordingSpan.
	self assert: rootSpan spanContext isValid.
	self assert: rootSpan parent isNil.
	self deny: rootSpan spanContext traceId equals: parentSpan spanContext traceId
]

{ #category : 'tests' }
OTSpanBuilderTest >> testAttributesGetterAnswersEmptyCollectionWhenUnset [

	| exportRecord provider span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	exportRecord := span asExportRecord.
	self deny: (exportRecord includesKey: #attributes)
]

{ #category : 'tests' }
OTSpanBuilderTest >> testEndedSpanCanStillBeUsedAsParentThroughContext [

	| childSpan parentSpan provider tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	parentSpan := (tracer spanBuilderNamed: 'parent') startSpan.
	parentSpan end.
	childSpan := (tracer spanBuilderNamed: 'child')
		             inContext: (OTContext new withSpan: parentSpan);
		             startSpan.
	self assert: childSpan parent identicalTo: parentSpan.
	self assert: childSpan spanContext traceId equals: parentSpan spanContext traceId
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
	OpenTelemetry useContext: currentContext during: [
			span := (tracer spanBuilderNamed: 'operation')
				        inCurrentContext;
				        startSpan ].
	self assert: span parent identicalTo: parentSpan.
	self assert: span spanContext traceId equals: parentSpan spanContext traceId
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
	tracedChild := (tracer spanBuilderNamed: 'child')
		               inContext: context;
		               startSpan.
	rootSpan := (tracer spanBuilderNamed: 'root')
		            inContext: context;
		            noParent;
		            startSpan.
	self assert: tracedChild isRecording.
	self assert: tracedChild spanContext traceId equals: parentSpan spanContext traceId.
	self assert: rootSpan class identicalTo: OTNonRecordingSpan.
	self assert: rootSpan spanContext isValid.
	self assert: rootSpan parent isNil.
	self deny: rootSpan spanContext traceId equals: parentSpan spanContext traceId.
	self assert: rootSpan context baggage equals: baggage
]

{ #category : 'tests' }
OTSpanBuilderTest >> testRecordExceptionDoesNotImplicitlySetErrorStatus [

	| eventsToExport exportRecord provider span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	[ Error signal: 'boom' ]
		on: Error
		do: [ :error | span recordException: error ].
	exportRecord := span asExportRecord.
	eventsToExport := exportRecord at: #events.
	self assert: (exportRecord at: #status) equals: OTSpan unset.
	self deny: (exportRecord includesKey: #statusDescription).
	self assert: eventsToExport size equals: 1.
	self assert: eventsToExport first name equals: 'exception'.
	self assert: (eventsToExport first attributes at: 'exception.message') equals: 'boom'
]

{ #category : 'tests' }
OTSpanBuilderTest >> testRecordingSpanCanAddLinkFromAnotherSpan [

	| exportRecord linkedSpan linksToExport provider span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	linkedSpan := (tracer spanBuilderNamed: 'linked') startSpan.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	span addLink: (OTSpanLink span: linkedSpan attributes: (OrderedDictionary new
				  at: 'link.kind' put: 'follows_from';
				  yourself)).
	exportRecord := span asExportRecord.
	linksToExport := exportRecord at: #links.
	self assert: linksToExport size equals: 1.
	self assert: linksToExport first spanContext equals: linkedSpan spanContext.
	self assert: (linksToExport first attributes at: 'link.kind') equals: 'follows_from'
]

{ #category : 'tests' }
OTSpanBuilderTest >> testRecordingSpanDoesNotExposeBulkMutationSetters [

	| link provider span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	link := OTSpanLink
		        spanContext: (OTSpanContext
				         traceId: '00112233445566778899aabbccddeeff'
				         spanId: '1122334455667788'
				         traceFlags: '01'
				         traceState: nil
				         remote: true)
		        attributes: #(  ).
	self
		should: [
				span perform: #attributes: with: (OrderedDictionary new
						 at: 'answer' put: 42;
						 yourself) ]
		raise: MessageNotUnderstood.
	self
		should: [ span perform: #events: with: { (OTSpanEvent named: 'event' attributes: #(  ) timestamp: DateAndTime unixEpoch) } ]
		raise: MessageNotUnderstood.
	self should: [ span perform: #links: with: { link } ] raise: MessageNotUnderstood
]

{ #category : 'tests' }
OTSpanBuilderTest >> testRecordingSpanDoesNotExposeLinkConvenienceSetters [

	| provider span tracer upstreamContext |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	upstreamContext := OTSpanContext
		                   traceId: '00112233445566778899aabbccddeeff'
		                   spanId: '1122334455667788'
		                   traceFlags: '01'
		                   traceState: nil
		                   remote: true.
	self should: [ span perform: #addLinkSpan: with: upstreamContext asNonRecordingSpan ] raise: MessageNotUnderstood.
	self
		should: [
				span perform: #addLinkSpan:attributes: with: upstreamContext asNonRecordingSpan with: (OrderedDictionary new
						 at: 'kind' put: 'caused_by';
						 yourself) ]
		raise: MessageNotUnderstood.
	self should: [ span perform: #addLinkSpanContext: with: upstreamContext ] raise: MessageNotUnderstood.
	self
		should: [
				span perform: #addLinkSpanContext:attributes: with: upstreamContext with: (OrderedDictionary new
						 at: 'kind' put: 'follows_from';
						 yourself) ]
		raise: MessageNotUnderstood
]

{ #category : 'tests' }
OTSpanBuilderTest >> testRecordingSpanDoesNotExposeStatusConvenienceSetters [

	| provider span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	self should: [ span perform: #setOkStatus ] raise: MessageNotUnderstood.
	self should: [ span perform: #setErrorStatus ] raise: MessageNotUnderstood.
	self should: [ span perform: #setErrorStatusDescription: with: 'boom' ] raise: MessageNotUnderstood
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
	self assert: firstContext traceId equals: span spanContext traceId.
	self assert: firstContext spanId equals: span spanContext spanId.
	self assert: firstContext traceFlags equals: span spanContext traceFlags.
	self assert: firstContext traceState equals: span spanContext traceState.
	span end.
	self assert: span spanContext identicalTo: firstContext
]

{ #category : 'tests' }
OTSpanBuilderTest >> testSpanBuilderCanAddLinkFromAnotherSpan [

	| exportRecord linkedSpan linksToExport provider span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	linkedSpan := (tracer spanBuilderNamed: 'linked') startSpan.
	span := (tracer spanBuilderNamed: 'operation')
		        addLinkSpan: linkedSpan attributes: (OrderedDictionary new
				         at: 'link.kind' put: 'caused_by';
				         yourself);
		        startSpan.
	exportRecord := span asExportRecord.
	linksToExport := exportRecord at: #links.
	self assert: linksToExport size equals: 1.
	self assert: linksToExport first spanContext equals: linkedSpan spanContext.
	self assert: (linksToExport first attributes at: 'link.kind') equals: 'caused_by'
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
	OpenTelemetry useContext: currentContext during: [ span := builder startSpan ].
	self assert: span parent identicalTo: parentSpan.
	self assert: span spanContext traceId equals: parentSpan spanContext traceId
]

{ #category : 'tests' }
OTSpanBuilderTest >> testSpanBuilderStartTimestampControlsRecordedStartTime [

	| provider requestedStartTime span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	requestedStartTime := DateAndTime unixEpoch + (Duration milliSeconds: 123).
	span := (tracer spanBuilderNamed: 'operation')
		        startTimestamp: requestedStartTime;
		        startSpan.
	self assert: (span asExportRecord at: #startTime) equals: requestedStartTime
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
	OpenTelemetry useContext: currentContext during: [ span := (tracer spanBuilderNamed: 'operation') startSpan ].
	self assert: span parent identicalTo: parentSpan.
	self assert: span spanContext traceId equals: parentSpan spanContext traceId
]

{ #category : 'tests' }
OTSpanBuilderTest >> testStartedSpanExposesRemoteParentSpanContext [

	| exportRecord parentContext provider span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	parentContext := OTSpanContext
		                 traceId: '00112233445566778899aabbccddeeff'
		                 spanId: '1122334455667788'
		                 traceFlags: '03'
		                 traceState: 'upstream=value'
		                 remote: true.
	span := (tracer spanBuilderNamed: 'operation')
		        inContext: (OTContext new withSpan: parentContext asNonRecordingSpan);
		        startSpan.
	exportRecord := span asExportRecord.
	self assert: (exportRecord at: #parentSpanContext) equals: parentContext.
	self assert: (exportRecord at: #parentSpanContext) isRemote
]

{ #category : 'tests' }
OTSpanBuilderTest >> testStonRoundTripPreservesErrorStatusDescription [

	| exportRecord provider roundTripped span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	span setStatus: OTSpan error description: 'boom'.
	roundTripped := STON fromString: (STON toString: span).
	exportRecord := roundTripped asExportRecord.
	self assert: (exportRecord at: #status) equals: OTSpan error.
	self assert: (exportRecord at: #statusDescription) equals: 'boom'
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
	OpenTelemetry useContext: currentContext during: [ span := tracer startSpanNamed: 'operation' ].
	self assert: span parent identicalTo: parentSpan.
	self assert: span spanContext traceId equals: parentSpan spanContext traceId
]

{ #category : 'tests' }
OTSpanBuilderTest >> testUpdateNameChangesRecordingSpanName [

	| exportRecord provider span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'original') startSpan.
	span updateName: 'renamed'.
	exportRecord := span asExportRecord.
	self assert: (exportRecord at: #name) equals: 'renamed'
]

{ #category : 'tests' }
OTSpanBuilderTest >> testUpdateNameDoesNothingAfterEnd [

	| exportRecord provider span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'original') startSpan.
	span end.
	span updateName: 'renamed'.
	exportRecord := span asExportRecord.
	self assert: (exportRecord at: #name) equals: 'original'
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
