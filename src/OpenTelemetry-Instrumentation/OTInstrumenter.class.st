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
	#name : 'OTInstrumenter',
	#superclass : 'Object',
	#instVars : [
		'spanSuppressionStrategy',
		'spanKindExtractor',
		'spanNameExtractor',
		'contextProducer',
		'instrumentationName',
		'tracerProvider'
	],
	#classInstVars : [
		'default',
		'defaultContextProducer',
		'defaultSpanNameExtractor'
	],
	#category : 'OpenTelemetry-Instrumentation',
	#package : 'OpenTelemetry-Instrumentation'
}

{ #category : 'instance creation' }
OTInstrumenter class >> default [
	"A shared instrumenter with default configurations."

	^ default ifNil: [ default := self new ]
]

{ #category : 'defaults' }
OTInstrumenter class >> defaultContextProducer [

	^ defaultContextProducer ifNil: [
		  defaultContextProducer := [ OTContext new ] ]
]

{ #category : 'private - logging' }
OTInstrumenter class >> defaultConfigurationWarningSink [

	^ [ :message | | transcript |
		transcript := Smalltalk globals at: #Transcript ifAbsent: [ nil ].
		transcript ifNotNil: [
			transcript
				show: message;
				cr ] ]
]

{ #category : 'defaults' }
OTInstrumenter class >> defaultSpanKindExtractor [

	^ OTSpan alwaysInternal
]

{ #category : 'defaults' }
OTInstrumenter class >> defaultSpanNameExtractor [

	^ defaultSpanNameExtractor ifNil: [
		  defaultSpanNameExtractor := [ :request |
		                              request printStringLimitedTo: 50 ] ]
]

{ #category : 'instance creation' }
OTInstrumenter class >> forInstrumentationNamed: aString [

	^ self new instrumentationName: aString
]

{ #category : 'private - logging' }
OTInstrumenter class >> configurationWarningSink [

	^ self
		propertyAt: #otConfigurationWarningSink
		ifAbsent: [ self defaultConfigurationWarningSink ]
]

{ #category : 'private - logging' }
OTInstrumenter class >> configurationWarningSink: aBlock [

	aBlock
		ifNil: [ self removeProperty: #otConfigurationWarningSink ifAbsent: [  ] ]
		ifNotNil: [ self propertyAt: #otConfigurationWarningSink put: aBlock ].
	^ self configurationWarningSink
]

{ #category : 'private - logging' }
OTInstrumenter class >> noteConfigurationFailedDuring: anOperationName error: anError [

	self configurationWarningSink value:
		'OpenTelemetry instrumenter callback failed during '
			, anOperationName
			, ': '
			, anError messageText
]

{ #category : 'accessing' }
OTInstrumenter >> contextProducer [

	^ contextProducer ifNil: [
		  contextProducer := self class defaultContextProducer ]
]

{ #category : 'accessing' }
OTInstrumenter >> contextProducer: anObject [

	contextProducer := anObject
]

{ #category : 'instrumenting' }
OTInstrumenter >> currentContext [

	| currentContext |
	currentContext := OpenTelemetry currentContext.
	^ currentContext isEmpty
		ifTrue: [ self produceContext ]
		ifFalse: [ currentContext ]
]

{ #category : 'private - error handling' }
OTInstrumenter >> configurationValueDuring: anOperationName default: aDefaultValue do: aBlock [

	^ [ aBlock value ]
		on: Error
		do: [ :error |
			self class noteConfigurationFailedDuring: anOperationName error: error.
			aDefaultValue ]
]

{ #category : 'instrumenting' }
OTInstrumenter >> decisionContextUnder: aSpan [

	| currentContext |
	aSpan ifNotNil: [ ^ aSpan context ].
	currentContext := OpenTelemetry currentContext.
	^ currentContext isEmpty
		ifTrue: [ OTContext new ]
		ifFalse: [ currentContext ]
]

{ #category : 'instrumenting' }
OTInstrumenter >> end [
	"Mark the end of the current span."

	^ self end: OTSpan current error: nil
]

{ #category : 'instrumenting' }
OTInstrumenter >> end: span [
	"Mark the end of a span execution."

	^ self end: span error: nil
]

{ #category : 'instrumenting' }
OTInstrumenter >> end: span error: error [
	"Mark the end of a span execution."

	error ifNotNil: [ span recordException: error ].
	^ span end
]

{ #category : 'instrumenting' }
OTInstrumenter >> end: span request: request response: response error: error [
	"Mark the end of a span execution."

	error ifNotNil: [ span recordException: error ].
	^ span end
]

{ #category : 'accessing' }
OTInstrumenter >> instrumentationName [

	^ instrumentationName
]

{ #category : 'accessing' }
OTInstrumenter >> instrumentationName: aString [

	instrumentationName := aString
]

{ #category : 'accessing' }
OTInstrumenter >> tracerProvider [

	^ tracerProvider ifNil: [ OTTracerProvider current ]
]

{ #category : 'accessing' }
OTInstrumenter >> tracerProvider: anObject [

	tracerProvider := anObject
]

{ #category : 'instrumenting' }
OTInstrumenter >> produceContext [

	^ self
		configurationValueDuring: 'contextProducer'
		default: OTContext new
		do: [ self contextProducer value ifNil: [ OTContext new ] ]
]

{ #category : 'instrumenting' }
OTInstrumenter >> shouldStartUnder: span request: request [

	| context spanKind spanName |
	spanKind := self spanKindForRequest: request.
	(self spanSuppressedUnder: span kind: spanKind) ifTrue: [ ^ false ].
	spanName := self spanNameForRequest: request.
	context := self decisionContextUnder: span.
	^ self tracer
		enabledForSpanNamed: spanName
		kind: spanKind
		in: context
		attributes: #()
		links: #()
]

{ #category : 'accessing' }
OTInstrumenter >> spanKindExtractor [

	^ spanKindExtractor ifNil: [
		  spanKindExtractor := self class defaultSpanKindExtractor ]
]

{ #category : 'accessing' }
OTInstrumenter >> spanKindExtractor: aBlock [

	spanKindExtractor := aBlock
]

{ #category : 'accessing' }
OTInstrumenter >> spanNameExtractor [

	^ spanNameExtractor ifNil: [
		  spanNameExtractor := self class defaultSpanNameExtractor ]
]

{ #category : 'accessing' }
OTInstrumenter >> spanNameExtractor: aBlock [

	spanNameExtractor := aBlock
]

{ #category : 'accessing' }
OTInstrumenter >> spanSuppressionStrategy [

	^ spanSuppressionStrategy
]

{ #category : 'accessing' }
OTInstrumenter >> spanSuppressionStrategy: aBlock [

	spanSuppressionStrategy := aBlock
]

{ #category : 'instrumenting' }
OTInstrumenter >> startIn: aContext request: request [
	"Start a new operation to be instrumented from a context."

	^ self tracer
		startSpanNamed: (self spanNameForRequest: request)
		kind: (self spanKindForRequest: request)
		in: aContext
]

{ #category : 'instrumenting' }
OTInstrumenter >> startRequest: request [
	"Start a new operation to be instrumented."

	^ self startIn: self currentContext request: request
]

{ #category : 'instrumenting' }
OTInstrumenter >> startUnder: parentSpan request: request [
	"Start a new operation to be instrumented.
	The parentSpan is the parent context of the resulting instrumented operation."

	^ self
		startIn: (self startContextUnder: parentSpan)
		request: request
]

{ #category : 'instrumenting' }
OTInstrumenter >> spanKindForRequest: request [

	^ self
		configurationValueDuring: 'spanKindExtractor'
		default: (self class defaultSpanKindExtractor value: request)
		do: [ self spanKindExtractor value: request ]
]

{ #category : 'instrumenting' }
OTInstrumenter >> spanNameForRequest: request [

	^ self
		configurationValueDuring: 'spanNameExtractor'
		default: (self class defaultSpanNameExtractor value: request)
		do: [ self spanNameExtractor value: request ]
]

{ #category : 'instrumenting' }
OTInstrumenter >> spanSuppressedUnder: span kind: aSpanKind [

	spanSuppressionStrategy ifNil: [ ^ false ].
	^ self
		configurationValueDuring: 'spanSuppressionStrategy'
		default: false
		do: [ spanSuppressionStrategy value: span value: aSpanKind ]
]

{ #category : 'instrumenting' }
OTInstrumenter >> startContextUnder: parentSpan [

	^ parentSpan
		ifNil: [ self produceContext ]
		ifNotNil: [ parentSpan context ]
]

{ #category : 'instrumenting' }
OTInstrumenter >> tracer [

	^ self tracerProvider tracerNamed: instrumentationName
]
