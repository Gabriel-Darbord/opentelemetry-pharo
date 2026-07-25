Class {
	#name : 'OTBeforeOnlyMetaLinkTestInstrumentation',
	#superclass : 'OTMetaLinkTestInstrumentation',
	#category : 'OpenTelemetry-Instrumentation-MetaLink-Tests',
	#package : 'OpenTelemetry-Instrumentation-MetaLink-Tests'
}

{ #category : 'evaluating' }
OTBeforeOnlyMetaLinkTestInstrumentation class >> onMethodEnter: event [

	^ super onMethodEnter: event
]

{ #category : 'configuring' }
OTBeforeOnlyMetaLinkTestInstrumentation class >> usesMethodExitHook [

	^ false
]
