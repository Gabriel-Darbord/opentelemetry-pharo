Class {
	#name : #OTMethodProxyInstaller,
	#superclass : #OTAgentInstaller,
	#instVars : [
		'proxy'
	],
	#category : #'OpenTelemetry-Instrumentation'
}

{ #category : #actions }
OTMethodProxyInstaller class >> uninstallInstrumentation: anInstrumentation [

	anInstrumentation reset.
	MpMethodProxy allSubInstancesDo: [ :proxy |
		proxy handler == anInstrumentation ifTrue: [ proxy uninstall ] ]
]

{ #category : #private }
OTMethodProxyInstaller >> instrument: aMethod [
	"This is a private method, do not use this!
	Install the metalink on the instrumented method."

	proxy install
]

{ #category : #asserting }
OTMethodProxyInstaller >> shouldInstrument: aMethod with: anInstrumentation [

	proxy := MpMethodProxy onMethod: aMethod handler: anInstrumentation.
	^ proxy shouldWrap: aMethod
]
