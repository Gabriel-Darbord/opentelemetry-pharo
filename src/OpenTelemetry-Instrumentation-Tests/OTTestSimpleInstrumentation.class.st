Class {
	#name : #OTTestSimpleInstrumentation,
	#superclass : #OTMetaLinkTestInstrumentation,
	#category : #'OpenTelemetry-Instrumentation-Tests'
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
