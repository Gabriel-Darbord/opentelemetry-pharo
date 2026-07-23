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

	^ self fromOrderedEntries: OrderedDictionary new
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
	^ self newInternal
		  restoreEntriesByKey: anOrderedDictionary copy;
		  yourself
]

{ #category : 'private' }
OTTraceState class >> hasValidEntries: anOrderedDictionary [

	anOrderedDictionary size <= 32 ifFalse: [ ^ false ].
	(self headerValueLengthOf: anOrderedDictionary) <= self maximumHeaderLength ifFalse: [ ^ false ].
	^ anOrderedDictionary associations allSatisfy: [ :each | (self isValidKey: each key) and: [ self isValidValue: each value ] ]
]

{ #category : 'private' }
OTTraceState class >> headerValueLengthOf: anOrderedDictionary [

	| length |
	length := 0.
	anOrderedDictionary associationsDo: [ :each | length := length + each key size + 1 + each value size ].
	anOrderedDictionary size > 1 ifTrue: [ length := length + anOrderedDictionary size - 1 ].
	^ length
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

	| normalized parts |
	normalized := self validationStringFrom: aString.
	normalized ifNil: [ ^ false ].
	normalized isEmpty ifTrue: [ ^ false ].
	normalized size <= 256 ifFalse: [ ^ false ].
	(normalized includes: Character space) ifTrue: [ ^ false ].
	(normalized occurrencesOf: $@) <= 1 ifFalse: [ ^ false ].
	parts := normalized substrings: '@'.
	parts size = 1 ifTrue: [ ^ self isValidSimpleKey: normalized ].
	parts size = 2 ifFalse: [ ^ false ].
	^ (self isValidTenantId: parts first) and: [ self isValidSystemId: parts second ]
]

{ #category : 'private' }
OTTraceState class >> isValidOtelSubkey: aString [

	| normalized |
	normalized := self validationStringFrom: aString.
	normalized ifNil: [ ^ false ].
	normalized isEmpty ifTrue: [ ^ false ].
	(normalized first between: $a and: $z) ifFalse: [ ^ false ].
	^ normalized allSatisfy: [ :each | (each between: $a and: $z) or: [ each isDigit ] ]
]

{ #category : 'private' }
OTTraceState class >> isValidOtelSubvalue: aString [

	| normalized |
	normalized := self validationStringFrom: aString.
	normalized ifNil: [ ^ false ].
	normalized isEmpty ifTrue: [ ^ false ].
	^ normalized allSatisfy: [ :each | each isDigit or: [ each isLetter or: [ '._-' includes: each ] ] ]
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

	| normalized |
	normalized := self validationStringFrom: aString.
	normalized ifNil: [ ^ false ].
	normalized isEmpty ifTrue: [ ^ false ].
	normalized size <= 256 ifFalse: [ ^ false ].
	normalized last = Character space ifTrue: [ ^ false ].
	^ normalized allSatisfy: [ :each | self isPrintableValueCharacter: each ]
]

{ #category : 'private' }
OTTraceState class >> maximumHeaderLength [

	^ 512
]

{ #category : 'instance creation' }
OTTraceState class >> new [

	Error signal: 'TraceState is immutable. Use OTTraceState class-side constructors and update messages.'
]

{ #category : 'private' }
OTTraceState class >> newInternal [

	^ super new
]

{ #category : 'private' }
OTTraceState class >> normalizedOtelSubvalueForKey: aKey value: aValue [

	| normalized threshold |
	normalized := self validationStringFrom: aValue.
	normalized ifNil: [ ^ nil ].
	aKey = 'th' ifTrue: [
			threshold := OTConsistentProbability thresholdFromString: normalized.
			threshold ifNil: [ ^ nil ].
			^ OTConsistentProbability thresholdStringFor: threshold ].
	aKey = 'rv' ifTrue: [
			^ (OTConsistentProbability usesExplicitRandomness: normalized)
				  ifTrue: [ normalized ]
				  ifFalse: [ nil ] ].
	^ (self isValidOtelSubvalue: normalized)
		  ifTrue: [ normalized ]
		  ifFalse: [ nil ]
]

{ #category : 'private' }
OTTraceState class >> normalizedOtelValue: aString [

	| entries |
	entries := self otelEntriesFromValue: aString.
	entries ifNil: [ ^ nil ].
	entries isEmpty ifTrue: [ ^ '' ].
	^ self otelValueFromEntries: entries
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

{ #category : 'private' }
OTTraceState class >> parseListMember: aString into: anOrderedDictionary [

	| separator key normalizedValue value |
	separator := aString indexOf: $= ifAbsent: [ ^ false ].
	separator = 1 ifTrue: [ ^ false ].
	separator = aString size ifTrue: [ ^ false ].
	(aString indexOf: $= startingAt: separator + 1 ifAbsent: [ 0 ]) > 0 ifTrue: [ ^ false ].
	key := aString copyFrom: 1 to: separator - 1.
	value := aString copyFrom: separator + 1 to: aString size.
	(self isValidKey: key) ifFalse: [ ^ false ].
	key = 'ot'
		ifTrue: [
				normalizedValue := self normalizedOtelValue: value.
				normalizedValue ifNil: [ ^ true ].
				normalizedValue ifEmpty: [ ^ true ].
				value := normalizedValue ]
		ifFalse: [ (self isValidValue: value) ifFalse: [ ^ false ] ].
	(anOrderedDictionary includesKey: key) ifTrue: [ ^ false ].
	anOrderedDictionary at: key put: value.
	^ true
]

{ #category : 'private' }
OTTraceState class >> parseOtelListMember: aString into: anOrderedDictionary [

	| key normalizedValue separator value |
	separator := aString indexOf: $: ifAbsent: [ ^ false ].
	separator = 1 ifTrue: [ ^ false ].
	separator = aString size ifTrue: [ ^ false ].
	(aString indexOf: $: startingAt: separator + 1 ifAbsent: [ 0 ]) > 0 ifTrue: [ ^ false ].
	key := aString copyFrom: 1 to: separator - 1.
	value := aString copyFrom: separator + 1 to: aString size.
	(self isValidOtelSubkey: key) ifFalse: [ ^ false ].
	normalizedValue := self normalizedOtelSubvalueForKey: key value: value.
	normalizedValue ifNil: [ ^ false ].
	(anOrderedDictionary includesKey: key) ifTrue: [ ^ false ].
	anOrderedDictionary at: key put: normalizedValue.
	^ true
]

{ #category : 'private' }
OTTraceState class >> validationStringFrom: anObject [

	anObject ifNil: [ ^ nil ].
	(anObject isString or: [ anObject isSymbol ]) ifTrue: [ ^ anObject asString ].
	^ nil
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

{ #category : 'printing' }
OTTraceState >> printOn: aStream [

	super printOn: aStream.
	aStream
		nextPutAll: '(';
		nextPutAll: self asHeaderValue;
		nextPutAll: ')'
]

{ #category : 'private' }
OTTraceState >> restoreEntriesByKey: anOrderedDictionary [

	entriesByKey := anOrderedDictionary
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

	| entries normalizedValue otValue |
	entries := self otelEntries.
	entries ifNil: [ ^ self ].
	(self class isValidOtelSubkey: aKey) ifFalse: [ ^ self ].
	normalizedValue := self class normalizedOtelSubvalueForKey: aKey value: aValue.
	normalizedValue ifNil: [ ^ self ].
	entries := entries copy.
	entries at: aKey put: normalizedValue.
	otValue := self class otelValueFromEntries: entries.
	otValue size > 256 ifTrue: [ ^ self ].
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
