Class {
	#name : #OTSpanInstrumentationTest,
	#superclass : #TestCase,
	#instVars : [
		'target'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : #running }
OTSpanInstrumentationTest >> setUp [

	super setUp.
	OTTestSpanInstrumentation install.
	target := OTTestTarget new
]

{ #category : #running }
OTSpanInstrumentationTest >> tearDown [

	OTTestSpanInstrumentation uninstall.
	super tearDown
]

{ #category : #tests }
OTSpanInstrumentationTest >> testFixedRateSampler [

	self deny: OTTestSpanInstrumentation hasRunOnEnter.
	target answer.
	self deny: OTTestSpanInstrumentation hasRunOnEnter.
	target answer.
	self assert: OTTestSpanInstrumentation hasRunOnEnter
]
