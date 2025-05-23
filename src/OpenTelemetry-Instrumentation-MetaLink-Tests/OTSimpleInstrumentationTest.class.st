"
An OTInstrumentationConfigurationTest is a test class for testing the behavior of OTInstrumentationConfiguration
"
Class {
	#name : 'OTSimpleInstrumentationTest',
	#superclass : 'OTAbstractInstrumentationTest',
	#category : 'OpenTelemetry-Instrumentation-MetaLink-Tests',
	#package : 'OpenTelemetry-Instrumentation-MetaLink-Tests'
}

{ #category : 'accessing' }
OTSimpleInstrumentationTest >> instrumentation [

	^ OTTestSimpleInstrumentation
]

{ #category : 'tests' }
OTSimpleInstrumentationTest >> testEnsureHasRunOnExit [

	self deny: self instrumentation hasRunOnExit.
	self should: [ target fail ] raise: Error.
	self assert: self instrumentation hasRunOnExit
]

{ #category : 'tests' }
OTSimpleInstrumentationTest >> testEventHasConfiguredData [

	| event |
	target answer. "run instrumented method"
	event := self instrumentation capturedEvent.
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
	event := self instrumentation capturedEvent.
	self assert: event isNotEmpty.
	self assert: event first class identicalTo: RFMethodOperation
]

{ #category : 'tests' }
OTSimpleInstrumentationTest >> testHasRun [

	self deny: self instrumentation hasRunOnEnter.
	self deny: self instrumentation hasRunOnExit.
	target answer.
	self assert: self instrumentation hasRunOnEnter.
	self assert: self instrumentation hasRunOnExit
]

{ #category : 'tests' }
OTSimpleInstrumentationTest >> testIgnoreHandledException [
	"The instrumentation is not influenced by an exception that is handled."

	target handledFail.
	self assert: self instrumentation hasRunOnExit
]

{ #category : 'tests' }
OTSimpleInstrumentationTest >> testIsInstalled [

	self assert:
		((OTTestTarget >> #answer) ast links anySatisfy: [ :link |
			 link metaObject == self instrumentation ])
]

{ #category : 'tests' }
OTSimpleInstrumentationTest >> testIsOneShot [

	target answer.
	self assert:
		((OTTestTarget >> #answer) ast links noneSatisfy: [ :link |
			 link metaObject == self instrumentation ])
]

{ #category : 'tests' }
OTSimpleInstrumentationTest >> testPassException [
	"The instrumentation should let the exception happen normally."

	self should: [ target fail ] raise: Error
]

{ #category : 'tests' }
OTSimpleInstrumentationTest >> testSmoke [
	"Instrumentation is successfully installed and uninstalled."
]
