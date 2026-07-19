"
An immutable W3C TraceState value that preserves entry order and validates key/value mutations.
"
Class {
	#name : 'OTTraceState',
	#superclass : 'Object',
	#instVars : [
		'entriesByKey'
	],
	#category : 'OpenTelemetry-Instrumentation',
	#package : 'OpenTelemetry-Instrumentation'
}

{ #category : 'instance creation' }
OTTraceState class >> empty [

	^ self new
]

{ #category : 'instance creation' }
OTTraceState class >> from: aTraceState [

	aTraceState ifNil: [ ^ nil ].
	aTraceState class == self ifTrue: [ ^ aTraceState ].
	(aTraceState isString not and: [ aTraceState isSymbol not ]) ifTrue: [ ^ nil ].
	^ self fromHeader: aTraceState asString
]

{ #category : 'instance creation' }
OTTraceState class >> fromHeader: aString [

	| entries |
	aString ifNil: [ ^ nil ].
	entries := OrderedDictionary new.
	(aString substrings: ',') do: [ :each |
		| listMember |
		listMember := each trimBoth.
		listMember ifNotEmpty: [
			(self parseListMember: listMember into: entries) ifFalse: [ ^ nil ] ] ].
	^ self fromOrderedEntries: entries
]

{ #category : 'private' }
OTTraceState class >> fromOrderedEntries: anOrderedDictionary [

	(self hasValidEntries: anOrderedDictionary) ifFalse: [ ^ nil ].
	^ self new
		entriesByKey: anOrderedDictionary copy;
		yourself
]

{ #category : 'private' }
OTTraceState class >> isValidOtelSubkey: aString [

	aString ifNil: [ ^ false ].
	aString isEmpty ifTrue: [ ^ false ].
	(aString first between: $a and: $z) ifFalse: [ ^ false ].
	^ aString allSatisfy: [ :each |
		(each between: $a and: $z) or: [ each isDigit ] ]
]

{ #category : 'private' }
OTTraceState class >> isValidOtelSubvalue: aString [

	aString ifNil: [ ^ false ].
	^ aString allSatisfy: [ :each |
		each isDigit
			or: [
				each isLetter
					or: [ '._-' includes: each ] ] ]
]

{ #category : 'private' }
OTTraceState class >> hasValidEntries: anOrderedDictionary [

	anOrderedDictionary size <= 32 ifFalse: [ ^ false ].
	^ anOrderedDictionary associations allSatisfy: [ :each |
		(self isValidKey: each key) and: [ self isValidValue: each value ] ]
]

{ #category : 'private' }
OTTraceState class >> isAllowedKeyCharacter: aCharacter [

	^ aCharacter isDigit
		or: [
			(aCharacter between: $a and: $z)
				or: [ '_-*/' includes: aCharacter ] ]
]

{ #category : 'private' }
OTTraceState class >> isPrintableValueCharacter: aCharacter [

	| asciiValue |
	asciiValue := aCharacter asciiValue.
	^ (asciiValue between: 32 and: 126)
		and: [ aCharacter ~= $, and: [ aCharacter ~= $= ] ]
]

{ #category : 'private' }
OTTraceState class >> isValidKey: aString [

	| parts |
	aString ifNil: [ ^ false ].
	aString isEmpty ifTrue: [ ^ false ].
	aString size <= 256 ifFalse: [ ^ false ].
	(aString includes: Character space) ifTrue: [ ^ false ].
	(aString occurrencesOf: $@) <= 1 ifFalse: [ ^ false ].
	parts := aString substrings: '@'.
	parts size = 1 ifTrue: [ ^ self isValidSimpleKey: aString ].
	parts size = 2 ifFalse: [ ^ false ].
	^ (self isValidTenantId: parts first)
		and: [ self isValidSystemId: parts second ]
]

{ #category : 'private' }
OTTraceState class >> isValidSimpleKey: aString [

	aString ifEmpty: [ ^ false ].
	(aString first between: $a and: $z) ifFalse: [ ^ false ].
	^ aString allSatisfy: [ :each | self isAllowedKeyCharacter: each ]
]

{ #category : 'private' }
OTTraceState class >> isValidSystemId: aString [

	aString ifNil: [ ^ false ].
	(aString size between: 1 and: 14) ifFalse: [ ^ false ].
	^ self isValidSimpleKey: aString
]

{ #category : 'private' }
OTTraceState class >> isValidTenantId: aString [

	aString ifNil: [ ^ false ].
	(aString size between: 1 and: 241) ifFalse: [ ^ false ].
	((aString first between: $a and: $z)
		or: [ aString first isDigit ]) ifFalse: [ ^ false ].
	^ aString allSatisfy: [ :each | self isAllowedKeyCharacter: each ]
]

{ #category : 'private' }
OTTraceState class >> isValidValue: aString [

	aString ifNil: [ ^ false ].
	aString isEmpty ifTrue: [ ^ false ].
	aString size <= 256 ifFalse: [ ^ false ].
	(aString last = Character space) ifTrue: [ ^ false ].
	^ aString allSatisfy: [ :each | self isPrintableValueCharacter: each ]
]

{ #category : 'private' }
OTTraceState class >> parseListMember: aString into: anOrderedDictionary [

	| separator key value |
	separator := aString indexOf: $= ifAbsent: [ ^ false ].
	separator = 1 ifTrue: [ ^ false ].
	separator = aString size ifTrue: [ ^ false ].
	(aString indexOf: $= startingAt: separator + 1 ifAbsent: [ 0 ]) > 0 ifTrue: [ ^ false ].
	key := aString copyFrom: 1 to: separator - 1.
	value := aString copyFrom: separator + 1 to: aString size.
	((self isValidKey: key) and: [ self isValidValue: value ]) ifFalse: [ ^ false ].
	(anOrderedDictionary includesKey: key) ifTrue: [ ^ false ].
	anOrderedDictionary at: key put: value.
	^ true
]

{ #category : 'private' }
OTTraceState class >> parseOtelListMember: aString into: anOrderedDictionary [

	| key separator value |
	separator := aString indexOf: $: ifAbsent: [ ^ false ].
	separator = 1 ifTrue: [ ^ false ].
	separator = aString size ifTrue: [ ^ false ].
	(aString indexOf: $: startingAt: separator + 1 ifAbsent: [ 0 ]) > 0 ifTrue: [ ^ false ].
	key := aString copyFrom: 1 to: separator - 1.
	value := aString copyFrom: separator + 1 to: aString size.
	((self isValidOtelSubkey: key) and: [ self isValidOtelSubvalue: value ]) ifFalse: [ ^ false ].
	(anOrderedDictionary includesKey: key) ifTrue: [ ^ false ].
	anOrderedDictionary at: key put: value.
	^ true
]

{ #category : 'private' }
OTTraceState class >> otelEntriesFromValue: aString [

	| entries |
	aString ifNil: [ ^ OrderedDictionary new ].
	aString size <= 256 ifFalse: [ ^ nil ].
	entries := OrderedDictionary new.
	(aString substrings: ';') do: [ :each |
		each ifEmpty: [ ^ nil ].
		(self parseOtelListMember: each into: entries) ifFalse: [ ^ nil ] ].
	^ entries
]

{ #category : 'private' }
OTTraceState class >> otelValueFromEntries: anOrderedDictionary [

	^ String streamContents: [ :stream |
		anOrderedDictionary associations
			do: [ :each |
				stream
					nextPutAll: each key;
					nextPut: $:;
					nextPutAll: each value ]
			separatedBy: [ stream nextPut: $; ] ]
]

{ #category : 'comparing' }
OTTraceState >> = anObject [

	self == anObject ifTrue: [ ^ true ].
	self class = anObject class ifFalse: [ ^ false ].
	^ entriesByKey = anObject entriesByKey
]

{ #category : 'accessing' }
OTTraceState >> allEntries [

	^ entriesByKey associations asArray
]

{ #category : 'accessing' }
OTTraceState >> otelEntries [

	^ self class
		otelEntriesFromValue: (entriesByKey at: 'ot' ifAbsent: [ nil ])
]

{ #category : 'accessing' }
OTTraceState >> otelValueAt: aString [

	| entries |
	entries := self otelEntries.
	entries ifNil: [ ^ nil ].
	^ entries at: aString ifAbsent: [ nil ]
]

{ #category : 'converting' }
OTTraceState >> asHeaderValue [

	^ String streamContents: [ :stream |
		entriesByKey associations
			do: [ :each |
				stream
					nextPutAll: each key;
					nextPut: $=;
					nextPutAll: each value ]
			separatedBy: [ stream nextPut: $, ] ]
]

{ #category : 'accessing' }
OTTraceState >> at: aKey ifAbsent: aBlock [

	^ entriesByKey at: aKey ifAbsent: aBlock
]

{ #category : 'private' }
OTTraceState >> entriesByKey [

	^ entriesByKey
]

{ #category : 'private' }
OTTraceState >> entriesByKey: anOrderedDictionary [

	entriesByKey := anOrderedDictionary
]

{ #category : 'comparing' }
OTTraceState >> hash [

	^ entriesByKey hash
]

{ #category : 'testing' }
OTTraceState >> includesKey: aKey [

	^ entriesByKey includesKey: aKey
]

{ #category : 'initialization' }
OTTraceState >> initialize [

	super initialize.
	entriesByKey := OrderedDictionary new
]

{ #category : 'testing' }
OTTraceState >> isEmpty [

	^ entriesByKey isEmpty
]

{ #category : 'printing' }
OTTraceState >> printOn: aStream [

	super printOn: aStream.
	aStream
		nextPutAll: '(';
		nextPutAll: self asHeaderValue;
		nextPutAll: ')'
]

{ #category : 'accessing' }
OTTraceState >> valueAt: aKey [

	^ self at: aKey ifAbsent: [ nil ]
]

{ #category : 'accessing' }
OTTraceState >> valueAt: aKey ifAbsent: aBlock [

	^ self at: aKey ifAbsent: aBlock
]

{ #category : 'updating' }
OTTraceState >> withKey: aKey value: aValue [

	| updatedEntries updatedTraceState |
	((self class isValidKey: aKey) and: [ self class isValidValue: aValue ]) ifFalse: [ ^ self ].
	(entriesByKey includesKey: aKey) not ifTrue: [
		entriesByKey size >= 32 ifTrue: [ ^ self ] ].
	updatedEntries := OrderedDictionary new.
	updatedEntries at: aKey put: aValue.
	entriesByKey associationsDo: [ :each |
		each key = aKey ifFalse: [
			updatedEntries at: each key put: each value ] ].
	updatedTraceState := self class fromOrderedEntries: updatedEntries.
	^ updatedTraceState ifNil: [ self ]
]

{ #category : 'updating' }
OTTraceState >> withOtelValueAt: aKey put: aValue [

	| entries otValue |
	entries := self otelEntries.
	entries ifNil: [ ^ self ].
	((self class isValidOtelSubkey: aKey) and: [ self class isValidOtelSubvalue: aValue ]) ifFalse: [
		^ self ].
	entries := entries copy.
	entries at: aKey put: aValue.
	otValue := self class otelValueFromEntries: entries.
	otValue size > 256 ifTrue: [ ^ self ].
	^ self withKey: 'ot' value: otValue
]

{ #category : 'updating' }
OTTraceState >> withoutOtelValueAt: aKey [

	| entries otValue |
	entries := self otelEntries.
	entries ifNil: [ ^ self ].
	(entries includesKey: aKey) ifFalse: [ ^ self ].
	entries := entries copy.
	entries removeKey: aKey.
	entries isEmpty ifTrue: [ ^ self withoutKey: 'ot' ].
	otValue := self class otelValueFromEntries: entries.
	^ self withKey: 'ot' value: otValue
]

{ #category : 'updating' }
OTTraceState >> withoutKey: aKey [

	| updatedEntries updatedTraceState |
	(entriesByKey includesKey: aKey) ifFalse: [ ^ self ].
	updatedEntries := entriesByKey copy.
	updatedEntries removeKey: aKey.
	updatedTraceState := self class fromOrderedEntries: updatedEntries.
	^ updatedTraceState ifNil: [ self ]
]
