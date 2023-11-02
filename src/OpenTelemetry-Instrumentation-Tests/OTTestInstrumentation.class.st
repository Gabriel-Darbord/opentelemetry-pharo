Class {
	#name : 'OTTestInstrumentation',
	#superclass : 'OTInstrumentation',
	#classInstVars : [
		'capturedArguments',
		'capturedValue'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'accessing' }
OTTestInstrumentation class >> capturedArguments [

	^ capturedArguments
]

{ #category : 'accessing' }
OTTestInstrumentation class >> capturedValue [

	^ capturedValue
]

{ #category : 'matching' }
OTTestInstrumentation class >> classMatcher [

	^ OTMatcher name: #OTTestTarget
]

{ #category : 'configuring' }
OTTestInstrumentation class >> configure: installer [

	self reset
]

{ #category : 'testing' }
OTTestInstrumentation class >> hasRunOnEnter [

	^ capturedArguments isNotNil
]

{ #category : 'testing' }
OTTestInstrumentation class >> hasRunOnExit [

	^ capturedValue isNotNil
]

{ #category : 'testing' }
OTTestInstrumentation class >> isAbstract [

	^ self == OTTestInstrumentation
]

{ #category : 'matching' }
OTTestInstrumentation class >> methodMatcher [

	^ OTMatcher any
]

{ #category : 'instrumenting' }
OTTestInstrumentation class >> onMethodEnter: arguments [

	capturedArguments := arguments
]

{ #category : 'instrumenting' }
OTTestInstrumentation class >> onMethodExit: arguments withValue: returnValue [

	capturedValue := returnValue ifNil: [ #nil ]
]

{ #category : 'matching' }
OTTestInstrumentation class >> packageMatcher [

	^ OTMatcher name: #'OpenTelemetry-Instrumentation-Tests'
]

{ #category : 'class initialization' }
OTTestInstrumentation class >> reset [

	super reset.
	capturedArguments := capturedValue := nil
]
