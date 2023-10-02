Class {
	#name : #OTTestInstrumentation,
	#superclass : #OTInstrumentation,
	#classInstVars : [
		'hasRun'
	],
	#category : #'OpenTelemetry-Instrumentation-Tests'
}

{ #category : #matching }
OTTestInstrumentation class >> classMatcher [

	^ OTMatcher name: #OTTestTarget
]

{ #category : #configuring }
OTTestInstrumentation class >> configure: configuration [

	configuration beOneShot.
	hasRun := false
]

{ #category : #accessing }
OTTestInstrumentation class >> hasRun [

	^ hasRun
]

{ #category : #matching }
OTTestInstrumentation class >> methodMatcher [

	^ OTMatcher any
]

{ #category : #instrumenting }
OTTestInstrumentation class >> onMethodEnter: arguments [

	hasRun := true
]

{ #category : #matching }
OTTestInstrumentation class >> packageMatcher [

	^ OTMatcher name: #'OpenTelemetry-Instrumentation-Tests'
]
