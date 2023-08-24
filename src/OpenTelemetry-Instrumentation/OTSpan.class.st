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
		'data'
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

{ #category : #'instance creation' }
OTSpan class >> rootIn: aContext [

	^ self new
		  context: aContext;
		  traceId: UUIDGenerator next
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

	data at: 'attributes' at: key put: value
]

{ #category : #accessing }
OTSpan >> attributes [

	^ data at: 'attributes' ifAbsent: nil
]

{ #category : #accessing }
OTSpan >> attributes: aDictionary [

	data at: 'attributes' put: aDictionary
]

{ #category : #accessing }
OTSpan >> context [

	^ data at: 'context' ifAbsent: nil
]

{ #category : #accessing }
OTSpan >> context: aContext [

	data at: 'context' put: aContext
]

{ #category : #accessing }
OTSpan >> data [
	"The dictionary containing the span data"

	^ data
]

{ #category : #control }
OTSpan >> end [

	self endTime: DateAndTime now.
	Current := self parent
]

{ #category : #accessing }
OTSpan >> endTime [

	^ data at: 'endTime' ifAbsent: nil
]

{ #category : #accessing }
OTSpan >> endTime: aDateAndTime [

	data at: 'endTime' put: aDateAndTime
]

{ #category : #accessing }
OTSpan >> events [

	^ data at: 'events' ifAbsent: nil
]

{ #category : #accessing }
OTSpan >> events: anObject [

	data at: 'events' put: anObject
]

{ #category : #initialization }
OTSpan >> initialize [

	data := Dictionary new.
	data at: 'spanId' put: UUIDGenerator next
]

{ #category : #accessing }
OTSpan >> instrumentationName [

	^ data at: 'instrumentationName' ifAbsent: nil
]

{ #category : #accessing }
OTSpan >> instrumentationName: aString [

	data at: 'instrumentationName' put: aString
]

{ #category : #accessing }
OTSpan >> kind [

	^ data at: 'kind' ifAbsent: nil
]

{ #category : #accessing }
OTSpan >> kind: aSpanKind [

	data at: 'kind' put: aSpanKind
]

{ #category : #accessing }
OTSpan >> name [

	^ data at: 'name' ifAbsent: nil
]

{ #category : #accessing }
OTSpan >> name: aString [

	data at: 'name' put: aString
]

{ #category : #accessing }
OTSpan >> parent [

	^ data at: 'parent' ifAbsent: nil
]

{ #category : #accessing }
OTSpan >> parent: anObject [

	data at: 'parent' put: anObject
]

{ #category : #recording }
OTSpan >> recordException: anException [

	self status: 'ERROR'.
	self attributeAt: 'error' put: anException description
]

{ #category : #accessing }
OTSpan >> spanId [

	^ data at: 'spanId'
]

{ #category : #control }
OTSpan >> start [

	Current := self.
	self startTime: DateAndTime now
]

{ #category : #accessing }
OTSpan >> startTime [

	^ data at: 'startTime'
]

{ #category : #accessing }
OTSpan >> startTime: aDateAndTime [

	data at: 'startTime' put: aDateAndTime
]

{ #category : #accessing }
OTSpan >> status [

	^ data at: 'status' ifAbsent: nil
]

{ #category : #accessing }
OTSpan >> status: aString [

	data at: 'status' put: aString
]

{ #category : #accessing }
OTSpan >> traceId [

	^ data at: 'traceId' ifAbsent: nil
]

{ #category : #accessing }
OTSpan >> traceId: id [

	data at: 'traceId' put: id
]
