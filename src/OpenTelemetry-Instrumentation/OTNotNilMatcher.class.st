"
An abstract matcher that rejects nil values.
"
Class {
	#name : #OTNotNilMatcher,
	#superclass : #OTMatcher,
	#category : #'OpenTelemetry-Instrumentation'
}

{ #category : #testing }
OTNotNilMatcher >> doMatch: target [
	"Matches the supplied value if it was found not to be nil."

	self subclassResponsibility
]

{ #category : #testing }
OTNotNilMatcher >> matches: target [

	^ target isNotNil and: [ self doMatch: target ]
]
