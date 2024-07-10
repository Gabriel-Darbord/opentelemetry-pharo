"
I represent a single unit of work or a discrete operation in the OpenTelemetry framework.
Spans are fundamental to distributed tracing and provide a way to track and measure the execution of specific activities within a software application.

Spans capture timing and contextual information related to an operation, including start and end timestamps, associated attributes, events, and status.
They can be used to analyze performance bottlenecks, detect errors, and visualize the flow of activities across various components and services.

My instance-side API provides methods to set attributes, log events, set status, and control the timing of a span's lifecycle.
Additionally, my class-side API supports the creation of child spans to represent nested operations.
"
Class {
	#name : #OTSpan,
	#superclass : #Object,
	#instVars : [
		'spanId',
		'traceId',
		'parent',
		'name',
		'context',
		'kind',
		'startTime',
		'endTime',
		'status',
		'instrumentationName',
		'attributes',
		'events'
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
	#category : #'OpenTelemetry-Instrumentation'
}

{ #category : #extracting }
OTSpan class >> alwaysClient [

	^ alwaysClient ifNil: [ alwaysClient := [ :request | #client ] ]
]

{ #category : #extracting }
OTSpan class >> alwaysConsumer [

	^ alwaysConsumer ifNil: [ alwaysConsumer := [ :request | #consumer ] ]
]

{ #category : #extracting }
OTSpan class >> alwaysInternal [

	^ alwaysInternal ifNil: [ alwaysInternal := [ :request | #internal ] ]
]

{ #category : #extracting }
OTSpan class >> alwaysProducer [

	^ alwaysProducer ifNil: [ alwaysProducer := [ :request | #producer ] ]
]

{ #category : #extracting }
OTSpan class >> alwaysServer [

	^ alwaysServer ifNil: [ alwaysServer := [ :request | #server ] ]
]

{ #category : #enumeration }
OTSpan class >> client [
	"Indicates that the span covers the client-side wrapper around an RPC or other remote request."

	^ #client
]

{ #category : #enumeration }
OTSpan class >> consumer [
	"Indicates that the span describes consumer receiving a message from a broker.
Unlike client and server, there is no direct critical path latency relationship between producer and consumer spans."

	^ #consumer
]

{ #category : #accessing }
OTSpan class >> current [

	^ Current
]

{ #category : #recording }
OTSpan class >> fromSton: stonReader [
	"enumeration"

	| span representation |
	span := self new.
	representation := stonReader parseMapOrListRepresentation.
	span instVarNamed: #spanId put: (representation at: #spanId).
	span instVarNamed: #traceId put: (representation at: #traceId).
	span name: (representation at: #name).
	span context: (representation at: #context).
	span kind: (representation at: #kind).
	span startTime: (representation at: #startTime).
	span endTime: (representation at: #endTime).
	span status: (representation at: #status).
	span instrumentationName: (representation at: #instrumentationName).
	representation
		at: #parentId
		ifPresent: [ :parentId | "self allInstances detect: [ :s | s spanId = parentId ]"
			 ].
	representation
		at: #attributes
		ifPresent: [ :attributes | span attributes: attributes ].
	representation
		at: #events
		ifPresent: [ :events | span events: events ].
	^ span
]

{ #category : #enumeration }
OTSpan class >> internal [
	"Default value. Indicates that the span is used internally."

	^ #internal
]

{ #category : #enumeration }
OTSpan class >> producer [
	"Indicates that the span describes producer sending a message to a broker.
	Unlike client and server, there is no direct critical path latency relationship between producer and consumer spans."

	^ #producer
]

{ #category : #recording }
OTSpan class >> recordException: anException [

	Current ifNotNil: [ Current recordException: anException ]
]

{ #category : #'class initialization' }
OTSpan class >> reset [

	Current := nil
]

{ #category : #'instance creation' }
OTSpan class >> rootIn: aContext [

	^ self new
		  context: aContext;
		  traceId: UUID new
]

{ #category : #enumeration }
OTSpan class >> server [
	"Indicates that the span covers server-side handling of an RPC or other remote request."

	^ #server
]

{ #category : #'instance creation' }
OTSpan class >> under: parentSpan [

	^ self new
		  parent: parentSpan;
		  context: parentSpan context;
		  traceId: parentSpan traceId
]

{ #category : #accessing }
OTSpan >> attributeAt: key put: value [

	(attributes ifNil: [ attributes := Dictionary new ])
		at: key
		put: value
]

{ #category : #accessing }
OTSpan >> attributes [

	^ attributes
]

{ #category : #accessing }
OTSpan >> attributes: aDictionary [

	attributes := aDictionary
]

{ #category : #accessing }
OTSpan >> context [

	^ context
]

{ #category : #accessing }
OTSpan >> context: aContext [

	context := aContext
]

{ #category : #control }
OTSpan >> end [

	self endTime: DateAndTime now.
	Current := self parent
]

{ #category : #accessing }
OTSpan >> endTime [

	^ endTime
]

{ #category : #accessing }
OTSpan >> endTime: aDateAndTime [

	endTime := aDateAndTime
]

{ #category : #accessing }
OTSpan >> events [

	^ events
]

{ #category : #accessing }
OTSpan >> events: aDictionary [

	events := aDictionary
]

{ #category : #initialization }
OTSpan >> initialize [

	spanId := UUID new
]

{ #category : #accessing }
OTSpan >> instrumentationName [

	^ instrumentationName
]

{ #category : #accessing }
OTSpan >> instrumentationName: aString [

	instrumentationName := aString
]

{ #category : #accessing }
OTSpan >> kind [

	^ kind
]

{ #category : #accessing }
OTSpan >> kind: aSpanKind [

	kind := aSpanKind
]

{ #category : #accessing }
OTSpan >> name [

	^ name
]

{ #category : #accessing }
OTSpan >> name: aString [

	name := aString
]

{ #category : #accessing }
OTSpan >> parent [

	^ parent
]

{ #category : #accessing }
OTSpan >> parent: aSpan [

	parent := aSpan
]

{ #category : #printing }
OTSpan >> printOn: aStream [

	aStream
		nextPutAll: 'Span[';
		nextPutAll: instrumentationName;
		nextPutAll: ': ';
		nextPutAll: name;
		nextPut: $]
]

{ #category : #recording }
OTSpan >> recordException: anException [

	self status: 'ERROR'.
	self attributeAt: 'error' put: anException description
]

{ #category : #accessing }
OTSpan >> spanId [

	^ spanId
]

{ #category : #control }
OTSpan >> start [

	Current := self.
	self startTime: DateAndTime now
]

{ #category : #accessing }
OTSpan >> startTime [

	^ startTime
]

{ #category : #accessing }
OTSpan >> startTime: aDateAndTime [

	startTime := aDateAndTime
]

{ #category : #accessing }
OTSpan >> status [

	^ status
]

{ #category : #accessing }
OTSpan >> status: aString [

	status := aString
]

{ #category : #'ston persistence' }
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
			at: #status put: status;
			at: #instrumentationName put: instrumentationName.
		parent ifNotNil: [ map at: #parentId put: parent spanId ].
		attributes isEmptyOrNil ifFalse: [
			map at: #attributes put: attributes ].
		events isEmptyOrNil ifFalse: [ map at: #events put: events ] ]
]

{ #category : #accessing }
OTSpan >> traceId [

	^ traceId
]

{ #category : #accessing }
OTSpan >> traceId: id [

	traceId := id
]
