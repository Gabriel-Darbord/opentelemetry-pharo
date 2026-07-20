"
A builder for configuring and starting spans through a tracer.
"
Class {
	#name : 'OTSpanBuilder',
	#superclass : 'Object',
	#instVars : [
		'tracer',
		'spanName',
		'parentContext',
		'usesCurrentContext',
		'spanKind',
		'attributes',
		'startTime',
		'rootRequested',
		'links'
	],
	#category : 'OpenTelemetry-Instrumentation',
	#package : 'OpenTelemetry-Instrumentation'
}

{ #category : 'private - logging' }
OTSpanBuilder class >> defaultParentContextWarningSink [

	^ OTDiagnosticLogger defaultWarningSink
]

{ #category : 'instance creation' }
OTSpanBuilder class >> forTracer: aTracer name: aString [

	| builder |
	builder := self new.
	builder
		tracer: aTracer;
		spanName: (aString ifNil: [ '' ] ifNotNil: [ aString ]).
	^ builder
]

{ #category : 'private' }
OTSpanBuilder class >> normalizedParentContextFrom: aContext [

	aContext ifNil: [ ^ OTContext new ].
	(aContext isKindOf: OTContext) ifTrue: [ ^ aContext ].
	Error signal: 'OpenTelemetry span builders require an OTContext parent. Wrap spans with OTContext>>withSpan:.'
]

{ #category : 'private - logging' }
OTSpanBuilder class >> noteInvalidParentContext: anObject [

	self parentContextWarningSink value:
		'OpenTelemetry span builder ignored an invalid parent context and used a root context instead: '
			, (anObject ifNil: [ 'nil' ] ifNotNil: [ anObject printString ])
]

{ #category : 'private - logging' }
OTSpanBuilder class >> parentContextWarningSink [

	^ OTClassStateStore
		valueAt: #otParentContextWarningSink
		forClass: self
		ifAbsent: [ self defaultParentContextWarningSink ]
]

{ #category : 'private - logging' }
OTSpanBuilder class >> parentContextWarningSink: aBlock [

	aBlock
		ifNil: [
			OTClassStateStore
				removeValueAt: #otParentContextWarningSink
				forClass: self
				ifAbsent: [  ] ]
		ifNotNil: [
			OTClassStateStore
				valueAt: #otParentContextWarningSink
				forClass: self
				put: aBlock ].
	^ self parentContextWarningSink
]

{ #category : 'configuring' }
OTSpanBuilder >> addLink: aSpanLink [

	(aSpanLink isNil or: [ (aSpanLink isKindOf: OTSpanLink) not ]) ifTrue: [
		Error signal: 'OpenTelemetry span builders require OTSpanLink instances' ].
	links add: aSpanLink.
	^ self
]

{ #category : 'configuring' }
OTSpanBuilder >> addLinkSpan: aSpan [

	^ self addLinkSpan: aSpan attributes: nil
]

{ #category : 'configuring' }
OTSpanBuilder >> addLinkSpan: aSpan attributes: aDictionary [

	^ self addLink: (OTSpanLink span: aSpan attributes: aDictionary)
]

{ #category : 'configuring' }
OTSpanBuilder >> addLinkSpanContext: aSpanContext [

	^ self addLinkSpanContext: aSpanContext attributes: nil
]

{ #category : 'configuring' }
OTSpanBuilder >> addLinkSpanContext: aSpanContext attributes: aDictionary [

	^ self addLink: (OTSpanLink spanContext: aSpanContext attributes: aDictionary)
]

{ #category : 'configuring' }
OTSpanBuilder >> addLinks: aCollection [

	aCollection ifNil: [ ^ self ].
	aCollection do: [ :each | self addLink: each ].
	^ self
]

{ #category : 'configuring' }
OTSpanBuilder >> attributeAt: aKey put: aValue [

	attributes
		at: (OTAttributeNormalizer normalizeAttributeKey: aKey)
		put: (OTAttributeNormalizer normalizeAttributeValue: aValue).
	^ self
]

{ #category : 'configuring' }
OTSpanBuilder >> attributes: aCollection [

	| normalized |
	aCollection ifNil: [ ^ self ].
	normalized := OTAttributeNormalizer normalizeAttributes: aCollection.
	normalized associationsDo: [ :each |
		attributes at: each key put: each value ].
	^ self
]

{ #category : 'configuring' }
OTSpanBuilder >> inContext: aContext [

	parentContext := self class normalizedParentContextFrom: aContext.
	usesCurrentContext := false.
	rootRequested := false.
	^ self
]

{ #category : 'initialization' }
OTSpanBuilder >> initialize [

	super initialize.
	parentContext := nil.
	usesCurrentContext := true.
	spanKind := OTSpan internal.
	attributes := OrderedDictionary new.
	links := OrderedCollection new.
	rootRequested := false.
	startTime := nil
]

{ #category : 'configuring' }
OTSpanBuilder >> kind: aSpanKind [

	spanKind := aSpanKind ifNil: [ OTSpan internal ] ifNotNil: [ aSpanKind ].
	^ self
]

{ #category : 'configuring' }
OTSpanBuilder >> links: aCollection [

	links := OrderedCollection new.
	aCollection ifNil: [ ^ self ].
	aCollection do: [ :each | self addLink: each ].
	^ self
]

{ #category : 'configuring' }
OTSpanBuilder >> noParent [

	rootRequested := true
]

{ #category : 'accessing' }
OTSpanBuilder >> spanName: aString [

	spanName := aString ifNil: [ '' ] ifNotNil: [ aString ]
]

{ #category : 'starting' }
OTSpanBuilder >> startSpan [

	| effectiveParentContext effectiveTraceFlags effectiveTraceState idGenerator parentSpan parentSpanContext samplingResult span traceId |
	effectiveParentContext := usesCurrentContext
		                          ifTrue: [ OTSpan currentContext ]
		                          ifFalse: [ self class normalizedParentContextFrom: parentContext ].
	rootRequested ifTrue: [ effectiveParentContext := effectiveParentContext withSpan: nil ].
	(tracer
		 enabledForSpanNamed: spanName
		 kind: spanKind
		 in: effectiveParentContext
		 attributes: attributes
		 links: links) ifFalse: [ ^ tracer provider nonRecordingSpanIn: effectiveParentContext ].
	idGenerator := tracer provider idGenerator.
	parentSpan := rootRequested
		              ifTrue: [ nil ]
		              ifFalse: [ tracer parentSpanFrom: effectiveParentContext ].
	parentSpanContext := parentSpan ifNotNil: [ parentSpan spanContext ].
	traceId := parentSpanContext ifNil: [ idGenerator generateTraceIdHex ] ifNotNil: [ parentSpanContext traceId ].
	samplingResult := tracer provider
		                  samplingResultIn: effectiveParentContext
		                  traceId: traceId
		                  name: spanName
		                  kind: spanKind
		                  attributes: attributes
		                  links: links.
	samplingResult isRecording ifFalse: [
			^ tracer provider
				  nonRecordingSpanIn: effectiveParentContext
				  parent: parentSpan
				  traceId: traceId
				  samplingResult: samplingResult
				  instrumentationScope: tracer instrumentationScope ].
	span := tracer provider
		        recordingSpanIn: effectiveParentContext
		        parent: parentSpan
		        instrumentationScope: tracer instrumentationScope.
	effectiveTraceFlags := tracer provider traceFlagsForSamplingResult: samplingResult parentSpan: parentSpan.
	effectiveTraceState := samplingResult traceState ifNil: [ span spanContext traceState ] ifNotNil: [ samplingResult traceState ].
	span
		restoreLimits: tracer provider spanLimits;
		restoreSpanContext: (OTSpanContext
				 traceId: traceId
				 spanId: idGenerator generateSpanIdHex
				 traceFlags: effectiveTraceFlags
				 traceState: effectiveTraceState
				 remote: false);
		restoreResource: tracer provider resource;
		restoreContext: (effectiveParentContext withSpan: span);
		restoreName: spanName;
		restoreKind: spanKind;
		restoreInstrumentationScope: tracer instrumentationScope;
		restoreTracerProvider: tracer provider;
		markStarted.
	samplingResult attributes do: [ :each | span attributeAt: each key put: each value ].
	attributes associationsDo: [ :each | span attributeAt: each key put: each value ].
	span restoreLinks: links.
	startTime ifNotNil: [ span restoreStartTime: startTime ].
	tracer provider processStartedSpan: span parentContext: effectiveParentContext.
	^ span
]

{ #category : 'configuring' }
OTSpanBuilder >> startTimestamp: aDateAndTime [

	startTime := aDateAndTime
]

{ #category : 'accessing' }
OTSpanBuilder >> tracer: aTracer [

	tracer := aTracer
]
