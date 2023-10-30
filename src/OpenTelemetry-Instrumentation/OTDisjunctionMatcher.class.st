"
A matcher which only matches an element if any represented matchers constitute a match.
Use `OTMatcher>>#or:` instead of instantiating me.
"
Class {
	#name : 'OTDisjunctionMatcher',
	#superclass : 'OTJunctionMatcher',
	#category : 'OpenTelemetry-Instrumentation',
	#package : 'OpenTelemetry-Instrumentation'
}

{ #category : 'testing' }
OTDisjunctionMatcher >> matches: target [

	^ matchers anySatisfy: [ :matcher | matcher matches: target ]
]

{ #category : 'controlling' }
OTDisjunctionMatcher >> or: matcher [
	"No need to create an instance, simply add to current matcher."

	matchers add: matcher
]
