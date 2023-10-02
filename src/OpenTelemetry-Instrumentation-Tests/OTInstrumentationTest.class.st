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

{ #category : #tests }
OTInstrumentationTest >> testHasRun [
	"Simple test to see if the instrumentation runs."

	self deny: OTTestInstrumentation hasRun.
	OTTestTarget new answer.
	self assert: OTTestInstrumentation hasRun
]
