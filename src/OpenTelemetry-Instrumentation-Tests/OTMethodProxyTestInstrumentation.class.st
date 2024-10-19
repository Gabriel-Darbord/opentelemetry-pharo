Class {
	#name : 'OTMethodProxyTestInstrumentation',
	#superclass : 'OTMethodProxyInstrumentation',
	#classInstVars : [
		'capturedReceiver',
		'capturedArguments',
		'capturedValue'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'evaluating' }
OTMethodProxyTestInstrumentation class >> afterExecutionWithReceiver: receiver arguments: arguments returnValue: returnValue [
	"This method is executed AFTER the instrumented method.
	The return value of the instrumented method is the return value of this method."

	capturedValue := returnValue ifNil: [ #nil ].
	^ returnValue
]

{ #category : 'evaluating' }
OTMethodProxyTestInstrumentation class >> beforeExecutionWithReceiver: receiver arguments: arguments [
	"This method is executed BEFORE the instrumented method."

	capturedReceiver := receiver.
	capturedArguments := arguments
]

{ #category : 'accessing' }
OTMethodProxyTestInstrumentation class >> capturedArguments [

	^ capturedArguments
]

{ #category : 'accessing' }
OTMethodProxyTestInstrumentation class >> capturedReceiver [

	^ capturedReceiver
]

{ #category : 'accessing' }
OTMethodProxyTestInstrumentation class >> capturedValue [

	^ capturedValue
]

{ #category : 'matching' }
OTMethodProxyTestInstrumentation class >> classMatcher [

	^ OTMatcher name: #OTTestTarget
]

{ #category : 'configuring' }
OTMethodProxyTestInstrumentation class >> configure: installer [

	self reset
]

{ #category : 'testing' }
OTMethodProxyTestInstrumentation class >> hasRunAfter [

	^ capturedValue isNotNil
]

{ #category : 'testing' }
OTMethodProxyTestInstrumentation class >> hasRunBefore [

	^ capturedReceiver isNotNil
]

{ #category : 'matching' }
OTMethodProxyTestInstrumentation class >> methodMatcher [

	^ OTMatcher any
]

{ #category : 'matching' }
OTMethodProxyTestInstrumentation class >> packageMatcher [

	^ OTMatcher name: #'OpenTelemetry-Instrumentation-Tests'
]

{ #category : 'class initialization' }
OTMethodProxyTestInstrumentation class >> reset [

	super reset.
	capturedReceiver := capturedArguments := capturedValue := nil
]
