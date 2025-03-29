Class {
	#name : 'OTMetaLinkInstaller',
	#superclass : 'OTAgentInstaller',
	#instVars : [
		'metalink',
		'arguments'
	],
	#category : 'OpenTelemetry-Instrumentation-MetaLink',
	#package : 'OpenTelemetry-Instrumentation-MetaLink'
}

{ #category : 'actions' }
OTMetaLinkInstaller class >> uninstallInstrumentation: anInstrumentation [

	anInstrumentation reset.
	MetaLink allInstancesDo: [ :metalink |
		metalink metaObject == anInstrumentation ifTrue: [
			metalink uninstall ] ]
]

{ #category : 'API - configuration' }
OTMetaLinkInstaller >> beOneShot [
	"Only execute the instrumentation once."

	metalink optionOneShot: true
]

{ #category : 'private' }
OTMetaLinkInstaller >> configureWith: anInstrumentation [
	"This is a private method, do not use this!
	Configure the MetaLink to make it run the method instrumentation defined in an OTInstrumentation subclass."

	super configureWith: anInstrumentation.
	metalink control: #instead.
	metalink selector: #run:.
	metalink arguments: arguments keys.
	metalink metaObject: anInstrumentation
]

{ #category : 'initialization' }
OTMetaLinkInstaller >> initialize [

	metalink := MetaLink new.
	"number of args depends on the configuration, so dump all in array as single arg"
	metalink optionArgsAsArray: true.
	metalink optionCompileOnLinkInstallation: true.
	"the configurable arguments that will be given to the instrumentation"
	arguments := OrderedDictionary new.
	"always with RFMethodOperation containing method, arguments and receiver."
	arguments add: #operation -> nil
]

{ #category : 'private' }
OTMetaLinkInstaller >> instrument: aMethod [
	"This is a private method, do not use this!
	Install the metalink on the instrumented method."

	aMethod ast link: metalink
]

{ #category : 'private' }
OTMetaLinkInstaller >> shouldInstrument: aMethod with: anInstrumentation [

	^ aMethod ast links noneSatisfy: [ :link |
		  link metaObject == anInstrumentation ]
]

{ #category : 'API - configuration' }
OTMetaLinkInstaller >> withContext [
	"The executing context, note that it is slow to reify."

	arguments add: #context -> nil
]

{ #category : 'API - configuration' }
OTMetaLinkInstaller >> withObject [
	"Object executing the instrumented method."

	arguments add: #object -> nil
]

{ #category : 'API - configuration' }
OTMetaLinkInstaller >> withSender [
	"Sender of the instrumented method."

	arguments add: #sender -> nil
]
