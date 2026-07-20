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
OTSpanBuilderTest >> testEndIgnoresRepeatedCallsAndKeepsFirstEndTimestamp [

	| exportRecord firstTimestamp processor provider secondTimestamp span tracer |
	processor := OTRecordingSpanProcessor new.
	provider := OTTracerProvider new.
	provider spanProcessor: processor.
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	firstTimestamp := DateAndTime unixEpoch + (Duration milliSeconds: 1).
	secondTimestamp := DateAndTime unixEpoch + (Duration milliSeconds: 2).
	span end: firstTimestamp.
	span end: secondTimestamp.
	exportRecord := span asExportRecord.
	self assert: (exportRecord at: #endTime) equals: firstTimestamp.
	self assert: processor endingSpans asArray equals: { span }.
	self assert: processor endedSpans asArray equals: { span }
]

{ #category : 'tests' }
OTSpanBuilderTest >> testEndedAndNonRecordingSpansIgnoreAddedLinks [

	| endedSpan provider result tracer upstreamContext unsampledSpan |
	provider := OTTracerProvider new.
	provider
		spanProcessor: OTSimpleSpanProcessor new;
		sampler: OTAlwaysOffSampler new.
	tracer := provider tracerNamed: 'demo.scope'.
	upstreamContext := OTSpanContext
		                   traceId: '00112233445566778899aabbccddeeff'
		                   spanId: '1122334455667788'
		                   traceFlags: '01'
		                   traceState: nil
		                   remote: true.
	endedSpan := (OTTracerProvider new
		              spanProcessor: OTSimpleSpanProcessor new;
		              tracerNamed: 'demo.scope') startSpanNamed: 'ended'.
	endedSpan end.
	result := endedSpan addLinkSpanContext: upstreamContext.
	self assert: result identicalTo: endedSpan.
	self deny: (endedSpan asExportRecord includesKey: #links).
	unsampledSpan := tracer startSpanNamed: 'unsampled'.
	result := unsampledSpan addLinkSpanContext: upstreamContext.
	self assert: result identicalTo: unsampledSpan.
	self deny: (unsampledSpan asExportRecord includesKey: #links).
	self assert: (unsampledSpan end: DateAndTime unixEpoch) identicalTo: unsampledSpan
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
	self assert: (childSpan asExportRecord at: #parentSpanContext) equals: parentSpan spanContext.
	self assert: childSpan spanContext traceId equals: parentSpan spanContext traceId
]

{ #category : 'tests' }
OTSpanBuilderTest >> testEndedSpanIgnoresLateMutationsWhileKeepingStableContext [

	| exception exportRecord firstContext provider span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	firstContext := span spanContext.
	span end.
	exception := [ Error signal: 'boom' ]
		             on: Error
		             do: [ :error | error ].
	self deny: span isRecording.
	span attributeAt: 'late.attribute' put: 42.
	span addEventNamed: 'late.event'.
	span setStatus: OTSpan error description: 'late failure'.
	span recordException: exception.
	exportRecord := span asExportRecord.
	self assert: span spanContext identicalTo: firstContext.
	self deny: (exportRecord includesKey: #attributes).
	self deny: (exportRecord includesKey: #events).
	self assert: (exportRecord at: #status) equals: OTSpan unset.
	self deny: (exportRecord includesKey: #statusDescription)
]

{ #category : 'tests' }
OTSpanBuilderTest >> testEventTimestampsOutsideSpanRangeArePreserved [

	| afterEnd beforeStart eventsToExport exportRecord provider requestedEndTime requestedStartTime span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	requestedStartTime := DateAndTime unixEpoch + (Duration milliSeconds: 100).
	requestedEndTime := DateAndTime unixEpoch + (Duration milliSeconds: 200).
	beforeStart := DateAndTime unixEpoch + (Duration milliSeconds: 50).
	afterEnd := DateAndTime unixEpoch + (Duration milliSeconds: 250).
	span := (tracer spanBuilderNamed: 'operation')
		        startTimestamp: requestedStartTime;
		        startSpan.
	span addEventNamed: 'before-start' timestamp: beforeStart.
	span end: requestedEndTime.
	span addEventNamed: 'after-end' timestamp: afterEnd.
	exportRecord := span asExportRecord.
	eventsToExport := exportRecord at: #events.
	self assert: (exportRecord at: #startTime) equals: requestedStartTime.
	self assert: (exportRecord at: #endTime) equals: requestedEndTime.
	self assert: eventsToExport size equals: 1.
	self assert: eventsToExport first name equals: 'before-start'.
	self assert: eventsToExport first timestamp equals: beforeStart
]

{ #category : 'tests' }
OTSpanBuilderTest >> testEventsPreserveRecordingOrderEvenWithOutOfOrderTimestamps [

	| eventsToExport exportRecord firstTimestamp provider secondTimestamp span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	firstTimestamp := DateAndTime unixEpoch + (Duration milliSeconds: 20).
	secondTimestamp := DateAndTime unixEpoch + (Duration milliSeconds: 10).
	span addEventNamed: 'first' timestamp: firstTimestamp.
	span addEventNamed: 'second' timestamp: secondTimestamp.
	exportRecord := span asExportRecord.
	eventsToExport := exportRecord at: #events.
	self assert: eventsToExport size equals: 2.
	self assert: eventsToExport first name equals: 'first'.
	self assert: eventsToExport first timestamp equals: firstTimestamp.
	self assert: eventsToExport second name equals: 'second'.
	self assert: eventsToExport second timestamp equals: secondTimestamp
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

	self withParentContextWarningsDo: [ :warnings |
			| provider span tracer |
			provider := OTTracerProvider new.
			provider spanProcessor: OTSimpleSpanProcessor new.
			tracer := provider tracerNamed: 'demo.scope'.
			span := (tracer spanBuilderNamed: 'operation')
				        inContext: nil;
				        startSpan.
			self deny: (span asExportRecord includesKey: #parentSpanContext).
			self assert: warnings isEmpty ]
]

{ #category : 'tests' }
OTSpanBuilderTest >> testNoParentIgnoresImplicitCurrentSpan [

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
				            noParent;
				            startSpan ].
	self assert: rootSpan class identicalTo: OTNonRecordingSpan.
	self assert: rootSpan spanContext isValid.
	self deny: rootSpan spanContext traceId equals: parentSpan spanContext traceId
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
	self assert: (tracedChild asExportRecord at: #parentSpanContext) equals: parentSpan spanContext.
	self assert: rootSpan class identicalTo: OTNonRecordingSpan.
	self assert: rootSpan spanContext isValid.
	self deny: rootSpan spanContext traceId equals: parentSpan spanContext traceId.
	self assert: rootSpan effectiveContext baggage equals: baggage
]

{ #category : 'tests' }
OTSpanBuilderTest >> testNoParentReturnsBuilderForFluentConfiguration [

	| builder provider tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	builder := tracer spanBuilderNamed: 'operation'.
	self assert: builder noParent identicalTo: builder
]

{ #category : 'tests' }
OTSpanBuilderTest >> testOkStatusClearsDescriptionAndBecomesFinal [

	| exportRecord provider span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	span setStatus: OTSpan error description: 'boom'.
	span setStatus: OTSpan ok description: 'ignored'.
	span setStatus: OTSpan error description: 'later'.
	exportRecord := span asExportRecord.
	self assert: (exportRecord at: #status) equals: OTSpan ok.
	self deny: (exportRecord includesKey: #statusDescription)
]

{ #category : 'tests' }
OTSpanBuilderTest >> testOkStatusIgnoresDescriptionImmediately [

	| exportRecord provider span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	span setStatus: OTSpan ok description: 'ignored'.
	exportRecord := span asExportRecord.
	self assert: (exportRecord at: #status) equals: OTSpan ok.
	self deny: (exportRecord includesKey: #statusDescription)
]

{ #category : 'tests' }
OTSpanBuilderTest >> testRecordExceptionAdditionalAttributesOverrideGeneratedExceptionFields [

	| event exportRecord provider span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	[ Error signal: 'boom' ]
		on: Error
		do: [ :error |
				span recordException: error attributes: (OrderedDictionary new
						 at: 'exception.message' put: 'override';
						 at: 'exception.type' put: 'CustomError';
						 yourself) ].
	exportRecord := span asExportRecord.
	event := (exportRecord at: #events) first.
	self assert: event name equals: 'exception'.
	self assert: (event attributes at: 'exception.message') equals: 'override'.
	self assert: (event attributes at: 'exception.type') equals: 'CustomError'
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
OTSpanBuilderTest >> testRecordExceptionSupportsExplicitTimestamp [

	| event eventsToExport exportRecord provider requestedTimestamp span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	requestedTimestamp := DateAndTime unixEpoch + (Duration milliSeconds: 123).
	[ Error signal: 'boom' ]
		on: Error
		do: [ :error |
				span
					recordException: error
					attributes: (OrderedDictionary new
							 at: 'exception.escaped' put: false;
							 yourself)
					timestamp: requestedTimestamp ].
	exportRecord := span asExportRecord.
	eventsToExport := exportRecord at: #events.
	event := eventsToExport first.
	self assert: eventsToExport size equals: 1.
	self assert: event name equals: 'exception'.
	self assert: event timestamp equals: requestedTimestamp.
	self assert: (event attributes at: 'exception.message') equals: 'boom'.
	self assert: (event attributes at: 'exception.escaped') equals: false
]

{ #category : 'tests' }
OTSpanBuilderTest >> testRecordingSpanAddLinkRespectsLinkCountLimitAfterStart [

	| exportRecord firstContext linksToExport limits provider secondContext span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	limits := OTSpanLimits new.
	limits linkCountLimit: 1.
	provider spanLimits: limits.
	tracer := provider tracerNamed: 'demo.scope'.
	firstContext := OTSpanContext
		                traceId: '00112233445566778899aabbccddeeff'
		                spanId: '1122334455667788'
		                traceFlags: '01'
		                traceState: nil
		                remote: true.
	secondContext := OTSpanContext
		                 traceId: 'ffeeddccbbaa99887766554433221100'
		                 spanId: '8877665544332211'
		                 traceFlags: '01'
		                 traceState: nil
		                 remote: true.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	span addLinkSpanContext: firstContext.
	span addLinkSpanContext: secondContext.
	exportRecord := span asExportRecord.
	linksToExport := exportRecord at: #links.
	self assert: linksToExport size equals: 1.
	self assert: linksToExport first spanContext equals: firstContext.
	self assert: (exportRecord at: #droppedLinksCount) equals: 1
]

{ #category : 'tests' }
OTSpanBuilderTest >> testRecordingSpanCanAddLinkFromAnotherSpan [

	| exportRecord linkedSpan linksToExport provider span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	linkedSpan := (tracer spanBuilderNamed: 'linked') startSpan.
	span := (tracer spanBuilderNamed: 'operation')
		        addLinkSpan: linkedSpan attributes: (OrderedDictionary new
				         at: 'link.kind' put: 'follows_from';
				         yourself);
		        startSpan.
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
OTSpanBuilderTest >> testRecordingSpanExposesLinkConvenienceSetters [

	| explicitLink exportRecord linkedSpan linksToExport provider span tracer upstreamContext anotherUpstreamContext |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	linkedSpan := (tracer spanBuilderNamed: 'linked') startSpan.
	upstreamContext := OTSpanContext
		                   traceId: '00112233445566778899aabbccddeeff'
		                   spanId: '1122334455667788'
		                   traceFlags: '01'
		                   traceState: nil
		                   remote: true.
	anotherUpstreamContext := OTSpanContext
		                          traceId: 'ffeeddccbbaa99887766554433221100'
		                          spanId: '8877665544332211'
		                          traceFlags: '01'
		                          traceState: 'vendor=value'
		                          remote: true.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	explicitLink := OTSpanLink spanContext: upstreamContext attributes: (OrderedDictionary new
			                 at: 'kind' put: 'explicit';
			                 yourself).
	span addLink: explicitLink.
	span addLinkSpan: linkedSpan.
	span addLinkSpan: linkedSpan attributes: (OrderedDictionary new
			 at: 'kind' put: 'caused_by';
			 yourself).
	span addLinkSpanContext: upstreamContext.
	span addLinkSpanContext: anotherUpstreamContext attributes: (OrderedDictionary new
			 at: 'kind' put: 'follows_from';
			 yourself).
	exportRecord := span asExportRecord.
	linksToExport := exportRecord at: #links.
	self assert: linksToExport size equals: 5.
	self assert: linksToExport first equals: explicitLink.
	self assert: linksToExport second spanContext equals: linkedSpan spanContext.
	self assert: linksToExport second attributes isEmpty.
	self assert: linksToExport third spanContext equals: linkedSpan spanContext.
	self assert: (linksToExport third attributes at: 'kind') equals: 'caused_by'.
	self assert: linksToExport fourth spanContext equals: upstreamContext.
	self assert: linksToExport fourth attributes isEmpty.
	self assert: linksToExport fifth spanContext equals: anotherUpstreamContext.
	self assert: (linksToExport fifth attributes at: 'kind') equals: 'follows_from'
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
OTSpanBuilderTest >> testSetAttributeOverwritesPreviousValueForSameKey [

	| exportRecord provider span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	span
		attributeAt: 'http.method' put: 'GET';
		attributeAt: 'http.method' put: 'POST'.
	exportRecord := span asExportRecord.
	self assert: ((exportRecord at: #attributes) at: 'http.method') equals: 'POST'
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
	self assert: (span asExportRecord at: #parentSpanContext) equals: parentSpan spanContext.
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
	self assert: (span asExportRecord at: #parentSpanContext) equals: parentSpan spanContext.
	self assert: span spanContext traceId equals: parentSpan spanContext traceId
]

{ #category : 'tests' }
OTSpanBuilderTest >> testStartTimestampReturnsBuilderForFluentConfiguration [

	| builder provider requestedStartTime tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	builder := tracer spanBuilderNamed: 'operation'.
	requestedStartTime := DateAndTime unixEpoch + (Duration milliSeconds: 123).
	self assert: (builder startTimestamp: requestedStartTime) identicalTo: builder
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
OTSpanBuilderTest >> testStartingSpanDoesNotActivateCreatedSpan [

	| childSpan currentContext parentSpan provider tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	parentSpan := self sampledParentSpan.
	currentContext := OTContext new withSpan: parentSpan.
	OpenTelemetry useContext: currentContext during: [
			childSpan := tracer startSpanNamed: 'child'.
			self assert: OpenTelemetry currentSpan identicalTo: parentSpan.
			self assert: OpenTelemetry currentContext identicalTo: currentContext ].
	self assert: childSpan spanContext traceId equals: parentSpan spanContext traceId
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
	self assert: (span asExportRecord at: #parentSpanContext) equals: parentSpan spanContext.
	self assert: span spanContext traceId equals: parentSpan spanContext traceId
]

{ #category : 'tests' }
OTSpanBuilderTest >> testUnsetStatusUpdateIsIgnored [

	| exportRecord provider span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	span setStatus: OTSpan unset description: 'ignored'.
	exportRecord := span asExportRecord.
	self assert: (exportRecord at: #status) equals: OTSpan unset.
	self deny: (exportRecord includesKey: #statusDescription)
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
