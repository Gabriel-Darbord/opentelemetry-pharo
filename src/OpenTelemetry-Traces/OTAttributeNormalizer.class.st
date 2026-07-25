"
Internal utility for validating and normalizing OpenTelemetry attribute keys and values.
"
Class {
	#name : 'OTAttributeNormalizer',
	#superclass : 'Object',
	#category : 'OpenTelemetry-Traces',
	#package : 'OpenTelemetry-Traces'
}

{ #category : 'testing' }
OTAttributeNormalizer class >> isBoolean: anObject [

	^ anObject == true or: [ anObject == false ]
]

{ #category : 'testing' }
OTAttributeNormalizer class >> isMapValue: anObject [

	anObject isDictionary ifTrue: [ ^ true ].
	(anObject isCollection and: [ anObject isEmpty not ]) ifFalse: [ ^ false ].
	^ anObject allSatisfy: [ :each | each isAssociation ]
]

{ #category : 'testing' }
OTAttributeNormalizer class >> isUnlimitedLengthLimit: aNumber [

	^ aNumber isNil
]

{ #category : 'constants' }
OTAttributeNormalizer class >> maxSignedInteger64 [

	^ 9223372036854775807
]

{ #category : 'private' }
OTAttributeNormalizer class >> mayAddAttributeNamed: aKey to: aDictionary countLimit: aCountLimit [

	aCountLimit ifNil: [ ^ true ].
	^ aDictionary size < aCountLimit
]

{ #category : 'constants' }
OTAttributeNormalizer class >> minSignedInteger64 [

	^ -9223372036854775808
]

{ #category : 'normalizing' }
OTAttributeNormalizer class >> normalizeArrayValue: aCollection [

	^ self normalizeArrayValue: aCollection lengthLimit: nil
]

{ #category : 'normalizing' }
OTAttributeNormalizer class >> normalizeArrayValue: aCollection lengthLimit: aLengthLimit [

	| normalized |
	normalized := OrderedCollection new: aCollection size.
	aCollection do: [ :each | normalized add: (self normalizeAttributeValue: each lengthLimit: aLengthLimit) ].
	^ normalized asArray
]

{ #category : 'normalizing' }
OTAttributeNormalizer class >> normalizeAttributeKey: aKey [

	| normalized |
	aKey ifNil: [ self signalInvalidAttributeKey: aKey ].
	(aKey isString or: [ aKey isSymbol ]) ifFalse: [ self signalInvalidAttributeKey: aKey ].
	normalized := aKey asString.
	normalized isEmpty ifTrue: [ self signalInvalidAttributeKey: aKey ].
	^ normalized
]

{ #category : 'normalizing' }
OTAttributeNormalizer class >> normalizeAttributeValue: anObject [

	^ self normalizeAttributeValue: anObject lengthLimit: nil
]

{ #category : 'normalizing' }
OTAttributeNormalizer class >> normalizeAttributeValue: anObject lengthLimit: aLengthLimit [

	anObject isNil ifTrue: [ ^ nil ].
	(anObject isString or: [ anObject isSymbol ]) ifTrue: [ ^ self truncateString: anObject asString lengthLimit: aLengthLimit ].
	(self isBoolean: anObject) ifTrue: [ ^ anObject ].
	anObject isInteger ifTrue: [ ^ self normalizeIntegerValue: anObject ].
	anObject isNumber ifTrue: [ ^ anObject asFloat ].
	(anObject isKindOf: ByteArray) ifTrue: [ ^ self truncateByteArray: anObject lengthLimit: aLengthLimit ].
	(self isMapValue: anObject) ifTrue: [ ^ self normalizeMapValue: anObject lengthLimit: aLengthLimit ].
	anObject isCollection ifTrue: [ ^ self normalizeArrayValue: anObject lengthLimit: aLengthLimit ].
	self signalInvalidAttributeValue: anObject
]

{ #category : 'normalizing' }
OTAttributeNormalizer class >> normalizeAttributes: aCollection [

	^ (self normalizeAttributes: aCollection countLimit: nil valueLengthLimit: nil) first
]

{ #category : 'normalizing' }
OTAttributeNormalizer class >> normalizeAttributes: aCollection countLimit: aCountLimit valueLengthLimit: aLengthLimit [

	| normalized droppedCount |
	normalized := OrderedDictionary new.
	droppedCount := 0.
	aCollection ifNil: [
			^ {
				  normalized.
				  droppedCount } ].
	(aCollection isDictionary or: [ aCollection isCollection and: [ aCollection allSatisfy: [ :each | each isAssociation ] ] ])
		ifFalse: [ self signalInvalidAttributeCollection: aCollection ].
	aCollection associationsDo: [ :each |
			| key value |
			key := self normalizeAttributeKey: each key.
			value := self normalizeAttributeValue: each value lengthLimit: aLengthLimit.
			((normalized includesKey: key) or: [ self mayAddAttributeNamed: key to: normalized countLimit: aCountLimit ])
				ifTrue: [ normalized at: key put: value ]
				ifFalse: [ droppedCount := droppedCount + 1 ] ].
	^ {
		  normalized.
		  droppedCount }
]

{ #category : 'normalizing' }
OTAttributeNormalizer class >> normalizeIntegerValue: anInteger [

	(anInteger between: self minSignedInteger64 and: self maxSignedInteger64) ifFalse: [ self signalInvalidAttributeValue: anInteger ].
	^ anInteger
]

{ #category : 'normalizing' }
OTAttributeNormalizer class >> normalizeMapValue: aCollection [

	^ self normalizeMapValue: aCollection lengthLimit: nil
]

{ #category : 'normalizing' }
OTAttributeNormalizer class >> normalizeMapValue: aCollection lengthLimit: aLengthLimit [

	| normalized |
	normalized := OrderedDictionary new.
	aCollection associationsDo: [ :each |
		normalized at: (self normalizeAttributeKey: each key) put: (self normalizeAttributeValue: each value lengthLimit: aLengthLimit) ].
	^ normalized
]

{ #category : 'private' }
OTAttributeNormalizer class >> signalInvalidAttributeCollection: aCollection [

	Error signal: 'OpenTelemetry attributes must be provided as a dictionary or a collection of associations'
]

{ #category : 'private' }
OTAttributeNormalizer class >> signalInvalidAttributeKey: aKey [

	Error signal: 'OpenTelemetry attribute keys must be non-empty strings or symbols'
]

{ #category : 'private' }
OTAttributeNormalizer class >> signalInvalidAttributeValue: anObject [

	Error signal: 'Unsupported OpenTelemetry attribute value: ' , anObject printString
]

{ #category : 'private' }
OTAttributeNormalizer class >> truncateByteArray: aByteArray lengthLimit: aLengthLimit [

	(self isUnlimitedLengthLimit: aLengthLimit) ifTrue: [ ^ aByteArray copy ].
	aByteArray size <= aLengthLimit ifTrue: [ ^ aByteArray copy ].
	^ aByteArray copyFrom: 1 to: aLengthLimit
]

{ #category : 'private' }
OTAttributeNormalizer class >> truncateString: aString lengthLimit: aLengthLimit [

	(self isUnlimitedLengthLimit: aLengthLimit) ifTrue: [ ^ aString ].
	aString size <= aLengthLimit ifTrue: [ ^ aString ].
	^ aString copyFrom: 1 to: aLengthLimit
]
