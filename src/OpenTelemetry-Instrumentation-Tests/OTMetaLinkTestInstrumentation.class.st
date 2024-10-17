Class {
	#name : #OTMetaLinkTestInstrumentation,
	#superclass : #OTMetaLinkInstrumentation,
	#classInstVars : [
		'capturedValue',
		'capturedEvent'
	],
	#category : #'OpenTelemetry-Instrumentation-Tests'
}

{ #category : #accessing }
OTMetaLinkTestInstrumentation class >> capturedEvent [

	^ capturedEvent
]

{ #category : #accessing }
OTMetaLinkTestInstrumentation class >> capturedValue [

	^ capturedValue
]

{ #category : #matching }
OTMetaLinkTestInstrumentation class >> classMatcher [

	^ OTMatcher name: #OTTestTarget
]

{ #category : #configuring }
OTMetaLinkTestInstrumentation class >> configure: installer [

	self reset
]

{ #category : #testing }
OTMetaLinkTestInstrumentation class >> hasRunOnEnter [

	^ capturedEvent isNotNil
]

{ #category : #testing }
OTMetaLinkTestInstrumentation class >> hasRunOnExit [

	^ capturedValue isNotNil
]

{ #category : #testing }
OTMetaLinkTestInstrumentation class >> isAbstract [

	^ self == OTMetaLinkTestInstrumentation
]

{ #category : #matching }
OTMetaLinkTestInstrumentation class >> methodMatcher [

	^ OTMatcher any
]

{ #category : #instrumenting }
OTMetaLinkTestInstrumentation class >> onMethodEnter: event [

	capturedEvent := event
]

{ #category : #instrumenting }
OTMetaLinkTestInstrumentation class >> onMethodExit: event withValue: returnValue [

	capturedValue := returnValue ifNil: [ #nil ]
]

{ #category : #matching }
OTMetaLinkTestInstrumentation class >> packageMatcher [

	^ OTMatcher name: #'OpenTelemetry-Instrumentation-Tests'
]

{ #category : #'class initialization' }
OTMetaLinkTestInstrumentation class >> reset [

	super reset.
	capturedEvent := capturedValue := nil
]
