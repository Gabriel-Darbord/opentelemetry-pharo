"
A matcher is used as a predicate for identifying code elements such as types, methods, fields or pragmas.
They can be chained by using instances of `OTJunctionMatcher`s.
"
Class {
	#name : #OTMatcher,
	#superclass : #Object,
	#classInstVars : [
		'any',
		'none'
	],
	#category : 'OpenTelemetry-Instrumentation-Matchers'
}

{ #category : #'instance creation' }
OTMatcher class >> any [
	"Always matches."

	^ any ifNil: [ any := OTAnyMatcher new ]
]

{ #category : #'instance creation' }
OTMatcher class >> anyName: aStringCollection [
	"Matches elements with a name included in the given collection."

	| names |
	names := aStringCollection asSet.
	^ self plug: [ :element | names includes: element otName ]
]

{ #category : #'instance creation' }
OTMatcher class >> name: aString [
	"Matches elements with a name equal to aString."

	^ self plug: [ :element | element otName = aString ]
]

{ #category : #'instance creation' }
OTMatcher class >> nameBeginsWith: aString [
	"Matches elements with a name beginning with aString."

	^ self plug: [ :element | element otName beginsWith: aString ]
]

{ #category : #'instance creation' }
OTMatcher class >> none [
	"Never matches."

	^ none ifNil: [ none := OTNoneMatcher new ]
]

{ #category : #'instance creation' }
OTMatcher class >> plug: aBlock [
	"Matches using custom logic defined in the given one-arg block."

	^ OTPluggableMatcher new block: aBlock
]

{ #category : #controlling }
OTMatcher >> and: matcher [

	^ OTConjunctionMatcher withAll: { self. matcher }
]

{ #category : #testing }
OTMatcher >> matches: target [

	self subclassResponsibility
]

{ #category : #controlling }
OTMatcher >> or: matcher [

	^ OTDisjunctionMatcher withAll: { self. matcher }
]
