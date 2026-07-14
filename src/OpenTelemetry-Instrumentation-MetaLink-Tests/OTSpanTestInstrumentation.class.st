Class {
	#name : 'OTSpanTestInstrumentation',
	#superclass : 'OTMetaLinkTestInstrumentation',
	#classInstVars : [
		'capturedSpan',
		'suppressed'
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
	instrumenter spanSuppressionStrategy: [ :span :kind |
		span isNotNil and: [ span name includesSubstring: 'suppressed' ] ]
]

{ #category : 'evaluating' }
OTSpanTestInstrumentation class >> onMethodEnter: event [

	| request |
	request := event first method.
	(suppressed := (instrumenter
		                shouldStartUnder: OTSpan current
		                request: request) not) ifTrue: [
		^ capturedSpan attributeAt: 'suppressed' put: true ].
	capturedSpan := instrumenter startRequest: request.
	capturedSpan attributeAt: 'enter' put: #OK
]

{ #category : 'evaluating' }
OTSpanTestInstrumentation class >> onMethodExit: event withValue: returnValue [

	suppressed ifTrue: [ "suppress only once" ^ suppressed := false ].
	capturedSpan attributeAt: 'exit' put: #OK.
	capturedSpan status = OTSpan unset ifTrue: [ capturedSpan setOkStatus ].
	instrumenter end: capturedSpan
]

{ #category : 'class initialization' }
OTSpanTestInstrumentation class >> reset [

	super reset.
	capturedSpan := nil.
	suppressed := false
]
