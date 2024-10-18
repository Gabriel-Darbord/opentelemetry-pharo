"
A matcher is used as a predicate for identifying code elements such as types, methods, fields or pragmas.
They can be chained by using instances of `OTJunctionMatcher`s.
"
Class {
	#name : 'OTMatcher',
	#superclass : 'Object',
	#classInstVars : [
		'any',
		'none'
	],
	#category : 'OpenTelemetry-Matchers',
	#package : 'OpenTelemetry-Matchers'
}

{ #category : 'controlling' }
OTMatcher class >> and: aMatcherCollection [
	"Shortcut to easily create a conjunction of matchers that is easier to read than chaining."

	^ OTConjunctionMatcher withAll: aMatcherCollection
]

{ #category : 'instance creation' }
OTMatcher class >> any [
	"Always matches."

	^ any ifNil: [ any := OTAnyMatcher new ]
]

{ #category : 'instance creation' }
OTMatcher class >> anyName: aStringCollection [
	"Matches elements with a name included in the given collection."

	| names |
	names := aStringCollection asSet.
	^ self plug: [ :element | names includes: element otName ]
]

{ #category : 'instance creation' }
OTMatcher class >> equalTo: anObject [
	"Matches elements equal to the given object."

	^ self plug: [ :element | element = anObject ]
]

{ #category : 'instance creation' }
OTMatcher class >> hierarchyOf: aClass [
	"Matches classes in the hierarchy (above or below) of aClass."

	^ self plug: [ :class | class isInClassHierarchyOf: aClass ]
]

{ #category : 'instance creation' }
OTMatcher class >> identicalTo: anObject [
	"Matches the given object."

	^ self plug: [ :element | element == anObject ]
]

{ #category : 'testing' }
OTMatcher class >> isAbstract [

	^ self == OTMatcher
]

{ #category : 'instance creation' }
OTMatcher class >> name: aString [
	"Matches elements with a name equal to aString."

	^ self plug: [ :element | element otName = aString ]
]

{ #category : 'instance creation' }
OTMatcher class >> nameBeginsWith: aString [
	"Matches elements with a name beginning with aString."

	^ self plug: [ :element | element otName beginsWith: aString ]
]

{ #category : 'instance creation' }
OTMatcher class >> nameEndsWith: aString [
	"Matches elements with a name ending with aString."

	^ self plug: [ :element | element otName endsWith: aString ]
]

{ #category : 'testing' }
OTMatcher class >> nameIncludes: aString [

	^ self plug: [ :element | element otName includesSubstring: aString ]
]

{ #category : 'testing' }
OTMatcher class >> nameMatches: aRegexString [

	| regex |
	regex := aRegexString asRegex.
	^ self plug: [ :element | regex matches: element otName ]
]

{ #category : 'testing' }
OTMatcher class >> nameSearch: aRegexString [

	| regex |
	regex := aRegexString asRegex.
	^ self plug: [ :element | regex search: element otName ]
]

{ #category : 'instance creation' }
OTMatcher class >> none [
	"Never matches."

	^ none ifNil: [ none := OTNoneMatcher new ]
]

{ #category : 'evaluating' }
OTMatcher class >> oneOf: aCollection [

	| aSet |
	aSet := aCollection asSet.
	^ self plug: [ :element | aSet includes: element ]
]

{ #category : 'controlling' }
OTMatcher class >> or: aMatcherCollection [
	"Shortcut to easily create a disjunction of matchers that is easier to read than chaining."

	^ OTDisjunctionMatcher withAll: aMatcherCollection
]

{ #category : 'instance creation' }
OTMatcher class >> plug: aBlock [
	"Matches using custom logic defined in the given one-arg block.
	The argument is either a package, class or method."

	^ OTPluggableMatcher new block: aBlock
]

{ #category : 'instance creation' }
OTMatcher class >> subclassesOf: aClass [
	"Matches subclasses of aClass."

	^ self plug: [ :class | class inheritsFrom: aClass ]
]

{ #category : 'instance creation' }
OTMatcher class >> superclassesOf: aClass [
	"Matches superclasses of aClass."

	^ self plug: [ :class | aClass inheritsFrom: class ]
]

{ #category : 'controlling' }
OTMatcher >> and: matcher [

	^ OTConjunctionMatcher withAll: { self. matcher }
]

{ #category : 'testing' }
OTMatcher >> matches: target [

	self subclassResponsibility
]

{ #category : 'enumerating' }
OTMatcher >> matching: aCollection do: aBlock [

	aCollection do: [ :element |
		(self matches: element) ifTrue: [ aBlock value: element ] ]
]

{ #category : 'enumerating' }
OTMatcher >> matchingPackagesDo: aBlock [

	self class packageOrganizer packages do: [ :package |
		(self matches: package) ifTrue: [ aBlock value: package ] ]
]

{ #category : 'testing' }
OTMatcher >> not [

	^ OTNegatingMatcher new matcher: self
]

{ #category : 'controlling' }
OTMatcher >> or: matcher [

	^ OTDisjunctionMatcher withAll: { self. matcher }
]
