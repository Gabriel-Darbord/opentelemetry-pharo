"
I represent one traced operation in the OpenTelemetry tracing API and SDK.

A span carries immutable tracing identity through its SpanContext and accumulates recording state such as timing, attributes, events, links, and status while it is active.

Application code obtains spans through OTTracer and OTSpanBuilder. Once created, spans can be enriched, ended, activated in context, exported, and inspected by SDK components such as span processors and exporters.
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

{ #category : 'private - logging' }
OTSpan class >> argumentSummaryFor: anObject [

	anObject ifNil: [ ^ 'nil' ].
	^ 'an instance of ' , anObject class name asString
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
	scope := representation at: #instrumentationScope ifAbsent: [ OTInstrumentationScope named: '' ].
	span restoreInstrumentationScope: scope.
	representation at: #parentSpanContext ifPresent: [ :parentSpanContext | span restoreParentSpanContext: parentSpanContext ].
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

{ #category : 'private' }
OTSpan class >> normalizedTimestamp: aDateAndTime forOperation: aString default: aBlock [

	aDateAndTime ifNil: [ ^ aBlock value ].
	(aDateAndTime isKindOf: DateAndTime) ifTrue: [ ^ aDateAndTime ].
	self noteIgnoredInvalidArgument: aDateAndTime forOperation: aString.
	^ aBlock value
]

{ #category : 'private - logging' }
OTSpan class >> noteIgnoredInvalidArgument: anObject forOperation: aString [

	OTDiagnosticLogger current warning:
		'OpenTelemetry ignored an invalid argument for ' , aString , ': ' , (self argumentSummaryFor: anObject)
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
OTSpan class >> validKinds [

	^ {
		  self internal.
		  self server.
		  self client.
		  self producer.
		  self consumer }
]

{ #category : 'enumeration' }
OTSpan class >> validStatusCodes [

	^ { self unset. self ok. self error }
]

{ #category : 'enumeration' }
OTSpan class >> validateKind: aSpanKind [

	aSpanKind ifNil: [ ^ self internal ].
	(self validKinds includes: aSpanKind) ifTrue: [ ^ aSpanKind ].
	self noteIgnoredInvalidArgument: aSpanKind forOperation: 'span kind selection'.
	^ self internal
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

	(anOTSpanEvent isKindOf: OTSpanEvent) ifFalse: [
			self class noteIgnoredInvalidArgument: anOTSpanEvent forOperation: 'OTSpan>>addEvent:'.
			^ self ].
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

	| timestamp |
	(aString isString or: [ aString isSymbol ]) ifFalse: [
			self class noteIgnoredInvalidArgument: aString forOperation: 'OTSpan>>addEventNamed:attributes:timestamp:'.
			^ self ].
	timestamp := self class
		             normalizedTimestamp: aDateAndTime
		             forOperation: 'OTSpan>>addEventNamed:attributes:timestamp:'
		             default: [ DateAndTime now ].
	^ [ self addEvent: (OTSpanEvent named: aString asString attributes: aCollection timestamp: timestamp) ]
		  on: Error
		  do: [
				  self class noteIgnoredInvalidArgument: aCollection forOperation: 'OTSpan>>addEventNamed:attributes:timestamp:'.
				  self ]
]

{ #category : 'recording' }
OTSpan >> addEventNamed: aString timestamp: aDateAndTime [

	^ self addEventNamed: aString attributes: #() timestamp: aDateAndTime
]

{ #category : 'recording' }
OTSpan >> addLink: anOTSpanLink [

	anOTSpanLink ifNil: [ ^ self ].
	(anOTSpanLink isKindOf: OTSpanLink) ifFalse: [
			self class noteIgnoredInvalidArgument: anOTSpanLink forOperation: 'OTSpan>>addLink:'.
			^ self ].
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

	| link |
	aSpan ifNil: [ ^ self ].
	link := [ OTSpanLink span: aSpan attributes: aDictionary ]
		        on: Error
		        do: [
				        self class noteIgnoredInvalidArgument: aSpan forOperation: 'OTSpan>>addLinkSpan:attributes:'.
				        ^ self ].
	^ self addLink: link
]

{ #category : 'recording' }
OTSpan >> addLinkSpanContext: aSpanContext [

	^ self addLinkSpanContext: aSpanContext attributes: nil
]

{ #category : 'recording' }
OTSpan >> addLinkSpanContext: aSpanContext attributes: aDictionary [

	| link |
	aSpanContext ifNil: [ ^ self ].
	link := [ OTSpanLink spanContext: aSpanContext attributes: aDictionary ]
		        on: Error
		        do: [
				        self class noteIgnoredInvalidArgument: aSpanContext forOperation: 'OTSpan>>addLinkSpanContext:attributes:'.
				        ^ self ].
	^ self addLink: link
]

{ #category : 'private' }
OTSpan >> applyStatusCode: aSymbol description: aString [

	aSymbol = self class ok
		ifTrue: [
				status := self class ok.
				statusDescription := nil ]
		ifFalse: [
				status := self class error.
				statusDescription := self normalizedStatusDescription: aString ].
	self
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
				  at: #traceFlags put: spanContextToExport traceFlags.
			  scope isEmpty ifFalse: [ data at: #instrumentationScope put: scope ].
			  parentContext ifNotNil: [ data at: #parentSpanContext put: parentContext ].
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
			  normalizedKey := [ OTAttributeNormalizer normalizeAttributeKey: key ]
				                   on: Error
				                   do: [
						                   self class noteIgnoredInvalidArgument: key forOperation: 'OTSpan>>attributeAt:put:'.
						                   ^ self ].
			  normalizedValue := [
			                     OTAttributeNormalizer
				                     normalizeAttributeValue: value
				                     lengthLimit: self effectiveLimits attributeValueLengthLimit ]
				                     on: Error
				                     do: [
						                     self class noteIgnoredInvalidArgument: value forOperation: 'OTSpan>>attributeAt:put:'.
						                     ^ self ].
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
OTSpan >> beginEndingAt: aDateAndTime fromProcess: aProcess [

	^ stateLock critical: [
			  (ended or: [ endingProcess notNil ]) ifTrue: [ ^ nil ].
			  endTime := aDateAndTime.
			  endingProcess := aProcess.
			  tracerProvider ]
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

	| currentProcess endTimestamp provider |
	currentProcess := Processor activeProcess.
	endTimestamp := self class normalizedTimestamp: aDateAndTime forOperation: 'OTSpan>>end:' default: [ DateAndTime now ].
	provider := self beginEndingAt: endTimestamp fromProcess: currentProcess.
	provider ifNil: [ ^ self ].
	[ provider processEndingSpan: self ] ensure: [ self finishEndingFromProcess: currentProcess ].
	provider processEndedSpan: self.
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

{ #category : 'private' }
OTSpan >> finishEndingFromProcess: aProcess [

	stateLock critical: [
			endingProcess == aProcess ifTrue: [
					endingProcess := nil.
					ended := true ] ]
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

{ #category : 'private' }
OTSpan >> isValidStatusCodeArgument: aSymbol [

	aSymbol ifNil: [
			self class noteIgnoredInvalidArgument: aSymbol forOperation: 'OTSpan>>setStatus:description:'.
			^ false ].
	(self class validStatusCodes includes: aSymbol) ifTrue: [ ^ true ].
	self class noteIgnoredInvalidArgument: aSymbol forOperation: 'OTSpan>>setStatus:description:'.
	^ false
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

	| description |
	aString ifNil: [ ^ nil ].
	(aString isString or: [ aString isSymbol ]) ifFalse: [
			self class noteIgnoredInvalidArgument: aString forOperation: 'OTSpan>>setStatus:description:'.
			^ nil ].
	description := aString asString.
	description isEmpty ifTrue: [ ^ nil ].
	^ description
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
	anException ifNil: [
			self class noteIgnoredInvalidArgument: anException forOperation: 'OTSpan>>recordException:attributes:timestamp:'.
			^ self ].
	self isRecording ifFalse: [ ^ self ].
	exceptionAttributes := [ (self normalizedExceptionAttributesFor: anException additionalAttributes: aCollection) associations ]
		                       on: Error
		                       do: [
				                       self class
					                       noteIgnoredInvalidArgument: anException
					                       forOperation: 'OTSpan>>recordException:attributes:timestamp:'.
				                       ^ self ].
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
	kind := self class validateKind: aSpanKind
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

	(self isValidStatusCodeArgument: aSymbol) ifFalse: [ ^ self ].
	^ stateLock critical: [
			  self currentProcessMayMutateSpanState ifFalse: [ ^ self ].
			  aSymbol = self class unset ifTrue: [ ^ self ].
			  self effectiveStatus = self class ok ifTrue: [ ^ self ].
			  self applyStatusCode: aSymbol description: aString ]
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
				at: #traceFlags put: spanContextToExport traceFlags.
			scope isEmpty ifFalse: [ map at: #instrumentationScope put: scope ].
			parentContext ifNotNil: [ map at: #parentSpanContext put: parentContext ].
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

	(aString isString or: [ aString isSymbol ]) ifFalse: [
			self class noteIgnoredInvalidArgument: aString forOperation: 'OTSpan>>updateName:'.
			^ self ].
	^ stateLock critical: [
			  self currentProcessMayMutateSpanState
				  ifTrue: [
						  name := aString asString.
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
