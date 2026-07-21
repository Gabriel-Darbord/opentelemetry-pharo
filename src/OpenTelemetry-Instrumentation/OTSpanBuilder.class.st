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
	builder restoreTracer: aTracer spanName: aString.
	^ builder
]

{ #category : 'private' }
OTSpanBuilder class >> normalizedParentContextFrom: aContext [

	aContext ifNil: [ ^ OTContext new ].
	(aContext isKindOf: OTContext) ifTrue: [ ^ aContext ].
	self noteInvalidParentContext: aContext.
	^ OTContext new
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

	aSpanLink ifNil: [ ^ self ].
	(aSpanLink isKindOf: OTSpanLink) ifFalse: [
			OTSpan noteIgnoredInvalidArgument: aSpanLink forOperation: 'OTSpanBuilder>>addLink:'.
			^ self ].
	links add: aSpanLink.
	self
]

{ #category : 'configuring' }
OTSpanBuilder >> addLinkSpan: aSpan [

	^ self addLinkSpan: aSpan attributes: nil
]

{ #category : 'configuring' }
OTSpanBuilder >> addLinkSpan: aSpan attributes: aDictionary [

	| link |
	aSpan ifNil: [ ^ self ].
	link := [ OTSpanLink span: aSpan attributes: aDictionary ]
		        on: Error
		        do: [
				        OTSpan noteIgnoredInvalidArgument: aSpan forOperation: 'OTSpanBuilder>>addLinkSpan:attributes:'.
				        ^ self ].
	^ self addLink: link
]

{ #category : 'configuring' }
OTSpanBuilder >> addLinkSpanContext: aSpanContext [

	^ self addLinkSpanContext: aSpanContext attributes: nil
]

{ #category : 'configuring' }
OTSpanBuilder >> addLinkSpanContext: aSpanContext attributes: aDictionary [

	| link |
	aSpanContext ifNil: [ ^ self ].
	link := [ OTSpanLink spanContext: aSpanContext attributes: aDictionary ]
		        on: Error
		        do: [
				        OTSpan noteIgnoredInvalidArgument: aSpanContext forOperation: 'OTSpanBuilder>>addLinkSpanContext:attributes:'.
				        ^ self ].
	^ self addLink: link
]

{ #category : 'configuring' }
OTSpanBuilder >> addLinks: aCollection [

	aCollection ifNil: [ ^ self ].
	aCollection do: [ :each | self addLink: each ].
	^ self
]

{ #category : 'configuring' }
OTSpanBuilder >> asRoot [

	^ self noParent
]

{ #category : 'configuring' }
OTSpanBuilder >> attributeAt: aKey put: aValue [

	[
	attributes at: (OTAttributeNormalizer normalizeAttributeKey: aKey) put: (OTAttributeNormalizer normalizeAttributeValue: aValue) ]
		on: Error
		do: [
				OTSpan noteIgnoredInvalidArgument: aKey forOperation: 'OTSpanBuilder>>attributeAt:put:'.
				^ self ].
	self
]

{ #category : 'configuring' }
OTSpanBuilder >> attributes: aCollection [

	| normalized |
	aCollection ifNil: [ ^ self ].
	normalized := [ OTAttributeNormalizer normalizeAttributes: aCollection ]
		              on: Error
		              do: [
				              OTSpan noteIgnoredInvalidArgument: aCollection forOperation: 'OTSpanBuilder>>attributes:'.
				              ^ self ].
	normalized associationsDo: [ :each | attributes at: each key put: each value ].
	self
]

{ #category : 'configuring' }
OTSpanBuilder >> inContext: aContext [

	parentContext := self class normalizedParentContextFrom: aContext.
	usesCurrentContext := false.
	rootRequested := false.
	^ self
]

{ #category : 'configuring' }
OTSpanBuilder >> inCurrentContext [

	parentContext := nil.
	usesCurrentContext := true.
	rootRequested := false.
	self
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

	spanKind := OTSpan validateKind: aSpanKind
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

	rootRequested := true.
	self
]

{ #category : 'private' }
OTSpanBuilder >> restoreTracer: aTracer spanName: aString [

	tracer := aTracer.
	(aString isString or: [ aString isSymbol ]) ifTrue: [
			spanName := aString asString.
			^ spanName ].
	aString ifNotNil: [ OTSpan noteIgnoredInvalidArgument: aString forOperation: 'OTTracer>>spanBuilderNamed:' ].
	spanName := ''
]

{ #category : 'starting' }
OTSpanBuilder >> startSpan [

	| effectiveParentContext effectiveTraceFlags effectiveTraceState idGenerator parentSpan parentSpanContext provider samplingResult span traceId |
	effectiveParentContext := usesCurrentContext
		                          ifTrue: [ OTSpan currentContext ]
		                          ifFalse: [ self class normalizedParentContextFrom: parentContext ].
	rootRequested ifTrue: [ effectiveParentContext := effectiveParentContext withSpan: nil ].
	provider := tracer provider.
	provider ifNil: [
			parentSpan := rootRequested
				              ifTrue: [ nil ]
				              ifFalse: [ tracer parentSpanFrom: effectiveParentContext ].
			parentSpan
				ifNotNil: [
						parentSpan isRecording ifFalse: [ ^ parentSpan ].
						span := OTSpan wrapping: parentSpan spanContext ]
				ifNil: [ span := OTSpan wrapping: OTSpanContext invalid ].
			span
				restoreContext: (effectiveParentContext withSpan: span);
				restoreInstrumentationScope: tracer instrumentationScope;
				restoreResource: OTResource empty.
			^ span ].
	(tracer
		 enabledForSpanNamed: spanName
		 kind: spanKind
		 in: effectiveParentContext
		 attributes: attributes
		 links: links) ifFalse: [
		^ provider nonRecordingSpanIn: effectiveParentContext instrumentationScope: tracer instrumentationScope ].
	idGenerator := provider idGenerator.
	parentSpan := rootRequested
		              ifTrue: [ nil ]
		              ifFalse: [ tracer parentSpanFrom: effectiveParentContext ].
	parentSpanContext := parentSpan ifNotNil: [ parentSpan spanContext ].
	traceId := parentSpanContext ifNil: [ idGenerator generateTraceIdHex ] ifNotNil: [ parentSpanContext traceId ].
	samplingResult := provider
		                  samplingResultIn: effectiveParentContext
		                  traceId: traceId
		                  name: spanName
		                  kind: spanKind
		                  attributes: attributes
		                  links: links.
	samplingResult isRecording ifFalse: [
			^ provider
				  nonRecordingSpanIn: effectiveParentContext
				  parent: parentSpan
				  traceId: traceId
				  samplingResult: samplingResult
				  instrumentationScope: tracer instrumentationScope ].
	span := provider recordingSpanIn: effectiveParentContext parent: parentSpan instrumentationScope: tracer instrumentationScope.
	effectiveTraceFlags := provider traceFlagsForSamplingResult: samplingResult parentSpan: parentSpan.
	effectiveTraceState := samplingResult traceState
		                       ifNil: [ parentSpanContext ifNotNil: [ parentSpanContext traceState ] ]
		                       ifNotNil: [ samplingResult traceState ].
	span
		restoreLimits: provider spanLimits;
		restoreSpanContext: (OTSpanContext
				 traceId: traceId
				 spanId: idGenerator generateSpanIdHex
				 traceFlags: effectiveTraceFlags
				 traceState: effectiveTraceState
				 remote: false);
		restoreResource: provider resource;
		restoreContext: (effectiveParentContext withSpan: span);
		restoreName: spanName;
		restoreKind: spanKind;
		restoreInstrumentationScope: tracer instrumentationScope;
		restoreTracerProvider: provider;
		markStarted.
	samplingResult attributes do: [ :each | span attributeAt: each key put: each value ].
	attributes associationsDo: [ :each | span attributeAt: each key put: each value ].
	span restoreLinks: links.
	startTime ifNotNil: [ span restoreStartTime: startTime ].
	provider processStartedSpan: span parentContext: effectiveParentContext.
	^ span
]

{ #category : 'configuring' }
OTSpanBuilder >> startTimestamp: aDateAndTime [

	startTime := aDateAndTime.
	self
]
