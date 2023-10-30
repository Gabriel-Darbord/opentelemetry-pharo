"
A matcher that always returns `true`.
Use `OTMatcher class>>#any` instead of instantiating me.
"
Class {
	#name : 'OTAnyMatcher',
	#superclass : 'OTMatcher',
	#category : 'OpenTelemetry-Instrumentation',
	#package : 'OpenTelemetry-Instrumentation'
}

{ #category : 'testing' }
OTAnyMatcher >> matches: target [

	^ true
]
