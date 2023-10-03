Class {
	#name : #OTTestSimpleInstrumentation,
	#superclass : #OTInstrumentation,
	#classInstVars : [
		'capturedArguments',
		'capturedValue'
	],
	#category : #'OpenTelemetry-Instrumentation-Tests'
}

{ #category : #accessing }
OTTestSimpleInstrumentation class >> capturedArguments [

	^ capturedArguments
]

{ #category : #accessing }
OTTestSimpleInstrumentation class >> capturedValue [

	^ capturedValue
]

{ #category : #matching }
OTTestSimpleInstrumentation class >> classMatcher [

	^ OTMatcher name: #OTTestTarget
]

{ #category : #configuring }
OTTestSimpleInstrumentation class >> configure: configuration [

	configuration
		beOneShot;
		withContext;
		withObject;
		withSender.
	capturedArguments := capturedValue := #none
]

{ #category : #testing }
OTTestSimpleInstrumentation class >> hasRunOnEnter [

	^ capturedArguments ~~ #none
]

{ #category : #testing }
OTTestSimpleInstrumentation class >> hasRunOnExit [

	^ capturedValue ~~ #none
]

{ #category : #matching }
OTTestSimpleInstrumentation class >> methodMatcher [

	^ OTMatcher any
]

{ #category : #instrumenting }
OTTestSimpleInstrumentation class >> onMethodEnter: arguments [

	capturedArguments := arguments
]

{ #category : #instrumenting }
OTTestSimpleInstrumentation class >> onMethodExit: arguments withValue: returnValue [

	capturedValue := returnValue
]

{ #category : #matching }
OTTestSimpleInstrumentation class >> packageMatcher [

	^ OTMatcher name: #'OpenTelemetry-Instrumentation-Tests'
]

{ #category : #'class initialization' }
OTTestSimpleInstrumentation class >> reset [

	capturedArguments := nil.
	capturedValue := nil
]
