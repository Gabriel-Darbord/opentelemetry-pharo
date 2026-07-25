"
I am a test instrumentation that creates spans around instrumented executions.

The MethodProxy span tests use me to assert span naming, kind, status, suppression, and context propagation behavior.
"
Class {
	#name : 'OTMethodProxySpanTestInstrumentation',
	#superclass : 'OTMethodProxyInstrumentation',
	#classInstVars : [
		'capturedSpan',
		'suppressed',
		'currentContextToken'
	],
	#category : 'OpenTelemetry-Instrumentation-MethodProxy-Tests',
	#package : 'OpenTelemetry-Instrumentation-MethodProxy-Tests'
}

{ #category : 'evaluating' }
OTMethodProxySpanTestInstrumentation class >> afterAbortedExecutionWithReceiver: receiver arguments: arguments [

	suppressed ifTrue: [ ^ suppressed := false ].
	OpenTelemetry detachContext: currentContextToken.
	currentContextToken := nil.
	self finishCapturedSpanMarkingSuccess: false.
	^ nil
]

{ #category : 'evaluating' }
OTMethodProxySpanTestInstrumentation class >> afterExecutionWithReceiver: receiver arguments: arguments returnValue: returnValue [

	suppressed ifTrue: [ ^ suppressed := false ].
	OpenTelemetry detachContext: currentContextToken.
	currentContextToken := nil.
	self finishCapturedSpanMarkingSuccess: true.
	^ returnValue
]

{ #category : 'evaluating' }
OTMethodProxySpanTestInstrumentation class >> beforeExecutionWithReceiver: receiver arguments: arguments [

	| request |
	request := thisContext sender method.
	(suppressed := (instrumenter shouldStartUnder: OTSpan current request: request) not) ifTrue: [
			capturedSpan := OTSpan current.
			^ capturedSpan attributeAt: 'suppressed' put: true ].
	capturedSpan := instrumenter startRequest: request.
	currentContextToken := OpenTelemetry attachContext: (OpenTelemetry currentContext withSpan: capturedSpan).
	capturedSpan attributeAt: 'enter' put: #OK
]

{ #category : 'instrumenting' }
OTMethodProxySpanTestInstrumentation class >> capturedSpan [

	^ capturedSpan
]

{ #category : 'matching' }
OTMethodProxySpanTestInstrumentation class >> classMatcher [

	^ OTMatcher name: #OTTestTarget
]

{ #category : 'configuring' }
OTMethodProxySpanTestInstrumentation class >> configure: installer [

	self reset
]

{ #category : 'configuring' }
OTMethodProxySpanTestInstrumentation class >> defineInstrumenter [

	instrumenter := OTInstrumenter forInstrumentationNamed: 'test'.
	instrumenter spanSuppressionStrategy: [ :span :kind | span isNotNil and: [ span isRecording ] ]
]

{ #category : 'private' }
OTMethodProxySpanTestInstrumentation class >> finishCapturedSpanMarkingSuccess: aBoolean [

	capturedSpan attributeAt: 'exit' put: #OK.
	(aBoolean and: [ capturedSpan status = OTSpan unset ]) ifTrue: [ capturedSpan setStatus: OTSpan ok ].
	instrumenter end: capturedSpan
]

{ #category : 'matching' }
OTMethodProxySpanTestInstrumentation class >> methodMatcher [

	^ OTMatcher any
]

{ #category : 'matching' }
OTMethodProxySpanTestInstrumentation class >> packageMatcher [

	^ OTMatcher name: #'OpenTelemetry-Instrumentation-Tests'
]

{ #category : 'class initialization' }
OTMethodProxySpanTestInstrumentation class >> reset [

	super reset.
	capturedSpan := nil.
	suppressed := false.
	currentContextToken := nil
]
