Class {
	#name : 'OTMethodProxyInstaller',
	#superclass : 'OTAgentInstaller',
	#instVars : [
		'proxy'
	],
	#category : 'OpenTelemetry-Instrumentation-MethodProxy',
	#package : 'OpenTelemetry-Instrumentation-MethodProxy'
}

{ #category : 'actions' }
OTMethodProxyInstaller class >> uninstallInstrumentation: anInstrumentation [

	anInstrumentation reset.
	MpMethodProxy allSubInstancesDo: [ :proxy |
		proxy handler == anInstrumentation ifTrue: [ proxy uninstall ] ]
]

{ #category : 'private' }
OTMethodProxyInstaller >> instrument: aMethod [
	"This is a private method, do not use this!
	Install the method proxy on the instrumented method."

	proxy install
]

{ #category : 'private' }
OTMethodProxyInstaller >> shouldInstrument: aMethod with: anInstrumentation [
	"A bit weird but this is when the proxy is created"

	proxy := MpMethodProxy onMethod: aMethod handler: anInstrumentation.
	^ true "proxy used to have a `shouldWrap:` method"
]
