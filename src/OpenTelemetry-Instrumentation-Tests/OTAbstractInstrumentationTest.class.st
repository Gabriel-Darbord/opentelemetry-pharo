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
OTAbstractInstrumentationTest >> instrumentation [

	self subclassResponsibility
]

{ #category : 'running' }
OTAbstractInstrumentationTest >> setUp [

	super setUp.
	self instrumentation install.
	target := OTTestTarget new
]

{ #category : 'running' }
OTAbstractInstrumentationTest >> tearDown [

	self instrumentation uninstall.
	super tearDown
]
