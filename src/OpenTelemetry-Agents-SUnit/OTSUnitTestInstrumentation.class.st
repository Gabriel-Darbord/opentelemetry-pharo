"
I generate `OTSpan`s when running SUnit tests.
Specifically, the following methods are instrumented:
- `TestCase >> #run:`
- `TestCase >> #debug`
- `TestSuite >> #run:`
- `TestSuite >> #debug`
"
Class {
	#name : #OTSUnitTestInstrumentation,
	#superclass : #OTInstrumentation,
	#classInstVars : [
		'counter'
	],
	#category : #'OpenTelemetry-Agents-SUnit'
}

{ #category : #matching }
OTSUnitTestInstrumentation class >> classMatcher [

	^ OTMatcher anyName: #( TestCase TestSuite )
]

{ #category : #configuring }
OTSUnitTestInstrumentation class >> configureMethodEnter: configuration [

	configuration withReceiver.
	counter := 0
]

{ #category : #configuring }
OTSUnitTestInstrumentation class >> defineInstrumenter [

	instrumenter := OTInstrumenter forInstrumentationNamed: 'sunit'
]

{ #category : #testing }
OTSUnitTestInstrumentation class >> hasMethodEnter [

	^ true
]

{ #category : #testing }
OTSUnitTestInstrumentation class >> hasMethodExit [

	^ true
]

{ #category : #matching }
OTSUnitTestInstrumentation class >> methodMatcher [

	^ OTMatcher anyName: #( run: debug )
]

{ #category : #instrumenting }
OTSUnitTestInstrumentation class >> onMethodEnter: arguments [

	counter := counter + 1.
	counter even ifTrue: [ ^ self ].
	instrumenter
		startUnder: OTSpan current
		request: (arguments first class == TestSuite
				 ifTrue: [ arguments first name ]
				 ifFalse: [ arguments first ])
]

{ #category : #instrumenting }
OTSUnitTestInstrumentation class >> onMethodExit: arguments [

	instrumenter
		end: OTSpan current
		request: nil
		response: nil
		error: nil
]

{ #category : #matching }
OTSUnitTestInstrumentation class >> packageMatcher [

	^ OTMatcher name: #'SUnit-Core'
]
