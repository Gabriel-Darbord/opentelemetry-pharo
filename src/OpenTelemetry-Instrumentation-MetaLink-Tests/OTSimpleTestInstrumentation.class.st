Class {
	#name : 'OTSimpleTestInstrumentation',
	#superclass : 'OTMetaLinkTestInstrumentation',
	#category : 'OpenTelemetry-Instrumentation-MetaLink-Tests',
	#package : 'OpenTelemetry-Instrumentation-MetaLink-Tests'
}

{ #category : 'configuring' }
OTSimpleTestInstrumentation class >> configure: installer [

	super configure: installer.
	installer
		beOneShot;
		withContext;
		withObject;
		withSender
]
