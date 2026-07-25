"
A W3C Baggage text-map propagator for baggage headers.
"
Class {
	#name : 'OTW3CBaggagePropagator',
	#superclass : 'OTTextMapPropagator',
	#classInstVars : [
		'current'
	],
	#category : 'OpenTelemetry-Traces',
	#package : 'OpenTelemetry-Traces'
}

{ #category : 'accessing' }
OTW3CBaggagePropagator class >> baggageHeaderName [

	^ 'baggage'
]

{ #category : 'accessing' }
OTW3CBaggagePropagator class >> current [

	^ current ifNil: [ current := self new ]
]

{ #category : 'accessing' }
OTW3CBaggagePropagator class >> maxBaggageBytes [

	^ 8192
]

{ #category : 'accessing' }
OTW3CBaggagePropagator class >> maxBaggageEntries [

	^ 64
]

{ #category : 'class initialization' }
OTW3CBaggagePropagator class >> reset [

	current := nil
]

{ #category : 'private' }
OTW3CBaggagePropagator >> baggageAndEntryCountFromHeader: aString startingWith: aBaggage remainingEntries: anInteger [

	| acceptedEntries baggage |
	baggage := aBaggage.
	acceptedEntries := 0.
	(aString substrings: ',') do: [ :eachMember |
			acceptedEntries < anInteger ifTrue: [
					(self baggageMemberFrom: eachMember) ifNotNil: [ :anAssociation |
							acceptedEntries := acceptedEntries + 1.
							baggage := baggage
								           withEntryNamed: anAssociation key
								           value: anAssociation value value
								           metadata: anAssociation value metadata ] ] ].
	^ Array with: baggage with: acceptedEntries
]

{ #category : 'private' }
OTW3CBaggagePropagator >> baggageFromCarrier: aCarrier getter: aGetter [

	| baggage totalBytes totalEntries |
	baggage := OTBaggage empty.
	totalBytes := 0.
	totalEntries := 0.
	(aGetter getAllFrom: aCarrier key: self class baggageHeaderName) do: [ :eachHeader |
			| headerBytes parsedHeader remainingEntries |
			eachHeader isEmpty ifFalse: [
					headerBytes := eachHeader size.
					(totalEntries >= self class maxBaggageEntries or: [ totalBytes + headerBytes > self class maxBaggageBytes ]) ifTrue: [
						^ baggage ].
					remainingEntries := self class maxBaggageEntries - totalEntries.
					parsedHeader := self baggageAndEntryCountFromHeader: eachHeader startingWith: baggage remainingEntries: remainingEntries.
					baggage := parsedHeader first.
					totalEntries := totalEntries + parsedHeader second.
					totalBytes := totalBytes + headerBytes ] ].
	^ baggage
]

{ #category : 'private' }
OTW3CBaggagePropagator >> baggageFromHeader: aString [

	^ (self baggageAndEntryCountFromHeader: aString startingWith: OTBaggage empty remainingEntries: self class maxBaggageEntries)
		  first
]

{ #category : 'private' }
OTW3CBaggagePropagator >> baggageMemberFrom: aString [

	| member metadataIndex memberPart keyValueIndex rawKey rawValue key value metadata |
	member := aString trimBoth.
	member isEmpty ifTrue: [ ^ nil ].
	metadataIndex := member indexOf: $; ifAbsent: [ 0 ].
	memberPart := metadataIndex = 0
		              ifTrue: [ member ]
		              ifFalse: [ member copyFrom: 1 to: metadataIndex - 1 ].
	keyValueIndex := memberPart indexOf: $= ifAbsent: [ ^ nil ].
	keyValueIndex = 1 ifTrue: [ ^ nil ].
	keyValueIndex = memberPart size ifTrue: [ ^ nil ].
	rawKey := (memberPart copyFrom: 1 to: keyValueIndex - 1) trimBoth.
	rawValue := (memberPart copyFrom: keyValueIndex + 1 to: memberPart size) trimBoth.
	(self isValidEncodedBaggageKey: rawKey) ifFalse: [ ^ nil ].
	(self isValidEncodedBaggageValue: rawValue) ifFalse: [ ^ nil ].
	key := self decodedComponentFrom: rawKey.
	value := self decodedComponentFrom: rawValue.
	((self isValidBaggageKey: key) and: [ value isNotNil and: [ value isNotEmpty ] ]) ifFalse: [ ^ nil ].
	metadata := metadataIndex = 0
		            ifTrue: [ '' ]
		            ifFalse: [ (member copyFrom: metadataIndex + 1 to: member size) trimBoth ].
	metadata := self decodedComponentFrom: metadata.
	metadata ifNil: [ ^ nil ].
	^ key -> (OTBaggageEntry value: value metadata: metadata)
]

{ #category : 'private' }
OTW3CBaggagePropagator >> decodedComponentFrom: aString [

	^ [ aString urlDecoded ]
		  on: Error
		  do: [ nil ]
]

{ #category : 'extracting' }
OTW3CBaggagePropagator >> extract: aContext from: aCarrier [

	^ self extract: aContext from: aCarrier getter: OTDictionaryTextMapGetter current
]

{ #category : 'extracting' }
OTW3CBaggagePropagator >> extract: aContext from: aCarrier getter: aGetter [

	| baseContext baggage |
	baseContext := aContext ifNil: [ OTContext new ] ifNotNil: [ aContext ].
	aGetter ifNil: [ ^ baseContext ].
	baggage := self baggageFromCarrier: aCarrier getter: aGetter.
	baggage isEmpty ifTrue: [ ^ baseContext ].
	^ baseContext withBaggage: baggage
]

{ #category : 'accessing' }
OTW3CBaggagePropagator >> fields [

	^ { self class baggageHeaderName }
]

{ #category : 'private' }
OTW3CBaggagePropagator >> headerValueFor: aBaggage [

	| stream entryCount |
	stream := String new writeStream.
	entryCount := 0.
	aBaggage entries do: [ :anAssociation |
			(self serializedMemberNamed: anAssociation key entry: anAssociation value) ifNotNil: [ :aString |
					| projectedSize |
					entryCount < self class maxBaggageEntries ifTrue: [
							projectedSize := stream position + aString size + (entryCount > 0
								                  ifTrue: [ 1 ]
								                  ifFalse: [ 0 ]).
							projectedSize <= self class maxBaggageBytes ifTrue: [
									entryCount > 0 ifTrue: [ stream nextPut: $, ].
									stream nextPutAll: aString.
									entryCount := entryCount + 1 ] ] ] ].
	^ stream contents
]

{ #category : 'injecting' }
OTW3CBaggagePropagator >> inject: aContext into: aCarrier [

	^ self inject: aContext into: aCarrier setter: OTDictionaryTextMapSetter current
]

{ #category : 'injecting' }
OTW3CBaggagePropagator >> inject: aContext into: aCarrier setter: aSetter [

	| baggage headerValue |
	(aContext isNil or: [ aSetter isNil ]) ifTrue: [ ^ self ].
	baggage := aContext baggage.
	baggage isEmpty ifTrue: [ ^ self ].
	headerValue := self headerValueFor: baggage.
	headerValue ifEmpty: [ ^ self ].
	aSetter setIn: aCarrier key: self class baggageHeaderName value: headerValue.
	^ self
]

{ #category : 'private' }
OTW3CBaggagePropagator >> isValidBaggageKey: aString [

	aString ifNil: [ ^ false ].
	aString isEmpty ifTrue: [ ^ false ].
	^ aString allSatisfy: [ :eachCharacter | eachCharacter isAlphaNumeric or: [ '!#$%&''*+-.^_`|~' includes: eachCharacter ] ]
]

{ #category : 'private' }
OTW3CBaggagePropagator >> isValidEncodedBaggageKey: aString [

	^ self isValidBaggageKey: aString
]

{ #category : 'private' }
OTW3CBaggagePropagator >> isValidEncodedBaggageValue: aString [

	aString ifNil: [ ^ false ].
	aString isEmpty ifTrue: [ ^ false ].
	^ aString allSatisfy: [ :eachCharacter | self isValidEncodedBaggageValueCharacter: eachCharacter ]
]

{ #category : 'private' }
OTW3CBaggagePropagator >> isValidEncodedBaggageValueCharacter: aCharacter [

	| asciiValue |
	asciiValue := aCharacter asciiValue.
	(asciiValue between: 33 and: 126) ifFalse: [ ^ false ].
	^ aCharacter ~= $, and: [ aCharacter ~= $; and: [ asciiValue ~= 92 ] ]
]

{ #category : 'private' }
OTW3CBaggagePropagator >> serializedMemberNamed: aName entry: anEntry [

	((self isValidBaggageKey: aName) and: [ anEntry value isNotEmpty ]) ifFalse: [ ^ nil ].
	^ String streamContents: [ :stream |
			  stream nextPutAll: aName urlEncoded.
			  stream nextPut: $=.
			  stream nextPutAll: anEntry value urlEncoded.
			  anEntry hasMetadata ifTrue: [
					  stream nextPut: $;.
					  stream nextPutAll: anEntry metadata asString urlEncoded ] ]
]
