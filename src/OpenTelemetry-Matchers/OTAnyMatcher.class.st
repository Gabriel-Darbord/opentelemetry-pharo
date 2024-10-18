"
A matcher that always returns `true`.
Use `OTMatcher class>>#any` instead of instantiating me.
"
Class {
	#name : 'OTAnyMatcher',
	#superclass : 'OTMatcher',
	#category : 'OpenTelemetry-Matchers',
	#package : 'OpenTelemetry-Matchers'
}

{ #category : 'testing' }
OTAnyMatcher >> matches: target [

	^ true
]
