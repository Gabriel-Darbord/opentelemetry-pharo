"
A matcher which only matches an element if all represented matchers constitute a match.
Use `OTMatcher>>#and:` instead of instantiating me.
"
Class {
	#name : #OTConjunctionMatcher,
	#superclass : #OTJunctionMatcher,
	#category : 'OpenTelemetry-Instrumentation-Matchers'
}

{ #category : #controlling }
OTConjunctionMatcher >> and: matcher [
	"No need to create an instance, simply add to current matcher."

	matchers add: matcher
]

{ #category : #testing }
OTConjunctionMatcher >> matches: target [

	^ matchers allSatisfy: [ :matcher | matcher matches: target ]
]
