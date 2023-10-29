"
An OTInstrumentationConfigurationTest is a test class for testing the behavior of OTInstrumentationConfiguration
"
Class {
	#name : #OTInstrumentationTest,
	#superclass : #TestCase,
	#instVars : [
		'target'
	],
	#category : #'OpenTelemetry-Instrumentation-Tests'
}

{ #category : #running }
OTInstrumentationTest >> setUp [

	super setUp.
	OTTestSimpleInstrumentation install.
	target := OTTestTarget new
]

{ #category : #running }
OTInstrumentationTest >> tearDown [

	OTTestSimpleInstrumentation reset.
	super tearDown
]

{ #category : #tests }
OTInstrumentationTest >> testEnsureHasRunOnExit [

	self deny: OTTestSimpleInstrumentation hasRunOnExit.
	[
	target fail.
	self fail "should not reach" ]
		on: Error
		do: [ nil ].
	self assert: OTTestSimpleInstrumentation hasRunOnExit
]

{ #category : #tests }
OTInstrumentationTest >> testHasConfiguredArguments [

	| arguments |
	target answer. "run instrumented method"
	arguments := OTTestSimpleInstrumentation capturedArguments.
	self assert: arguments size equals: 4.
	self assert: arguments second isContext.
	self assert: arguments third class equals: OTTestTarget.
	self assert: arguments fourth class equals: ReflectiveMethod
]

{ #category : #tests }
OTInstrumentationTest >> testHasRunOnEnter [

	self deny: OTTestSimpleInstrumentation hasRunOnEnter.
	target answer.
	self assert: OTTestSimpleInstrumentation hasRunOnEnter
]

{ #category : #tests }
OTInstrumentationTest >> testHasRunOnExit [

	self deny: OTTestSimpleInstrumentation hasRunOnExit.
	target answer.
	self assert: OTTestSimpleInstrumentation hasRunOnExit
]

{ #category : #tests }
OTInstrumentationTest >> testIsInstalled [

	self
		shouldnt: ((OTTestTarget >> #answer) ast links detect: [ :link |
				 link metaObject == OTTestSimpleInstrumentation ])
		raise: NotFound
]
