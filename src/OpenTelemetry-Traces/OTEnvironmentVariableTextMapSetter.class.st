"
A stateless setter for environment-variable carriers that normalizes propagation keys per the OpenTelemetry environment carrier specification.
"
Class {
	#name : 'OTEnvironmentVariableTextMapSetter',
	#superclass : 'Object',
	#classVars : [
		'Current'
	],
	#category : 'OpenTelemetry-Traces',
	#package : 'OpenTelemetry-Traces'
}

{ #category : 'accessing' }
OTEnvironmentVariableTextMapSetter class >> current [

	^ OTClassStateStore currentValueForClass: self ifAbsentPut: [ self new ]
]

{ #category : 'normalizing' }
OTEnvironmentVariableTextMapSetter class >> isNormalizedKey: aString [

	aString ifNil: [ ^ false ].
	aString isEmpty ifTrue: [ ^ false ].
	(self isNormalizedLeadingCharacter: aString first) ifFalse: [ ^ false ].
	^ aString allButFirst allSatisfy: [ :each | self isNormalizedTrailingCharacter: each ]
]

{ #category : 'normalizing' }
OTEnvironmentVariableTextMapSetter class >> isNormalizedLeadingCharacter: aCharacter [

	^ aCharacter = $_ or: [ aCharacter asciiValue between: 65 and: 90 ]
]

{ #category : 'normalizing' }
OTEnvironmentVariableTextMapSetter class >> isNormalizedTrailingCharacter: aCharacter [

	^ (self isNormalizedLeadingCharacter: aCharacter) or: [ aCharacter asciiValue between: 48 and: 57 ]
]

{ #category : 'normalizing' }
OTEnvironmentVariableTextMapSetter class >> normalizeKey: aString [

	aString ifNil: [ ^ '_' ].
	(self isNormalizedKey: aString) ifTrue: [ ^ aString ].
	aString isEmpty ifTrue: [ ^ '_' ].
	^ String streamContents: [ :stream |
			  | firstNormalized |
			  firstNormalized := self normalizedCharacterFor: aString first.
			  firstNormalized isDigit ifTrue: [ stream nextPut: $_ ].
			  stream nextPut: firstNormalized.
			  aString allButFirst do: [ :each | stream nextPut: (self normalizedCharacterFor: each) ] ]
]

{ #category : 'normalizing' }
OTEnvironmentVariableTextMapSetter class >> normalizedCharacterFor: aCharacter [

	| asciiValue |
	asciiValue := aCharacter asciiValue.
	((asciiValue between: 65 and: 90) or: [ asciiValue between: 97 and: 122 ]) ifTrue: [ ^ aCharacter asUppercase ].
	((asciiValue between: 48 and: 57) or: [ aCharacter = $_ ]) ifTrue: [ ^ aCharacter ].
	^ $_
]

{ #category : 'class initialization' }
OTEnvironmentVariableTextMapSetter class >> reset [

	OTClassStateStore removeCurrentValueForClass: self ifAbsent: [ ]
]

{ #category : 'accessing' }
OTEnvironmentVariableTextMapSetter >> setIn: aCarrier key: aString value: aValue [

	(aCarrier isNil or: [ aValue isNil ]) ifTrue: [ ^ self ].
	aCarrier at: (self class normalizeKey: aString) put: aValue
]
