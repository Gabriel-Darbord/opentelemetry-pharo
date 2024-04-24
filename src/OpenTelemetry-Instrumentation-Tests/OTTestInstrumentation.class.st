Class {
	#name : 'OTTestInstrumentation',
	#superclass : 'OTInstrumentation',
	#classInstVars : [
		'capturedValue',
		'capturedEvent'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'accessing' }
OTTestInstrumentation class >> capturedEvent [

	^ capturedEvent
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

	^ capturedEvent isNotNil
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
OTTestInstrumentation class >> onMethodEnter: event [

	capturedEvent := event
]

{ #category : 'instrumenting' }
OTTestInstrumentation class >> onMethodExit: event withValue: returnValue [

	capturedValue := returnValue ifNil: [ #nil ]
]

{ #category : 'matching' }
OTTestInstrumentation class >> packageMatcher [

	^ OTMatcher name: #'OpenTelemetry-Instrumentation-Tests'
]

{ #category : 'class initialization' }
OTTestInstrumentation class >> reset [

	super reset.
	capturedEvent := capturedValue := nil
]
