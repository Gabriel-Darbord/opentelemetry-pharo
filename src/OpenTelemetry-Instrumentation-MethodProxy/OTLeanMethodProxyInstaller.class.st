Class {
	#name : 'OTLeanMethodProxyInstaller',
	#superclass : 'OTMethodProxyInstaller',
	#category : 'OpenTelemetry-Instrumentation-MethodProxy',
	#package : 'OpenTelemetry-Instrumentation-MethodProxy'
}

{ #category : 'private' }
OTLeanMethodProxyInstaller >> shouldInstrument: aMethod with: anInstrumentation [
	"A bit weird but this is when the proxy is created"

	(self class isMethodProxyArtifact: aMethod) ifTrue: [ ^ false ].
	proxy := anInstrumentation methodProxyClass onMethod: aMethod handler: anInstrumentation.
	^ true
]
