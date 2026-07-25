Class {
	#name : 'OTSpanTestInstrumentation',
	#superclass : 'OTMetaLinkTestInstrumentation',
	#classInstVars : [
		'capturedSpan',
		'suppressed',
		'currentContextToken'
	],
	#category : 'OpenTelemetry-Instrumentation-MetaLink-Tests',
	#package : 'OpenTelemetry-Instrumentation-MetaLink-Tests'
}

{ #category : 'instrumenting' }
OTSpanTestInstrumentation class >> capturedSpan [

	^ capturedSpan
]

{ #category : 'configuring' }
OTSpanTestInstrumentation class >> defineInstrumenter [

	instrumenter := OTInstrumenter forInstrumentationNamed: 'test'.
	instrumenter spanSuppressionStrategy: [ :span :kind | span isNotNil and: [ span isRecording ] ]
]

{ #category : 'private' }
OTSpanTestInstrumentation class >> finishCapturedSpanMarkingSuccess: aBoolean [

	capturedSpan attributeAt: 'exit' put: #OK.
	(aBoolean and: [ capturedSpan status = OTSpan unset ]) ifTrue: [ capturedSpan setStatus: OTSpan ok ].
	instrumenter end: capturedSpan
]

{ #category : 'evaluating' }
OTSpanTestInstrumentation class >> onMethodEnter: event [

	| request |
	request := event first method.
	(suppressed := (instrumenter shouldStartUnder: OTSpan current request: request) not) ifTrue: [
			capturedSpan := OTSpan current.
			^ capturedSpan attributeAt: 'suppressed' put: true ].
	capturedSpan := instrumenter startRequest: request.
	currentContextToken := OpenTelemetry attachContext: (OpenTelemetry currentContext withSpan: capturedSpan).
	capturedSpan attributeAt: 'enter' put: #OK
]

{ #category : 'evaluating' }
OTSpanTestInstrumentation class >> onMethodException: event error: anException [

	suppressed ifTrue: [ ^ self ].
	capturedSpan setStatus: OTSpan error description: anException description.
	capturedSpan recordException: anException
]

{ #category : 'evaluating' }
OTSpanTestInstrumentation class >> onMethodExit: event withValue: returnValue [

	suppressed ifTrue: [ "suppress only once" ^ suppressed := false ].
	OpenTelemetry detachContext: currentContextToken.
	currentContextToken := nil.
	self finishCapturedSpanMarkingSuccess: true
]

{ #category : 'class initialization' }
OTSpanTestInstrumentation class >> reset [

	super reset.
	capturedSpan := nil.
	suppressed := false.
	currentContextToken := nil
]
