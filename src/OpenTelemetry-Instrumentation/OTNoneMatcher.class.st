"
A matcher that always returns `false`.
Use `OTMatcher class>>#none` instead of instantiating me.
"
Class {
	#name : #OTNoneMatcher,
	#superclass : #OTMatcher,
	#category : #'OpenTelemetry-Instrumentation'
}

{ #category : #testing }
OTNoneMatcher >> matches: target [

	^ false
]
