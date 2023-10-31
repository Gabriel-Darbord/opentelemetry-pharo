Class {
	#name : 'OTTestSimpleInstrumentation',
	#superclass : 'OTTestInstrumentation',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'configuring' }
OTTestSimpleInstrumentation class >> configure: configuration [

	super configure: configuration.
	configuration
		beOneShot;
		withContext;
		withObject;
		withSender
]
