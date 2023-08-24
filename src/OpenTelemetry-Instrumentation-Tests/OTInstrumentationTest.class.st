"
An OTInstrumentationConfigurationTest is a test class for testing the behavior of OTInstrumentationConfiguration
"
Class {
	#name : #OTInstrumentationTest,
	#superclass : #TestCase,
	#category : #'OpenTelemetry-Instrumentation-Tests'
}

{ #category : #running }
OTInstrumentationTest >> setUp [

	super setUp.
	OTTestInstrumentation install
]

{ #category : #running }
OTInstrumentationTest >> tearDown [

	OTTestInstrumentation uninstall.
	super tearDown
]

{ #category : #tests }
OTInstrumentationTest >> testInstrumentWithOnEnter [
	"trigger the instrumentation"

	self deny: OTTestInstrumentation hasRun.
	OTTestTarget new answer.
	self assert: OTTestInstrumentation hasRun
]
