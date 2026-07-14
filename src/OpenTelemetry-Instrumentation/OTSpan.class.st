"
I represent a single unit of work or a discrete operation in the OpenTelemetry framework.
Spans are fundamental to distributed tracing and provide a way to track and measure the execution of specific activities within a software application.

Spans capture timing and contextual information related to an operation, including start and end timestamps, associated attributes, events, and status.
They can be used to analyze performance bottlenecks, detect errors, and visualize the flow of activities across various components and services.

My instance-side API provides methods to set attributes, log events, set status, and control the timing of a span's lifecycle.
Additionally, my class-side API supports the creation of child spans to represent nested operations.
"
Class {
	#name : 'OTSpan',
	#superclass : 'Object',
	#instVars : [
		'spanId',
		'traceId',
		'parent',
		'name',
		'context',
		'kind',
		'startTime',
		'endTime',
		'ended',
		'status',
		'instrumentationName',
		'attributes',
		'events',
		'statusDescription',
		'traceFlags',
		'traceState',
		'links',
		'resource',
		'tracerProvider',
		'instrumentationScope',
		'limits',
		'droppedAttributesCount',
		'droppedEventsCount',
		'droppedLinksCount'
	],
	#classVars : [
		'Current'
	],
	#classInstVars : [
		'alwaysClient',
		'alwaysConsumer',
		'alwaysInternal',
		'alwaysProducer',
		'alwaysServer'
	],
	#category : 'OpenTelemetry-Instrumentation',
	#package : 'OpenTelemetry-Instrumentation'
}

