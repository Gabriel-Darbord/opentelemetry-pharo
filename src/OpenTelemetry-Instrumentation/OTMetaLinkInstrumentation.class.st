Class {
	#name : #OTMetaLinkInstrumentation,
	#superclass : #OTInstrumentation,
	#category : #'OpenTelemetry-Instrumentation'
}

{ #category : #configuring }
OTMetaLinkInstrumentation class >> installer [

	^ OTMetaLinkInstaller
]

{ #category : #testing }
OTMetaLinkInstrumentation class >> isAbstract [

	^ self == OTMetaLinkInstrumentation
]

{ #category : #instrumenting }
OTMetaLinkInstrumentation class >> onMethodEnter: event [
	"This method is executed BEFORE the instrumented method.
	The event contains the RFMethodOperation plus the data requested in #configure:."
]

{ #category : #instrumenting }
OTMetaLinkInstrumentation class >> onMethodExit: event withValue: returnValue [
	"This method is executed AFTER the instrumented method.
	The first argument contains the RFMethodOperation plus the data requested in #configure:.
	The second contains the return value of the method."
]

{ #category : #private }
OTMetaLinkInstrumentation class >> run: arguments [
	"Hook called when executing an instrumented method.
	If the trace should not be sampled, execute the method directly.
	Otherwise, run on enter, execute method, record unhandled exception if any, and ensure running on exit."

	| returnValue exception |
	sampler ifNotNil: [
		sampler shouldSample ifFalse: [ ^ arguments first value ] ].
	self onMethodEnter: arguments.
	^ [
	  [
	  [ returnValue := arguments first value ]
		  on: Exception
		  do: [ :e | (exception := e) pass ] ] ifCurtailed: [
		  OTSpan recordException: exception ] ] ensure: [
		  self onMethodExit: arguments withValue: returnValue ]
]
