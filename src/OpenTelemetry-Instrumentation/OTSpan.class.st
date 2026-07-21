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
		'spanContext',
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
		'links',
		'resource',
		'tracerProvider',
		'instrumentationScope',
		'limits',
		'droppedAttributesCount',
		'droppedEventsCount',
		'droppedLinksCount',
		'stateLock',
		'endingProcess'
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

	^ self fromContext: self currentContext
]

{ #category : 'accessing' }
OTSpan class >> currentContext [

	^ self currentContextsByProcess
		at: Processor activeProcess
		ifAbsent: [ OTContext new ]
]

{ #category : 'accessing' }
OTSpan class >> currentContext: aContext [

	| context currentProcess |
	context := aContext ifNil: [ OTContext new ] ifNotNil: [ aContext ].
	currentProcess := Processor activeProcess.
	context isEmpty
		ifTrue: [
			self currentContextsByProcess
				removeKey: currentProcess
				ifAbsent: [  ] ]
		ifFalse: [
			self currentContextsByProcess
				at: currentProcess
				put: context ].
	^ context
]

{ #category : 'private' }
OTSpan class >> currentContextsByProcess [

	^ OTClassStateStore
		valueAt: #otCurrentContextsByProcess
		forClass: self
		ifAbsent: [
			| contexts |
			contexts := WeakIdentityKeyDictionary new.
			OTClassStateStore
				valueAt: #otCurrentContextsByProcess
				forClass: self
				put: contexts.
			contexts ]
]

{ #category : 'private - logging' }
OTSpan class >> defaultLimitWarningSink [

	^ OTDiagnosticLogger defaultWarningSink
]

{ #category : 'enumeration' }
OTSpan class >> error [
	"The operation contains an error."

	^ #ERROR
]

{ #category : 'accessing' }
OTSpan class >> fromContext: aContext [

	| span |
	span := aContext ifNotNil: [ aContext span ].
	^ span ifNil: [ self wrapping: OTSpanContext invalid ] ifNotNil: [ span ]
]

{ #category : 'recording' }
OTSpan class >> fromSton: stonReader [
	"enumeration"

	| endTimestamp representation scope span traceFlags traceState |
	representation := stonReader parseMap.
	span := self newInternal.
	traceFlags := representation at: #traceFlags ifAbsent: [ '01' ].
	traceState := representation at: #traceState ifAbsent: [ nil ].
	span restoreSpanContext: (OTSpanContext
			 traceId: (representation at: #traceId)
			 spanId: (representation at: #spanId)
			 traceFlags: traceFlags
			 traceState: traceState
			 remote: false).
	span restoreName: (representation at: #name).
	span restoreContext: (representation at: #context).
	span restoreKind: (representation at: #kind).
	scope := representation
		         at: #instrumentationScope
		         ifAbsent: [ OTInstrumentationScope named: (representation at: #instrumentationName ifAbsent: [ '' ]) ].
	span restoreInstrumentationScope: scope.
	(representation includesKey: #parentSpanContext)
		ifTrue: [ span restoreParentSpanContext: (representation at: #parentSpanContext) ]
		ifFalse: [
				representation at: #parentId ifPresent: [ :parentId |
						span restoreParentSpanContext: (self
								 legacyParentSpanContextFromParentId: parentId
								 traceId: (representation at: #traceId)
								 traceFlags: traceFlags
								 traceState: traceState) ] ].
	span restoreStartTime: (representation at: #startTime).
	span
		restoreStatus: (representation at: #status ifAbsent: [ self unset ])
		description: (representation at: #statusDescription ifAbsent: [ nil ]).
	representation at: #attributes ifPresent: [ :attributes | span restoreAttributes: attributes ].
	representation at: #events ifPresent: [ :events | span restoreEvents: events ].
	representation at: #links ifPresent: [ :links | span restoreLinks: links ].
	representation at: #resource ifPresent: [ :aResource | span restoreResource: aResource ].
	span restoreDroppedAttributesCount: (representation at: #droppedAttributesCount ifAbsent: [ 0 ]).
	span restoreDroppedEventsCount: (representation at: #droppedEventsCount ifAbsent: [ 0 ]).
	span restoreDroppedLinksCount: (representation at: #droppedLinksCount ifAbsent: [ 0 ]).
	endTimestamp := representation at: #endTime ifAbsent: [ nil ].
	span restoreEndTime: endTimestamp.
	endTimestamp ifNotNil: [ span markEnded ].
	^ span
]

{ #category : 'enumeration' }
OTSpan class >> internal [
	"Default value. Indicates that the span is used internally."

	^ #internal
]

{ #category : 'private - id generation' }
OTSpan class >> isZeroHexIdentifier: aString [

	^ OTSpanContext isZeroHexIdentifier: aString
]

{ #category : 'private' }
OTSpan class >> legacyParentSpanContextFromParentId: aParentId traceId: aTraceId traceFlags: someTraceFlags traceState: aTraceState [

	^ OTSpanContext
		traceId: aTraceId
		spanId: aParentId
		traceFlags: someTraceFlags
		traceState: aTraceState
		remote: false
]

{ #category : 'private - logging' }
OTSpan class >> limitWarningSink [

	^ OTClassStateStore
		valueAt: #otLimitWarningSink
		forClass: self
		ifAbsent: [ self defaultLimitWarningSink ]
]

{ #category : 'private - logging' }
OTSpan class >> limitWarningSink: aBlock [

	aBlock
		ifNil: [
			OTClassStateStore
				removeValueAt: #otLimitWarningSink
				forClass: self
				ifAbsent: [  ] ]
		ifNotNil: [
			OTClassStateStore
				valueAt: #otLimitWarningSink
				forClass: self
				put: aBlock ].
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

{ #category : 'instance creation' }
OTSpan class >> new [

	Error signal: 'Spans must be created through an OTTracer. Use OTTracer>>startSpanNamed: or OTTracer>>spanBuilderNamed:.'
]

{ #category : 'private' }
OTSpan class >> newInternal [

	^ super new
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

	^ OTSpanContext randomHexDigit
]

{ #category : 'recording' }
OTSpan class >> recordException: anException [

	self current recordException: anException
]

{ #category : 'recording' }
OTSpan class >> recordException: anException attributes: aCollection [

	self current recordException: anException attributes: aCollection
]

{ #category : 'recording' }
OTSpan class >> recordException: anException attributes: aCollection timestamp: aDateAndTime [

	self current recordException: anException attributes: aCollection timestamp: aDateAndTime
]

{ #category : 'recording' }
OTSpan class >> recordException: anException timestamp: aDateAndTime [

	self current recordException: anException timestamp: aDateAndTime
]

{ #category : 'class initialization' }
OTSpan class >> reset [

	Current := nil.
	OTClassStateStore
		removeValueAt: #otCurrentContextsByProcess
		forClass: self
		ifAbsent: [  ]
]

{ #category : 'private - logging' }
OTSpan class >> resetLimitWarningState [

	OTClassStateStore
		removeValueAt: #otWarnedSpans
		forClass: self
		ifAbsent: [  ].
	OTClassStateStore
		removeValueAt: #otLimitWarningSink
		forClass: self
		ifAbsent: [  ]
]

{ #category : 'enumeration' }
OTSpan class >> server [
	"Indicates that the span covers server-side handling of an RPC or other remote request."

	^ #server
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

	^ OTClassStateStore
		valueAt: #otWarnedSpans
		forClass: self
		ifAbsent: [
			| warned |
			warned := WeakSet new.
			OTClassStateStore
				valueAt: #otWarnedSpans
				forClass: self
				put: warned.
			warned ]
]

{ #category : 'instance creation' }
OTSpan class >> wrapping: aSpanContext [

	^ OTNonRecordingSpan withSpanContext: aSpanContext
]

{ #category : 'recording' }
OTSpan >> addEvent: anOTSpanEvent [

	^ stateLock critical: [
			  | currentEvents limitedEvent |
			  self currentProcessMayMutateSpanState ifFalse: [ ^ self ].
			  currentEvents := events ifNil: [ #(  ) ].
			  (self attributesCountWithinLimit: self effectiveLimits eventCountLimit currentSize: currentEvents size) ifFalse: [
					  self warnOnceAboutDiscardedData.
					  self restoreDroppedEventsCount: self effectiveDroppedEventsCount + 1.
					  ^ self ].
			  limitedEvent := self limitedEventFrom: anOTSpanEvent.
			  events := currentEvents copyWith: limitedEvent.
			  limitedEvent ]
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

{ #category : 'recording' }
OTSpan >> addLink: anOTSpanLink [

	^ stateLock critical: [
			  | currentLinks limitedLink |
			  self currentProcessMayMutateSpanState ifFalse: [ ^ self ].
			  currentLinks := self effectiveLinks.
			  (self attributesCountWithinLimit: self effectiveLimits linkCountLimit currentSize: currentLinks size) ifFalse: [
					  self warnOnceAboutDiscardedData.
					  self restoreDroppedLinksCount: self effectiveDroppedLinksCount + 1.
					  ^ self ].
			  limitedLink := self limitedLinkFrom: anOTSpanLink.
			  links := currentLinks copyWith: limitedLink.
			  limitedLink ]
]

{ #category : 'recording' }
OTSpan >> addLinkSpan: aSpan [

	^ self addLinkSpan: aSpan attributes: nil
]

{ #category : 'recording' }
OTSpan >> addLinkSpan: aSpan attributes: aDictionary [

	^ self addLink: (OTSpanLink span: aSpan attributes: aDictionary)
]

{ #category : 'recording' }
OTSpan >> addLinkSpanContext: aSpanContext [

	^ self addLinkSpanContext: aSpanContext attributes: nil
]

{ #category : 'recording' }
OTSpan >> addLinkSpanContext: aSpanContext attributes: aDictionary [

	^ self addLink: (OTSpanLink spanContext: aSpanContext attributes: aDictionary)
]

{ #category : 'private - exporting' }
OTSpan >> asExportRecord [

	^ stateLock critical: [
			  | data linksToExport parentContext resourceToExport scope spanContextToExport statusDescriptionToExport statusToExport traceStateToExport |
			  data := OrderedDictionary new.
			  linksToExport := self effectiveLinks.
			  parentContext := self effectiveParentSpanContext.
			  resourceToExport := self effectiveResource.
			  scope := self effectiveInstrumentationScope.
			  spanContextToExport := self spanContext.
			  statusDescriptionToExport := self effectiveStatusDescription.
			  statusToExport := self effectiveStatus.
			  traceStateToExport := spanContextToExport traceState.
			  data
				  at: #spanId put: spanContextToExport spanId;
				  at: #traceId put: spanContextToExport traceId;
				  at: #name put: name;
				  at: #kind put: kind;
				  at: #startTime put: startTime;
				  at: #endTime put: endTime;
				  at: #status put: statusToExport;
				  at: #traceFlags put: spanContextToExport traceFlags;
				  at: #instrumentationName put: scope name.
			  scope isEmpty ifFalse: [ data at: #instrumentationScope put: scope ].
			  parentContext ifNotNil: [
					  data
						  at: #parentSpanContext put: parentContext;
						  at: #parentId put: parentContext spanId ].
			  traceStateToExport ifNotNil: [ :aTraceState | data at: #traceState put: aTraceState asHeaderValue ].
			  statusDescriptionToExport ifNotNil: [ :description | data at: #statusDescription put: description ].
			  attributes isEmptyOrNil ifFalse: [ data at: #attributes put: attributes ].
			  events isEmptyOrNil ifFalse: [ data at: #events put: events ].
			  linksToExport ifNotEmpty: [ data at: #links put: linksToExport ].
			  resourceToExport isEmpty ifFalse: [ data at: #resource put: resourceToExport ].
			  self effectiveDroppedAttributesCount > 0 ifTrue: [
				  data at: #droppedAttributesCount put: self effectiveDroppedAttributesCount ].
			  self effectiveDroppedEventsCount > 0 ifTrue: [ data at: #droppedEventsCount put: self effectiveDroppedEventsCount ].
			  self effectiveDroppedLinksCount > 0 ifTrue: [ data at: #droppedLinksCount put: self effectiveDroppedLinksCount ].
			  data ]
]

{ #category : 'accessing' }
OTSpan >> attributeAt: key put: value [

	^ stateLock critical: [
			  | normalizedKey normalizedValue |
			  self currentProcessMayMutateSpanState ifFalse: [ ^ self ].
			  normalizedKey := OTAttributeNormalizer normalizeAttributeKey: key.
			  normalizedValue := OTAttributeNormalizer
				                     normalizeAttributeValue: value
				                     lengthLimit: self effectiveLimits attributeValueLengthLimit.
			  attributes ifNil: [ attributes := OrderedDictionary new ].
			  (self mayAddAttributeNamed: normalizedKey)
				  ifTrue: [ attributes at: normalizedKey put: normalizedValue ]
				  ifFalse: [
						  self warnOnceAboutDiscardedData.
						  self restoreDroppedAttributesCount: self effectiveDroppedAttributesCount + 1 ] ]
]

{ #category : 'accessing' }
OTSpan >> attributes [

	^ stateLock critical: [ attributes ifNil: [ OrderedDictionary new ] ifNotNil: [ attributes copy ] ]
]

{ #category : 'private' }
OTSpan >> attributesCountWithinLimit: aLimit currentSize: aSize [

	aLimit ifNil: [ ^ true ].
	^ aSize < aLimit
]

{ #category : 'private' }
OTSpan >> currentProcessMayMutateSpanState [

	^ self recordingStateAllowsMutation and: [ endingProcess isNil or: [ endingProcess == Processor activeProcess ] ]
]

{ #category : 'accessing' }
OTSpan >> droppedAttributesCount [

	^ stateLock critical: [ self effectiveDroppedAttributesCount ]
]

{ #category : 'accessing' }
OTSpan >> droppedEventsCount [

	^ stateLock critical: [ self effectiveDroppedEventsCount ]
]

{ #category : 'accessing' }
OTSpan >> droppedLinksCount [

	^ stateLock critical: [ self effectiveDroppedLinksCount ]
]

{ #category : 'private' }
OTSpan >> effectiveContext [

	^ context
]

{ #category : 'private' }
OTSpan >> effectiveDroppedAttributesCount [

	^ droppedAttributesCount ifNil: [ 0 ]
]

{ #category : 'private' }
OTSpan >> effectiveDroppedEventsCount [

	^ droppedEventsCount ifNil: [ 0 ]
]

{ #category : 'private' }
OTSpan >> effectiveDroppedLinksCount [

	^ droppedLinksCount ifNil: [ 0 ]
]

{ #category : 'private' }
OTSpan >> effectiveInstrumentationScope [

	instrumentationScope ifNil: [ instrumentationScope := OTInstrumentationScope named: (instrumentationName ifNil: [ '' ]) ].
	^ instrumentationScope
]

{ #category : 'private' }
OTSpan >> effectiveLimits [

	^ limits ifNil: [ OTSpanLimits default ]
]

{ #category : 'private' }
OTSpan >> effectiveLinks [

	^ links ifNil: [ #(  ) ]
]

{ #category : 'private' }
OTSpan >> effectiveParentSpanContext [

	^ parent ifNotNil: [ parent spanContext ]
]

{ #category : 'private' }
OTSpan >> effectiveResource [

	^ resource ifNil: [ OTResource empty ]
]

{ #category : 'private' }
OTSpan >> effectiveStatus [

	^ status ifNil: [ self class unset ]
]

{ #category : 'private' }
OTSpan >> effectiveStatusDescription [

	^ self effectiveStatus = self class error
		  ifTrue: [ statusDescription ]
		  ifFalse: [ nil ]
]

{ #category : 'control' }
OTSpan >> end [

	^ self end: DateAndTime now
]

{ #category : 'control' }
OTSpan >> end: aDateAndTime [

	| currentProcess provider shouldEnd |
	currentProcess := Processor activeProcess.
	provider := nil.
	shouldEnd := stateLock critical: [
			             (ended or: [ endingProcess notNil ])
				             ifTrue: [ false ]
				             ifFalse: [
						             endTime := aDateAndTime ifNil: [ DateAndTime now ] ifNotNil: [ aDateAndTime ].
						             endingProcess := currentProcess.
						             provider := tracerProvider.
						             true ] ].
	shouldEnd ifFalse: [ ^ self ].
	[ provider ifNotNil: [ :aTracerProvider | aTracerProvider processEndingSpan: self ] ] ensure: [
			stateLock critical: [
					endingProcess == currentProcess ifTrue: [
							endingProcess := nil.
							ended := true ] ] ].
	provider ifNotNil: [ :aTracerProvider | aTracerProvider processEndedSpan: self ].
	self
]

{ #category : 'accessing' }
OTSpan >> endTime [

	^ stateLock critical: [ endTime ]
]

{ #category : 'private' }
OTSpan >> ensureMutableCreationState [

	startTime ifNil: [ ^ self ].
	Error signal: 'OpenTelemetry span creation state cannot change after the span has started'
]

{ #category : 'private' }
OTSpan >> ensureMutableSpanContextState [

	startTime ifNil: [ ^ self ].
	Error signal: 'OpenTelemetry recording span identity cannot change after the span has started'
]

{ #category : 'accessing' }
OTSpan >> events [

	^ stateLock critical: [ events ifNil: [ #(  ) ] ifNotNil: [ events copy ] ]
]

{ #category : 'private' }
OTSpan >> exceptionMessageFor: anException [

	^ anException messageText ifNil: [ anException description ]
]

{ #category : 'private' }
OTSpan >> exceptionStacktraceFor: anException [

	^ anException signalerContext ifNil: [ '' ] ifNotNil: [ :aContext | aContext longStack ]
]

{ #category : 'private' }
OTSpan >> exceptionTypeFor: anException [

	^ anException class name asString
]

{ #category : 'testing' }
OTSpan >> hasEnded [

	^ stateLock critical: [ ended ]
]

{ #category : 'initialization' }
OTSpan >> initialize [

	super initialize.
	spanContext := nil.
	ended := false.
	endingProcess := nil.
	stateLock := Semaphore forMutualExclusion.
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
OTSpan >> instrumentationLibrary [

	^ self instrumentationScope
]

{ #category : 'accessing' }
OTSpan >> instrumentationName [

	^ self instrumentationScope name
]

{ #category : 'accessing' }
OTSpan >> instrumentationScope [

	^ stateLock critical: [ self effectiveInstrumentationScope ]
]

{ #category : 'accessing' }
OTSpan >> instrumentationVersion [

	^ self instrumentationScope version
]

{ #category : 'testing' }
OTSpan >> isRecording [

	^ stateLock critical: [ ended not ]
]

{ #category : 'accessing' }
OTSpan >> kind [

	^ stateLock critical: [ kind ]
]

{ #category : 'private - logging' }
OTSpan >> limitDiscardWarningMessage [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'OpenTelemetry discarded attributes, events, or links due to configured span limits on span ';
				  nextPut: $";
				  nextPutAll: (name ifNil: [ '' ]);
				  nextPut: $";
				  nextPutAll: '. Further warnings for this span are suppressed.' ]
]

{ #category : 'private' }
OTSpan >> limitedEventFrom: anEvent [

	| limitedEvent |
	(anEvent isNil or: [ (anEvent isKindOf: OTSpanEvent) not ]) ifTrue: [
		Error signal: 'OpenTelemetry spans require OTSpanEvent instances' ].
	limitedEvent := anEvent
		                withAttributeCountLimit: self effectiveLimits attributePerEventCountLimit
		                valueLengthLimit: self effectiveLimits attributeValueLengthLimit.
	limitedEvent droppedAttributesCount > anEvent droppedAttributesCount ifTrue: [ self warnOnceAboutDiscardedData ].
	^ limitedEvent
]

{ #category : 'private' }
OTSpan >> limitedLinkFrom: aLink [

	| limitedLink |
	(aLink isNil or: [ (aLink isKindOf: OTSpanLink) not ]) ifTrue: [
		Error signal: 'OpenTelemetry spans require OTSpanLink instances' ].
	limitedLink := aLink
		               withAttributeCountLimit: self effectiveLimits attributePerLinkCountLimit
		               valueLengthLimit: self effectiveLimits attributeValueLengthLimit.
	limitedLink droppedAttributesCount > aLink droppedAttributesCount ifTrue: [ self warnOnceAboutDiscardedData ].
	^ limitedLink
]

{ #category : 'accessing' }
OTSpan >> links [

	^ stateLock critical: [ self effectiveLinks copy ]
]

{ #category : 'private' }
OTSpan >> markEnded [

	ended := true.
	^ self
]

{ #category : 'private' }
OTSpan >> markStarted [

	ended ifTrue: [ ^ self ].
	self restoreStartTime: DateAndTime now
]

{ #category : 'private' }
OTSpan >> mayAddAttributeNamed: aKey [

	^ (attributes notNil and: [ attributes includesKey: aKey ]) or: [
			  self
				  attributesCountWithinLimit: self effectiveLimits attributeCountLimit
				  currentSize: (attributes ifNil: [ 0 ] ifNotNil: [ attributes size ]) ]
]

{ #category : 'accessing' }
OTSpan >> name [

	^ stateLock critical: [ name ]
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
OTSpan >> normalizedExceptionAttributesFor: anException additionalAttributes: aCollection [

	| attributesToRecord normalizedAdditionalAttributes |
	attributesToRecord := OrderedDictionary new.
	attributesToRecord
		at: 'exception.type' put: (self exceptionTypeFor: anException);
		at: 'exception.message' put: (self exceptionMessageFor: anException);
		at: 'exception.stacktrace' put: (self exceptionStacktraceFor: anException).
	normalizedAdditionalAttributes := OTAttributeNormalizer normalizeAttributes: aCollection.
	normalizedAdditionalAttributes associationsDo: [ :each | attributesToRecord at: each key put: each value ].
	^ attributesToRecord
]

{ #category : 'private' }
OTSpan >> normalizedStatusDescription: aString [

	(aString isNil or: [ aString isEmpty ]) ifTrue: [ ^ nil ].
	^ aString
]

{ #category : 'accessing' }
OTSpan >> parentSpanContext [

	^ stateLock critical: [ self effectiveParentSpanContext ]
]

{ #category : 'printing' }
OTSpan >> printOn: aStream [

	| scope |
	scope := self effectiveInstrumentationScope.
	aStream
		nextPutAll: 'Span[';
		nextPutAll: scope name;
		nextPutAll: ': ';
		nextPutAll: (name ifNil: [ '' ]);
		nextPut: $]
]

{ #category : 'recording' }
OTSpan >> recordException: anException [

	^ self recordException: anException attributes: #(  ) timestamp: DateAndTime now
]

{ #category : 'recording' }
OTSpan >> recordException: anException attributes: aCollection [

	^ self recordException: anException attributes: aCollection timestamp: DateAndTime now
]

{ #category : 'recording' }
OTSpan >> recordException: anException attributes: aCollection timestamp: aDateAndTime [

	| exceptionAttributes |
	self isRecording ifFalse: [ ^ self ].
	exceptionAttributes := (self normalizedExceptionAttributesFor: anException additionalAttributes: aCollection) associations.
	self addEventNamed: 'exception' attributes: exceptionAttributes timestamp: aDateAndTime
]

{ #category : 'recording' }
OTSpan >> recordException: anException timestamp: aDateAndTime [

	^ self recordException: anException attributes: #(  ) timestamp: aDateAndTime
]

{ #category : 'private' }
OTSpan >> recordingStateAllowsMutation [

	^ ended not
]

{ #category : 'accessing' }
OTSpan >> resource [

	^ stateLock critical: [ self effectiveResource ]
]

{ #category : 'private' }
OTSpan >> restoreAttributes: aDictionary [

	| normalized |
	self isRecording ifFalse: [ ^ self ].
	aDictionary ifNil: [ ^ self ].
	normalized := OTAttributeNormalizer
		              normalizeAttributes: aDictionary
		              countLimit: self effectiveLimits attributeCountLimit
		              valueLengthLimit: self effectiveLimits attributeValueLengthLimit.
	normalized first associationsDo: [ :each | self attributeAt: each key put: each value ].
	normalized second > 0 ifTrue: [ self warnOnceAboutDiscardedData ].
	self restoreDroppedAttributesCount: self effectiveDroppedAttributesCount + normalized second
]

{ #category : 'private' }
OTSpan >> restoreContext: aContext [

	context := aContext
]

{ #category : 'private' }
OTSpan >> restoreDroppedAttributesCount: anInteger [

	droppedAttributesCount := anInteger ifNil: [ 0 ] ifNotNil: [ anInteger ]
]

{ #category : 'private' }
OTSpan >> restoreDroppedEventsCount: anInteger [

	droppedEventsCount := anInteger ifNil: [ 0 ] ifNotNil: [ anInteger ]
]

{ #category : 'private' }
OTSpan >> restoreDroppedLinksCount: anInteger [

	droppedLinksCount := anInteger ifNil: [ 0 ] ifNotNil: [ anInteger ]
]

{ #category : 'private' }
OTSpan >> restoreEndTime: aDateAndTime [

	endTime := aDateAndTime
]

{ #category : 'private' }
OTSpan >> restoreEvents: aCollection [

	self isRecording ifFalse: [ ^ self ].
	aCollection ifNil: [ ^ self ].
	aCollection do: [ :each | self addEvent: each ]
]

{ #category : 'private' }
OTSpan >> restoreInstrumentationScope: anInstrumentationScope [

	| scope |
	scope := anInstrumentationScope ifNil: [ OTInstrumentationScope named: '' ] ifNotNil: [ anInstrumentationScope ].
	instrumentationScope := scope.
	instrumentationName := scope name.
	^ scope
]

{ #category : 'private' }
OTSpan >> restoreKind: aSpanKind [

	self ensureMutableCreationState.
	kind := aSpanKind
]

{ #category : 'private' }
OTSpan >> restoreLimits: someLimits [

	limits := (someLimits ifNil: [ OTSpanLimits default ] ifNotNil: [ someLimits ]) copy.
	^ limits
]

{ #category : 'private' }
OTSpan >> restoreLinks: aCollection [

	| currentLinks limitedLink |
	self isRecording ifFalse: [ ^ self ].
	aCollection ifNil: [ ^ self ].
	aCollection do: [ :each |
			currentLinks := self effectiveLinks.
			(self attributesCountWithinLimit: self effectiveLimits linkCountLimit currentSize: currentLinks size)
				ifFalse: [
						self warnOnceAboutDiscardedData.
						self restoreDroppedLinksCount: self effectiveDroppedLinksCount + 1 ]
				ifTrue: [
						limitedLink := self limitedLinkFrom: each.
						links := currentLinks copyWith: limitedLink ] ]
]

{ #category : 'private' }
OTSpan >> restoreName: aString [

	name := aString
]

{ #category : 'private' }
OTSpan >> restoreParent: aSpan [

	self ensureMutableCreationState.
	parent := aSpan
]

{ #category : 'private' }
OTSpan >> restoreParentSpanContext: anObject [

	self ensureMutableCreationState.
	parent := anObject ifNotNil: [
			          (anObject isKindOf: OTSpanContext)
				          ifTrue: [ anObject asNonRecordingSpan ]
				          ifFalse: [ anObject spanContext asNonRecordingSpan ] ]
]

{ #category : 'private' }
OTSpan >> restoreResource: anOTResource [

	resource := anOTResource
]

{ #category : 'private' }
OTSpan >> restoreSpanContext: anOTSpanContext [

	| normalized |
	anOTSpanContext ifNil: [
			spanContext := nil.
			^ nil ].
	self ensureMutableSpanContextState.
	normalized := anOTSpanContext isRemote
		              ifTrue: [ anOTSpanContext asLocal ]
		              ifFalse: [ anOTSpanContext ].
	spanContext := normalized.
	^ spanContext
]

{ #category : 'private' }
OTSpan >> restoreStartTime: aDateAndTime [

	startTime := aDateAndTime
]

{ #category : 'private' }
OTSpan >> restoreStatus: aSymbol description: aString [

	self validateStatusCode: aSymbol.
	status := aSymbol = self class unset
		          ifTrue: [ nil ]
		          ifFalse: [ aSymbol ].
	statusDescription := status = self class error
		                     ifTrue: [ self normalizedStatusDescription: aString ]
		                     ifFalse: [ nil ]
]

{ #category : 'private' }
OTSpan >> restoreTracerProvider: aTracerProvider [

	tracerProvider := aTracerProvider
]

{ #category : 'recording' }
OTSpan >> setStatus: aSymbol [

	self setStatus: aSymbol description: nil
]

{ #category : 'recording' }
OTSpan >> setStatus: aSymbol description: aString [

	^ stateLock critical: [
			  self currentProcessMayMutateSpanState
				  ifFalse: [ self ]
				  ifTrue: [
						  self validateStatusCode: aSymbol.
						  aSymbol = self class unset
							  ifTrue: [ self ]
							  ifFalse: [
									  self effectiveStatus = self class ok
										  ifTrue: [ self ]
										  ifFalse: [
												  aSymbol = self class ok
													  ifTrue: [
															  status := self class ok.
															  statusDescription := nil.
															  self ]
													  ifFalse: [
															  status := self class error.
															  statusDescription := self normalizedStatusDescription: aString.
															  self ] ] ] ] ]
]

{ #category : 'accessing' }
OTSpan >> spanContext [

	^ spanContext ifNil: [ OTSpanContext invalid ]
]

{ #category : 'accessing' }
OTSpan >> spanId [

	^ stateLock critical: [ spanContext spanId ]
]

{ #category : 'accessing' }
OTSpan >> startTime [

	^ stateLock critical: [ startTime ]
]

{ #category : 'accessing' }
OTSpan >> status [

	^ stateLock critical: [ self effectiveStatus ]
]

{ #category : 'accessing' }
OTSpan >> statusDescription [

	^ stateLock critical: [ self effectiveStatusDescription ]
]

{ #category : 'ston persistence' }
OTSpan >> stonOn: stonWriter [

	| linksToExport parentContext resourceToExport scope spanContextToExport statusDescriptionToExport statusToExport traceStateToExport |
	linksToExport := self effectiveLinks.
	parentContext := self effectiveParentSpanContext.
	resourceToExport := self effectiveResource.
	scope := self effectiveInstrumentationScope.
	spanContextToExport := self spanContext.
	statusDescriptionToExport := self effectiveStatusDescription.
	statusToExport := self effectiveStatus.
	traceStateToExport := spanContextToExport traceState.
	stonWriter writeObject: self streamMap: [ :map |
			map
				at: #spanId put: spanContextToExport spanId;
				at: #traceId put: spanContextToExport traceId;
				at: #name put: name;
				at: #context put: context;
				at: #kind put: kind;
				at: #startTime put: startTime;
				at: #endTime put: endTime;
				at: #status put: statusToExport;
				at: #traceFlags put: spanContextToExport traceFlags;
				at: #instrumentationName put: scope name.
			scope isEmpty ifFalse: [ map at: #instrumentationScope put: scope ].
			parentContext ifNotNil: [
					map
						at: #parentSpanContext put: parentContext;
						at: #parentId put: parentContext spanId ].
			traceStateToExport ifNotNil: [ :aTraceState | map at: #traceState put: aTraceState asHeaderValue ].
			statusDescriptionToExport ifNotNil: [ :description | map at: #statusDescription put: description ].
			attributes isEmptyOrNil ifFalse: [ map at: #attributes put: attributes ].
			events isEmptyOrNil ifFalse: [ map at: #events put: events ].
			linksToExport ifNotEmpty: [ map at: #links put: linksToExport ].
			resourceToExport isEmpty ifFalse: [ map at: #resource put: resourceToExport ].
			self effectiveDroppedAttributesCount > 0 ifTrue: [ map at: #droppedAttributesCount put: self effectiveDroppedAttributesCount ].
			self effectiveDroppedEventsCount > 0 ifTrue: [ map at: #droppedEventsCount put: self effectiveDroppedEventsCount ].
			self effectiveDroppedLinksCount > 0 ifTrue: [ map at: #droppedLinksCount put: self effectiveDroppedLinksCount ] ]
]

{ #category : 'accessing' }
OTSpan >> traceFlags [

	^ stateLock critical: [ spanContext traceFlags ]
]

{ #category : 'accessing' }
OTSpan >> traceId [

	^ stateLock critical: [ spanContext traceId ]
]

{ #category : 'accessing' }
OTSpan >> traceState [

	^ stateLock critical: [ spanContext traceState ]
]

{ #category : 'recording' }
OTSpan >> updateName: aString [

	^ stateLock critical: [
			  self currentProcessMayMutateSpanState
				  ifTrue: [
						  name := aString.
						  self ]
				  ifFalse: [ self ] ]
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
