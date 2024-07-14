Class {
	#name : 'OTAbstractInstrumentationTest',
	#superclass : 'TestCase',
	#instVars : [
		'target'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'accessing' }
OTAbstractInstrumentationTest >> instrumentationClass [

	self subclassResponsibility
]

{ #category : 'running' }
OTAbstractInstrumentationTest >> setUp [

	super setUp.
	self instrumentationClass install.
	target := OTTestTarget new
]

{ #category : 'running' }
OTAbstractInstrumentationTest >> tearDown [

	self instrumentationClass uninstall.
	super tearDown
]
