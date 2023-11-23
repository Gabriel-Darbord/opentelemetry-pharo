Class {
	#name : #OTTestSimpleInstrumentation,
	#superclass : #OTTestInstrumentation,
	#category : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : #configuring }
OTTestSimpleInstrumentation class >> configure: installer [

	super configure: installer.
	installer
		beOneShot;
		withContext;
		withObject;
		withSender
]
