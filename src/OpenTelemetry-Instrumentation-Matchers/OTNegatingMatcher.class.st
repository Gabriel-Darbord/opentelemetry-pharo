"
A matcher that reverses the matching result of another matcher.
"
Class {
	#name : 'OTNegatingMatcher',
	#superclass : 'OTMatcher',
	#instVars : [
		'matcher'
	],
	#category : 'OpenTelemetry-Instrumentation-Matchers',
	#package : 'OpenTelemetry-Instrumentation-Matchers'
}

{ #category : 'testing' }
OTNegatingMatcher >> matcher [

	^ matcher
]

{ #category : 'testing' }
OTNegatingMatcher >> matcher: aMatcher [

	matcher := aMatcher
]

{ #category : 'testing' }
OTNegatingMatcher >> matches: target [

	^ (matcher matches: target) not
]
