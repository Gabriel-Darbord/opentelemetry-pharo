"
I generate `OTSpan`s when running SUnit tests.
Specifically, the following methods are instrumented:
- `TestCase >> #run:`
- `TestCase >> #debug`
- `TestSuite >> #run:`
- `TestSuite >> #debug`
"
Class {
	#name : #OTSUnitInstrumentation,
	#superclass : #OTInstrumentation,
	#classInstVars : [
		'counter'
	],
	#category : #'OpenTelemetry-Agents-SUnit'
}

{ #category : #matching }
OTSUnitInstrumentation class >> classMatcher [

	^ OTMatcher anyName: #( TestCase TestSuite )
]

{ #category : #configuring }
OTSUnitInstrumentation class >> defineInstrumenter [

	instrumenter := OTInstrumenter forInstrumentationNamed: 'sunit'
]

{ #category : #matching }
OTSUnitInstrumentation class >> methodMatcher [

	^ OTMatcher anyName: #( run: debug )
]

{ #category : #instrumenting }
OTSUnitInstrumentation class >> onMethodEnter: arguments [

	instrumenter startRequest:
		(arguments first receiver class == TestSuite
			 ifTrue: [ arguments first receiver name ]
			 ifFalse: [ arguments first receiver printString ])
]

{ #category : #instrumenting }
OTSUnitInstrumentation class >> onMethodExit: arguments withValue: value [

	instrumenter end
]

{ #category : #matching }
OTSUnitInstrumentation class >> packageMatcher [

	^ OTMatcher name: #'SUnit-Core'
]