{ #category : 'extracting' }
OTSpan class >> alwaysClient [

	^ alwaysClient ifNil: [ alwaysClient := [ :request | #client ] ]
]

{ #category : 'extracting' }
OTSpan class >> alwaysConsumer [

	^ alwaysConsumer ifNil: [ alwaysConsumer := [ :request | #consumer ] ]
]

{ #category : 'extracting' }
OTSpan class >> alwaysInternal [

	^ alwaysInternal ifNil: [ alwaysInternal := [ :request | #internal ] ]
]

{ #category : 'extracting' }
OTSpan class >> alwaysProducer [

	^ alwaysProducer ifNil: [ alwaysProducer := [ :request | #producer ] ]
]

{ #category : 'extracting' }
OTSpan class >> alwaysServer [

	^ alwaysServer ifNil: [ alwaysServer := [ :request | #server ] ]
]

{ #category : 'enumeration' }
OTSpan class >> client [
	"Indicates that the span covers the client-side wrapper around an RPC or other remote request."

	^ #client
]

{ #category : 'enumeration' }
OTSpan class >> consumer [
	"Indicates that the span describes consumer receiving a message from a broker.
Unlike client and server, there is no direct critical path latency relationship between producer and consumer spans."

	^ #consumer
]

{ #category : 'accessing' }
OTSpan class >> current [

	^ self currentContext span
]

{ #category : 'accessing' }
OTSpan class >> currentContext [

	^ Current ifNil: [ OTContext new ]
]

{ #category : 'accessing' }
OTSpan class >> currentContext: aContext [

	Current := aContext ifNil: [ OTContext new ] ifNotNil: [ aContext ].
	^ Current
]

{ #category : 'private - logging' }
OTSpan class >> defaultLimitWarningSink [

	^ [ :message | | transcript |
		transcript := Smalltalk globals at: #Transcript ifAbsent: [ nil ].
		transcript ifNotNil: [
			transcript
				show: message;
				cr ] ]
]

{ #category : 'enumeration' }
OTSpan class >> error [
	"The operation contains an error."

	^ #ERROR
]

{ #category : 'accessing' }
OTSpan class >> fromContext: aContext [

	^ aContext ifNotNil: [ aContext span ]
]

{ #category : 'recording' }
OTSpan class >> fromSton: stonReader [
	"enumeration"

	| representation span scope |
	representation := stonReader parseMap.
	span := self new.
	span spanId: (representation at: #spanId).
	span traceId: (representation at: #traceId).
	span name: (representation at: #name).
	span context: (representation at: #context).
	span kind: (representation at: #kind).
	span startTime: (representation at: #startTime).
	span status: (representation at: #status ifAbsent: [ self unset ]).
	span traceFlags: (representation at: #traceFlags ifAbsent: [ '01' ]).
	representation
		at: #traceState
		ifPresent: [ :aTraceState | span traceState: aTraceState ].
	representation
		at: #statusDescription
		ifPresent: [ :description | span statusDescription: description ].
	scope := representation
		at: #instrumentationScope
		ifAbsent: [ OTInstrumentationScope named: (representation at: #instrumentationName ifAbsent: [ '' ]) ].
	span instrumentationScope: scope.
	representation
		at: #parentId
		ifPresent: [ :parentId | span parent: (self fromParentId: parentId) ].
	representation
		at: #attributes
		ifPresent: [ :attributes | span attributes: attributes ].
	representation
		at: #events
		ifPresent: [ :events | span events: events ].
	representation
		at: #links
		ifPresent: [ :links | span links: links ].
	representation
		at: #resource
		ifPresent: [ :aResource | span resource: aResource ].
	span droppedAttributesCount: (representation at: #droppedAttributesCount ifAbsent: [ span droppedAttributesCount ]).
	span droppedEventsCount: (representation at: #droppedEventsCount ifAbsent: [ span droppedEventsCount ]).
	span droppedLinksCount: (representation at: #droppedLinksCount ifAbsent: [ span droppedLinksCount ]).
	span endTime: (representation at: #endTime).
	span endTime ifNotNil: [ span markEnded ].
	^ span
]

{ #category : 'enumeration' }
OTSpan class >> internal [
	"Default value. Indicates that the span is used internally."

	^ #internal
]

{ #category : 'private - id generation' }
OTSpan class >> isZeroHexIdentifier: aString [

	^ aString allSatisfy: [ :each | each = $0 ]
]

{ #category : 'private - logging' }
OTSpan class >> limitWarningSink [

	^ self
		propertyAt: #otLimitWarningSink
		ifAbsent: [ self defaultLimitWarningSink ]
]

{ #category : 'private - logging' }
OTSpan class >> limitWarningSink: aBlock [

	aBlock
		ifNil: [ self removeProperty: #otLimitWarningSink ifAbsent: [  ] ]
		ifNotNil: [ self propertyAt: #otLimitWarningSink put: aBlock ].
	^ self limitWarningSink
]

{ #category : 'accessing' }
OTSpan class >> linkFromSpanContext: aSpanContext [

	^ OTSpanLink spanContext: aSpanContext
]

{ #category : 'accessing' }
OTSpan class >> linkFromSpanContext: aSpanContext attributes: aDictionary [

	^ OTSpanLink spanContext: aSpanContext attributes: aDictionary
]

{ #category : 'private - id generation' }
OTSpan class >> newHexIdentifierOfSize: anInteger [

	| identifier |
	[
		identifier := String streamContents: [ :stream |
			anInteger timesRepeat: [
				stream nextPut: self randomHexDigit ] ].
		self isZeroHexIdentifier: identifier ] whileTrue.
	^ identifier
]

{ #category : 'private - id generation' }
OTSpan class >> newSpanId [

	^ self newHexIdentifierOfSize: 16
]

{ #category : 'private - id generation' }
OTSpan class >> newTraceId [

	^ self newHexIdentifierOfSize: 32
]

{ #category : 'private - logging' }
OTSpan class >> noteLimitWarningFor: aSpan message: aString [

	| warned |
	warned := self warnedSpans.
	(warned includes: aSpan) ifTrue: [ ^ false ].
	warned add: aSpan.
	self limitWarningSink value: aString.
	^ true
]

{ #category : 'enumeration' }
OTSpan class >> ok [
	"The operation has completed successfully."

	^ #OK
]

{ #category : 'enumeration' }
OTSpan class >> producer [
	"Indicates that the span describes producer sending a message to a broker.
	Unlike client and server, there is no direct critical path latency relationship between producer and consumer spans."

	^ #producer
]

{ #category : 'private - id generation' }
OTSpan class >> randomHexDigit [

	^ '0123456789abcdef' at: (SharedRandom globalGenerator nextInteger: 16)
]

{ #category : 'recording' }
OTSpan class >> recordException: anException [

	self current ifNotNil: [ :currentSpan | currentSpan recordException: anException ]
]

{ #category : 'class initialization' }
OTSpan class >> reset [

	Current := nil
]

{ #category : 'private - logging' }
OTSpan class >> resetLimitWarningState [

	self removeProperty: #otWarnedSpans ifAbsent: [  ].
	self removeProperty: #otLimitWarningSink ifAbsent: [  ]
]

{ #category : 'instance creation' }
OTSpan class >> rootIn: aContext [

	| span |
	span := self new.
	span
		context: aContext;
		traceId: self newTraceId;
		traceFlags: '01';
		traceState: nil.
	^ span
]

{ #category : 'enumeration' }
OTSpan class >> server [
	"Indicates that the span covers server-side handling of an RPC or other remote request."

	^ #server
]

{ #category : 'instance creation' }
OTSpan class >> under: parentSpan [

	| parentSpanContext span |
	parentSpanContext := parentSpan spanContext.
	span := self new.
	span
		parent: parentSpan;
		context: parentSpan context;
		traceId: parentSpan traceId;
		traceFlags: parentSpanContext traceFlags;
		traceState: parentSpanContext traceState.
	^ span
]

{ #category : 'enumeration' }
OTSpan class >> unset [
	"The default OpenTelemetry span status."

	^ #UNSET
]

{ #category : 'enumeration' }
OTSpan class >> validStatusCodes [

	^ { self unset. self ok. self error }
]

{ #category : 'private - logging' }
OTSpan class >> warnedSpans [

	^ self
		propertyAt: #otWarnedSpans
		ifAbsent: [
			| warned |
			warned := WeakSet new.
			self propertyAt: #otWarnedSpans put: warned.
			warned ]
]

{ #category : 'instance creation' }
OTSpan class >> wrapping: aSpanContext [

	^ OTNonRecordingSpan withSpanContext: aSpanContext
]

{ #category : 'recording' }
OTSpan >> addEvent: anOTSpanEvent [

	| limitedEvent |
	self isRecording ifFalse: [ ^ self ].
	(self attributesCountWithinLimit: self limits eventCountLimit currentSize: self events size)
		ifFalse: [
			self warnOnceAboutDiscardedData.
			self droppedEventsCount: self droppedEventsCount + 1.
			^ self ].
	limitedEvent := self limitedEventFrom: anOTSpanEvent.
	events := self events copyWith: limitedEvent.
	^ limitedEvent
]

{ #category : 'recording' }
OTSpan >> addEventNamed: aString [

	^ self addEventNamed: aString attributes: #() timestamp: DateAndTime now
]

{ #category : 'recording' }
OTSpan >> addEventNamed: aString attributes: aCollection [

	^ self addEventNamed: aString attributes: aCollection timestamp: DateAndTime now
]

{ #category : 'recording' }
OTSpan >> addEventNamed: aString attributes: aCollection timestamp: aDateAndTime [

	^ self addEvent: (OTSpanEvent named: aString attributes: aCollection timestamp: aDateAndTime)
]

{ #category : 'recording' }
OTSpan >> addEventNamed: aString timestamp: aDateAndTime [

	^ self addEventNamed: aString attributes: #() timestamp: aDateAndTime
]

{ #category : 'accessing' }
OTSpan >> addLink: aSpanLink [

	| limitedLink |
	self isRecording ifFalse: [ ^ self ].
	(self attributesCountWithinLimit: self limits linkCountLimit currentSize: self links size)
		ifFalse: [
			self warnOnceAboutDiscardedData.
			self droppedLinksCount: self droppedLinksCount + 1.
			^ self ].
	limitedLink := self limitedLinkFrom: aSpanLink.
	links := self links copyWith: limitedLink.
	^ limitedLink
]

{ #category : 'accessing' }
OTSpan >> addLinkSpanContext: aSpanContext [

	^ self addLinkSpanContext: aSpanContext attributes: nil
]

{ #category : 'accessing' }
OTSpan >> addLinkSpanContext: aSpanContext attributes: aDictionary [

	^ self addLink: (OTSpanLink spanContext: aSpanContext attributes: aDictionary)
]

{ #category : 'accessing' }
OTSpan >> addLinks: aCollection [

	self isRecording ifFalse: [ ^ self ].
	aCollection do: [ :each | self addLink: each ]
]

{ #category : 'accessing' }
OTSpan >> attributeAt: key put: value [

	| normalizedKey normalizedValue |
	self isRecording ifFalse: [ ^ self ].
	normalizedKey := OTAttributeNormalizer normalizeAttributeKey: key.
	normalizedValue := OTAttributeNormalizer
		normalizeAttributeValue: value
		lengthLimit: self limits attributeValueLengthLimit.
	attributes ifNil: [ attributes := OrderedDictionary new ].
	(self mayAddAttributeNamed: normalizedKey)
		ifTrue: [ attributes at: normalizedKey put: normalizedValue ]
		ifFalse: [
			self warnOnceAboutDiscardedData.
			self droppedAttributesCount: self droppedAttributesCount + 1 ]
]

{ #category : 'accessing' }
OTSpan >> attributes [

	^ attributes
]

{ #category : 'accessing' }
OTSpan >> attributes: aDictionary [

	| result |
	self isRecording ifFalse: [ ^ self ].
	result := OTAttributeNormalizer
		normalizeAttributes: aDictionary
		countLimit: self limits attributeCountLimit
		valueLengthLimit: self limits attributeValueLengthLimit.
	attributes := result first.
	result second > 0 ifTrue: [ self warnOnceAboutDiscardedData ].
	self droppedAttributesCount: self droppedAttributesCount + result second
]

{ #category : 'private' }
OTSpan >> attributesCountWithinLimit: aLimit currentSize: aSize [

	aLimit ifNil: [ ^ true ].
	^ aSize < aLimit
]

{ #category : 'accessing' }
OTSpan >> context [

	^ context
]

{ #category : 'accessing' }
OTSpan >> context: aContext [

	context := aContext
]

{ #category : 'accessing' }
OTSpan >> droppedAttributesCount [

	^ droppedAttributesCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
OTSpan >> droppedAttributesCount: anInteger [

	droppedAttributesCount := anInteger ifNil: [ 0 ] ifNotNil: [ anInteger ]
]

{ #category : 'accessing' }
OTSpan >> droppedEventsCount [

	^ droppedEventsCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
OTSpan >> droppedEventsCount: anInteger [

	droppedEventsCount := anInteger ifNil: [ 0 ] ifNotNil: [ anInteger ]
]

{ #category : 'accessing' }
OTSpan >> droppedLinksCount [

	^ droppedLinksCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
OTSpan >> droppedLinksCount: anInteger [

	droppedLinksCount := anInteger ifNil: [ 0 ] ifNotNil: [ anInteger ]
]

{ #category : 'control' }
OTSpan >> end [

	^ self end: DateAndTime now
]

{ #category : 'control' }
OTSpan >> end: aDateAndTime [

	self isEnded ifTrue: [ ^ self ].
	self endTime: (aDateAndTime ifNil: [ DateAndTime now ] ifNotNil: [ aDateAndTime ]).
	self tracerProvider ifNotNil: [ :aTracerProvider | aTracerProvider processEndingSpan: self ].
	self markEnded.
	self tracerProvider ifNotNil: [ :aTracerProvider | aTracerProvider processEndedSpan: self ].
	^ self
]

{ #category : 'accessing' }
OTSpan >> endTime [

	^ endTime
]

{ #category : 'accessing' }
OTSpan >> endTime: aDateAndTime [

	endTime := aDateAndTime
]

{ #category : 'accessing' }
OTSpan >> events [

	^ events ifNil: [ #() ]
]

{ #category : 'accessing' }
OTSpan >> events: aCollection [

	self isRecording ifFalse: [ ^ self ].
	events := #().
	aCollection ifNil: [ ^ self ].
	aCollection do: [ :each | self addEvent: each ].
	^ self
]

{ #category : 'private' }
OTSpan >> exceptionMessageFor: anException [ [

	^ anException messageText ifNil: [ anException description ]
]
]

{ #category : 'private' }
OTSpan >> exceptionStacktraceFor: anException [ [

	^ anException signalerContext
		ifNil: [ '' ]
		ifNotNil: [ :aContext | aContext longStack ]
]
]

{ #category : 'private' }
OTSpan >> exceptionTypeFor: anException [ [

	^ anException class name asString
]
]

{ #category : 'accessing' }
OTSpan >> inContext: aContext [

	| baseContext |
	baseContext := aContext ifNil: [ OTContext new ] ifNotNil: [ aContext ].
	^ baseContext withSpan: self
]

{ #category : 'initialization' }
OTSpan >> initialize [

	super initialize.
	spanId := self class newSpanId.
	traceFlags := '01'.
	traceState := nil.
	ended := false.
	links := nil.
	resource := OTResource empty.
	instrumentationScope := OTInstrumentationScope named: ''.
	instrumentationName := ''.
	limits := OTSpanLimits default.
	droppedAttributesCount := 0.
	droppedEventsCount := 0.
	droppedLinksCount := 0
]

{ #category : 'accessing' }
OTSpan >> instrumentationName [

	^ self instrumentationScope name
]

{ #category : 'accessing' }
OTSpan >> instrumentationName: aString [

	| currentScope normalizedName |
	currentScope := self instrumentationScope.
	normalizedName := aString ifNil: [ '' ] ifNotNil: [ aString ].
	instrumentationName := normalizedName.
	instrumentationScope := OTInstrumentationScope named: normalizedName version: currentScope version schemaUrl: currentScope schemaUrl attributes: currentScope allAttributes.
	^ normalizedName
]

{ #category : 'accessing' }
OTSpan >> instrumentationSchemaUrl [

	^ self instrumentationScope schemaUrl
]

{ #category : 'accessing' }
OTSpan >> instrumentationScope [

	instrumentationScope ifNil: [ instrumentationScope := OTInstrumentationScope named: (instrumentationName ifNil: [ '' ]) ].
	^ instrumentationScope
]

{ #category : 'accessing' }
OTSpan >> instrumentationScope: anInstrumentationScope [

	| scope |
	scope := anInstrumentationScope ifNil: [ OTInstrumentationScope named: '' ] ifNotNil: [ anInstrumentationScope ].
	instrumentationScope := scope.
	instrumentationName := scope name.
	^ scope
]

{ #category : 'accessing' }
OTSpan >> instrumentationScopeAttributes [

	^ self instrumentationScope allAttributes
]

{ #category : 'accessing' }
OTSpan >> instrumentationVersion [

	^ self instrumentationScope version
]

{ #category : 'testing' }
OTSpan >> isEnded [

	^ ended = true
]

{ #category : 'testing' }
OTSpan >> isRecording [

	^ self isEnded not
]

{ #category : 'private' }
OTSpan >> markEnded [

	ended := true.
	^ self
]

{ #category : 'accessing' }
OTSpan >> kind [

	^ kind
]

{ #category : 'accessing' }
OTSpan >> kind: aSpanKind [

	self isRecording ifFalse: [ ^ self ].
	kind := aSpanKind
]

{ #category : 'private - logging' }
OTSpan >> limitDiscardWarningMessage [

	^ String streamContents: [ :stream |
		stream
			nextPutAll: 'OpenTelemetry discarded attributes, events, or links due to configured span limits on span ';
			nextPut: $";
			nextPutAll: self name;
			nextPut: $";
			nextPutAll: '. Further warnings for this span are suppressed.' ]
]

{ #category : 'private' }
OTSpan >> limitedEventFrom: anEvent [

	| limitedEvent |
	(anEvent isNil or: [ (anEvent isKindOf: OTSpanEvent) not ]) ifTrue: [
		Error signal: 'OpenTelemetry spans require OTSpanEvent instances' ].
	limitedEvent := anEvent
		withAttributeCountLimit: self limits attributePerEventCountLimit
		valueLengthLimit: self limits attributeValueLengthLimit.
	limitedEvent droppedAttributesCount > anEvent droppedAttributesCount ifTrue: [
		self warnOnceAboutDiscardedData ].
	^ limitedEvent
]

{ #category : 'private' }
OTSpan >> limitedLinkFrom: aLink [

	| limitedLink |
	(aLink isNil or: [ (aLink isKindOf: OTSpanLink) not ]) ifTrue: [
		Error signal: 'OpenTelemetry spans require OTSpanLink instances' ].
	limitedLink := aLink
		withAttributeCountLimit: self limits attributePerLinkCountLimit
		valueLengthLimit: self limits attributeValueLengthLimit.
	limitedLink droppedAttributesCount > aLink droppedAttributesCount ifTrue: [
		self warnOnceAboutDiscardedData ].
	^ limitedLink
]

{ #category : 'accessing' }
OTSpan >> limits [

	^ limits ifNil: [ OTSpanLimits default ]
]

{ #category : 'accessing' }
OTSpan >> limits: someLimits [

	limits := (someLimits ifNil: [ OTSpanLimits default ] ifNotNil: [ someLimits ]) copy.
	^ limits
]

{ #category : 'accessing' }
OTSpan >> links [

	^ links ifNil: [ #() ]
]

{ #category : 'accessing' }
OTSpan >> links: aCollection [

	self isRecording ifFalse: [ ^ self ].
	links := #().
	aCollection ifNil: [ ^ self ].
	aCollection do: [ :each | self addLink: each ].
	^ self
]

{ #category : 'private' }
OTSpan >> mayAddAttributeNamed: aKey [

	^ (attributes notNil and: [ attributes includesKey: aKey ])
		or: [ self attributesCountWithinLimit: self limits attributeCountLimit currentSize: (attributes ifNil: [ 0 ] ifNotNil: [ attributes size ]) ]
]

{ #category : 'accessing' }
OTSpan >> name [

	^ name
]

{ #category : 'accessing' }
OTSpan >> name: aString [

	self isRecording ifFalse: [ ^ self ].
	name := aString
]

{ #category : 'private' }
OTSpan >> normalizeEventCollection: aCollection [

	aCollection ifNil: [ ^ #() ].
	^ (aCollection isDictionary
		ifTrue: [ aCollection associations collect: [ :each | OTSpanEvent named: each key asString attributes: { 'value' -> each value } timestamp: DateAndTime now ] ]
		ifFalse: [ aCollection collect: [ :each |
			each class = OTSpanEvent
				ifTrue: [ each ]
				ifFalse: [ each isAssociation
					ifTrue: [ OTSpanEvent named: each key asString attributes: { 'value' -> each value } timestamp: DateAndTime now ]
					ifFalse: [ OTSpanEvent named: each asString ] ] ] ]) asArray
]

{ #category : 'private' }
OTSpan >> normalizedExceptionAttributesFor: anException additionalAttributes: aCollection [ [

	| attributesToRecord |
	attributesToRecord := OrderedDictionary new.
	attributesToRecord
		at: 'exception.type' put: (self exceptionTypeFor: anException);
		at: 'exception.message' put: (self exceptionMessageFor: anException);
		at: 'exception.stacktrace' put: (self exceptionStacktraceFor: anException).
	aCollection ifNotNil: [
		aCollection associationsDo: [ :each |
			attributesToRecord at: each key put: each value ] ].
	^ attributesToRecord
]
]

{ #category : 'private' }
OTSpan >> normalizedStatusDescription: aString [

	(aString isNil or: [ aString isEmpty ]) ifTrue: [ ^ nil ].
	^ aString
]

{ #category : 'accessing' }
OTSpan >> parent [

	^ parent
]

{ #category : 'accessing' }
OTSpan >> parent: aSpan [

	parent := aSpan
]

{ #category : 'printing' }
OTSpan >> printOn: aStream [ [

	aStream
		nextPutAll: 'Span[';
		nextPutAll: self instrumentationName;
		nextPutAll: ': ';
		nextPutAll: name;
		nextPut: $]
]
]

{ #category : 'recording' }
OTSpan >> recordException: anException [ [

	^ self recordException: anException attributes: #()
]
]

{ #category : 'recording' }
OTSpan >> recordException: anException attributes: aCollection [ [

	self isRecording ifFalse: [ ^ self ].
	self setErrorStatusDescription: anException description.
	self addEventNamed: 'exception' attributes: (self normalizedExceptionAttributesFor: anException additionalAttributes: aCollection).
	^ self
]
]

{ #category : 'accessing' }
OTSpan >> resource [

	^ resource ifNil: [ OTResource empty ]
]

{ #category : 'accessing' }
OTSpan >> resource: anOTResource [

	resource := anOTResource
]

{ #category : 'accessing' }
OTSpan >> tracerProvider [

	^ tracerProvider
]

{ #category : 'accessing' }
OTSpan >> tracerProvider: aTracerProvider [

	tracerProvider := aTracerProvider
]

{ #category : 'recording' }
OTSpan >> setErrorStatus [
	"Specification: https://opentelemetry.io/docs/specs/otel/trace/api/#set-status
	Status values form a total order: Ok > Error > Unset.
	This means that setting Status with Ok will override any prior or future attempts to set span Status with Error or Unset."

	self setStatus: self class error
]

{ #category : 'recording' }
OTSpan >> setErrorStatusDescription: aString [

	self setStatus: self class error description: aString
]

{ #category : 'recording' }
OTSpan >> setOkStatus [

	self setStatus: self class ok
]

{ #category : 'recording' }
OTSpan >> setStatus: aSymbol [

	self setStatus: aSymbol description: nil
]

{ #category : 'recording' }
OTSpan >> setStatus: aSymbol description: aString [

	self isRecording ifFalse: [ ^ self ].
	self validateStatusCode: aSymbol.
	aSymbol = self class unset ifTrue: [ ^ self ].
	self status = self class ok ifTrue: [ ^ self ].
	aSymbol = self class ok ifTrue: [
		status := self class ok.
		statusDescription := nil.
		^ self ].
	status := self class error.
	statusDescription := self normalizedStatusDescription: aString
]

{ #category : 'accessing' }
OTSpan >> spanContext [

	^ OTSpanContext fromSpan: self
]

{ #category : 'accessing' }
OTSpan >> spanId [

	^ spanId
]

{ #category : 'accessing' }
OTSpan >> spanId: anIdentifier [

	spanId := anIdentifier
]

{ #category : 'control' }
OTSpan >> start [

	self isEnded ifTrue: [ ^ self ].
	OTSpan currentContext: self context.
	self startTime: DateAndTime now
]

{ #category : 'accessing' }
OTSpan >> startTime [

	^ startTime
]

{ #category : 'accessing' }
OTSpan >> startTime: aDateAndTime [

	startTime := aDateAndTime
]

{ #category : 'accessing' }
OTSpan >> status [

	^ status ifNil: [ self class unset ]
]

{ #category : 'accessing' }
OTSpan >> status: aSymbol [
	"Use `setStatus:` or `setStatus:description:` for normal span status mutation."

	self isRecording ifFalse: [ ^ self ].
	self validateStatusCode: aSymbol.
	status := aSymbol = self class unset
		          ifTrue: [ nil ]
		          ifFalse: [ aSymbol ].
	status = self class error ifFalse: [ statusDescription := nil ]
]

{ #category : 'accessing' }
OTSpan >> statusCode [

	^ self status
]

{ #category : 'accessing' }
OTSpan >> statusDescription [

	^ self status = self class error
		  ifTrue: [ statusDescription ]
		  ifFalse: [ nil ]
]

{ #category : 'accessing' }
OTSpan >> statusDescription: aString [

	self isRecording ifFalse: [ ^ self ].
	statusDescription := self normalizedStatusDescription: aString
]

{ #category : 'ston persistence' }
OTSpan >> stonOn: stonWriter [

	stonWriter writeObject: self streamMap: [ :map |
		map
			at: #spanId put: spanId;
			at: #traceId put: traceId;
			at: #name put: name;
			at: #context put: context;
			at: #kind put: kind;
			at: #startTime put: startTime;
			at: #endTime put: endTime;
			at: #status put: self status;
			at: #traceFlags put: self traceFlags;
			at: #instrumentationName put: self instrumentationName.
		self instrumentationScope isEmpty ifFalse: [ map at: #instrumentationScope put: self instrumentationScope ].
		parent ifNotNil: [ map at: #parentId put: parent spanId ].
		self traceState ifNotNil: [ :aTraceState | map at: #traceState put: aTraceState asHeaderValue ].
		self statusDescription ifNotNil: [ :description | map at: #statusDescription put: description ].
		attributes isEmptyOrNil ifFalse: [ map at: #attributes put: attributes ].
		events isEmptyOrNil ifFalse: [ map at: #events put: events ].
		self links ifNotEmpty: [ map at: #links put: self links ].
		self resource isEmpty ifFalse: [ map at: #resource put: self resource ].
		self droppedAttributesCount > 0 ifTrue: [ map at: #droppedAttributesCount put: self droppedAttributesCount ].
		self droppedEventsCount > 0 ifTrue: [ map at: #droppedEventsCount put: self droppedEventsCount ].
		self droppedLinksCount > 0 ifTrue: [ map at: #droppedLinksCount put: self droppedLinksCount ] ]
]

{ #category : 'accessing' }
OTSpan >> traceFlags [

	^ traceFlags ifNil: [ '01' ]
]

{ #category : 'accessing' }
OTSpan >> traceFlags: aString [

	traceFlags := aString
]

{ #category : 'accessing' }
OTSpan >> traceId [

	^ traceId
]

{ #category : 'accessing' }
OTSpan >> traceId: id [

	traceId := id
]

{ #category : 'accessing' }
OTSpan >> traceState [

	^ traceState
]

{ #category : 'accessing' }
OTSpan >> traceState: aTraceState [

	| normalized |
	normalized := OTTraceState from: aTraceState.
	traceState := normalized
]

{ #category : 'recording' }
OTSpan >> updateName: aString [ [

	^ self name: aString
]
]

{ #category : 'private' }
OTSpan >> validateStatusCode: aSymbol [

	(self class validStatusCodes includes: aSymbol) ifFalse: [
		Error signal: 'Invalid OpenTelemetry span status: ' , aSymbol printString ]
]

{ #category : 'private - logging' }
OTSpan >> warnOnceAboutDiscardedData [

	^ self class noteLimitWarningFor: self message: self limitDiscardWarningMessage
]
