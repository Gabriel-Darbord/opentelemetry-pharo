"
An instrumenter of the start and end of a request/response lifecycle.
Almost all instrumentation of libraries falls into modeling start and end, generating observability signals from these such as a tracing `OTSpan`, or metrics such as the duration taken, active requests, etc.
If you want to produce spans, you should create and configure an instance in `OTInstrumentation class>>#defineInstrumenter`.

When instrumenting a library, there will generally be four steps:

- Instantiate an `OTInstrumenter` and configure any library-specific customizations, and also expose useful knobs to your user.
- Call `OTInstrumenter>>#shouldStartUnder:request:` and do not proceed if `false`.
- Call `OTInstrumenter>>#startUnder:request:` at the beginning of a request.
- Call `OTInstrumenter>>#end:request:response:error:` at the end of a request.

The `end` method is called when the instrumented operation finished. It is of extreme importance for this method to be always called after `start`. Calling `start` without later `end` will result in inaccurate or wrong telemetry and context leaks.
"
Class {
	#name : #OTInstrumenter,
	#superclass : #Object,
	#instVars : [
		'spanSuppressionStrategy',
		'spanKindExtractor',
		'spanNameExtractor',
		'contextProducer',
		'instrumentationName'
	],
	#classInstVars : [
		'default'
	],
	#category : #'OpenTelemetry-Instrumentation'
}

{ #category : #accessing }
OTInstrumenter class >> default [
	"A shared instrumenter with default configurations."

	^ default ifNil: [ default := self new ]
]

{ #category : #defaults }
OTInstrumenter class >> defaultContextProducer [

	^ [ OTContext new ]
]

{ #category : #defaults }
OTInstrumenter class >> defaultSpanKindExtractor [

	^ OTSpan alwaysInternal
]

{ #category : #defaults }
OTInstrumenter class >> defaultSpanNameExtractor [

	^ [ :request | request printStringLimitedTo: 50 ]
]

{ #category : #'instance creation' }
OTInstrumenter class >> forInstrumentationNamed: aString [

	^ self new instrumentationName: aString
]

{ #category : #accessing }
OTInstrumenter >> contextProducer [

	^ contextProducer ifNil: [
		  contextProducer := self class defaultContextProducer ]
]

{ #category : #accessing }
OTInstrumenter >> contextProducer: anObject [

	contextProducer := anObject
]

{ #category : #instrumenting }
OTInstrumenter >> end: span request: request response: response error: error [
	"Mark the end of a span execution."

	error ifNotNil: [ span recordException: error ].
	span end.
	OTSpanProcessor instance process: span
]

{ #category : #accessing }
OTInstrumenter >> instrumentationName [

	^ instrumentationName
]

{ #category : #accessing }
OTInstrumenter >> instrumentationName: aString [

	instrumentationName := aString
]

{ #category : #instrumenting }
OTInstrumenter >> produceContext [

	^ self contextProducer value
]

{ #category : #instrumenting }
OTInstrumenter >> shouldStartUnder: span request: request [

	^ spanSuppressionStrategy ifNil: [ true ] ifNotNil: [
		  spanSuppressionStrategy
			  value: span
			  value: (spanKindExtractor value: request) ]
]

{ #category : #accessing }
OTInstrumenter >> spanKindExtractor [

	^ spanKindExtractor ifNil: [
		  spanKindExtractor := self class defaultSpanKindExtractor ]
]

{ #category : #accessing }
OTInstrumenter >> spanKindExtractor: aBlock [

	spanKindExtractor := aBlock
]

{ #category : #accessing }
OTInstrumenter >> spanNameExtractor [

	^ spanNameExtractor ifNil: [
		  spanNameExtractor := self class defaultSpanNameExtractor ]
]

{ #category : #accessing }
OTInstrumenter >> spanNameExtractor: aBlock [

	spanNameExtractor := aBlock
]

{ #category : #accessing }
OTInstrumenter >> spanSuppressionStrategy [

	^ spanSuppressionStrategy
]

{ #category : #accessing }
OTInstrumenter >> spanSuppressionStrategy: aBlock [

	spanSuppressionStrategy := aBlock
]

{ #category : #instrumenting }
OTInstrumenter >> startUnder: parentSpan request: request [
	"Starts a new operation to be instrumented.
	The parentSpan is the parent of the resulting instrumented operation."

	^ (parentSpan
		   ifNil: [ OTSpan rootIn: self produceContext ]
		   ifNotNil: [ OTSpan under: parentSpan ])
		  name: (self spanNameExtractor value: request);
		  kind: (self spanKindExtractor value: request);
		  instrumentationName: instrumentationName;
		  start
]
