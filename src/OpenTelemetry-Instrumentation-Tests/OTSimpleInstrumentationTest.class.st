"
An OTInstrumentationConfigurationTest is a test class for testing the behavior of OTInstrumentationConfiguration
"
Class {
	#name : 'OTSimpleInstrumentationTest',
	#superclass : 'OTAbstractInstrumentationTest',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'accessing' }
OTSimpleInstrumentationTest >> instrumentationClass [

	^ OTTestSimpleInstrumentation
]

{ #category : 'tests' }
OTSimpleInstrumentationTest >> testEnsureHasRunOnExit [

	self deny: OTTestSimpleInstrumentation hasRunOnExit.
	self
		should: [
			target fail.
			self fail "should not reach" ]
		raise: Error.
	self assert: OTTestSimpleInstrumentation hasRunOnExit
]

{ #category : 'tests' }
OTSimpleInstrumentationTest >> testEventHasConfiguredData [

	| event |
	target answer. "run instrumented method"
	event := OTTestSimpleInstrumentation capturedEvent.
	self assert: event size equals: 4.
	"withContext"
	self assert: event second isContext.
	"withObject"
	self assert: event third class equals: OTTestTarget.
	"withSender"
	self assert: event fourth class equals: self class
]

{ #category : 'tests' }
OTSimpleInstrumentationTest >> testEventHasOperation [

	| event |
	target answer. "run instrumented method"
	event := OTTestSimpleInstrumentation capturedEvent.
	self assert: event isNotEmpty.
	self assert: event first class identicalTo: RFMethodOperation
]

{ #category : 'tests' }
OTSimpleInstrumentationTest >> testHasRun [

	self deny: OTTestSimpleInstrumentation hasRunOnEnter.
	self deny: OTTestSimpleInstrumentation hasRunOnExit.
	target answer.
	self assert: OTTestSimpleInstrumentation hasRunOnEnter.
	self assert: OTTestSimpleInstrumentation hasRunOnExit
]

{ #category : 'tests' }
OTSimpleInstrumentationTest >> testIsInstalled [

	self assert:
		((OTTestTarget >> #answer) ast links anySatisfy: [ :link |
			 link metaObject == OTTestSimpleInstrumentation ])
]

{ #category : 'tests' }
OTSimpleInstrumentationTest >> testIsOneShot [

	target answer.
	self assert:
		((OTTestTarget >> #answer) ast links noneSatisfy: [ :link |
			 link metaObject == OTTestSimpleInstrumentation ])
]

{ #category : 'tests' }
OTSimpleInstrumentationTest >> testPassException [
	"The instrumentation should let the exception happen normally."

	self should: [ target fail ] raise: Error
]
