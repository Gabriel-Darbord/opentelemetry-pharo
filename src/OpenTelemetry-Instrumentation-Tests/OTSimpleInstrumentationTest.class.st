"
An OTInstrumentationConfigurationTest is a test class for testing the behavior of OTInstrumentationConfiguration
"
Class {
	#name : #OTSimpleInstrumentationTest,
	#superclass : #TestCase,
	#instVars : [
		'target'
	],
	#category : #'OpenTelemetry-Instrumentation-Tests'
}

{ #category : #running }
OTSimpleInstrumentationTest >> setUp [

	super setUp.
	OTTestSimpleInstrumentation install.
	target := OTTestTarget new
]

{ #category : #running }
OTSimpleInstrumentationTest >> tearDown [

	OTTestSimpleInstrumentation uninstall.
	super tearDown
]

{ #category : #tests }
OTSimpleInstrumentationTest >> testEnsureHasRunOnExit [

	self deny: OTTestSimpleInstrumentation hasRunOnExit.
	[
	target fail.
	self fail "should not reach" ]
		on: Error
		do: [ nil ].
	self assert: OTTestSimpleInstrumentation hasRunOnExit
]

{ #category : #tests }
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

{ #category : #tests }
OTSimpleInstrumentationTest >> testHasRun [

	self deny: OTTestSimpleInstrumentation hasRunOnEnter.
	self deny: OTTestSimpleInstrumentation hasRunOnExit.
	target answer.
	self assert: OTTestSimpleInstrumentation hasRunOnEnter.
	self assert: OTTestSimpleInstrumentation hasRunOnExit
]

{ #category : #tests }
OTSimpleInstrumentationTest >> testIsInstalled [

	self assert:
		((OTTestTarget >> #answer) ast links anySatisfy: [ :link |
			 link metaObject == OTTestSimpleInstrumentation ])
]

{ #category : #tests }
OTSimpleInstrumentationTest >> testIsOneShot [

	target answer.
	self assert:
		((OTTestTarget >> #answer) ast links noneSatisfy: [ :link |
			 link metaObject == OTTestSimpleInstrumentation ])
]

{ #category : #tests }
OTSimpleInstrumentationTest >> testRecordException [

	| span error |
	self skip. "don't use Span directly, use a real instrumentation. Otherwise it can conflict with an actual instrumentation."
	span := OTSpan new start.
	[ target fail ]
		on: Error
		do: [ :err | error := err ].
	[
	self assert: span status equals: 'ERROR'.
	self assert: (span attributes at: 'error') identicalTo: error ]
		ensure: [ span end ]
]
