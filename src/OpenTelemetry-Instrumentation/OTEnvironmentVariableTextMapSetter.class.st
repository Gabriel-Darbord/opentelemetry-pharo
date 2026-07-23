"
A stateless setter for environment-variable carriers that normalizes propagation keys per the OpenTelemetry environment carrier specification.
"
Class {
	#name : 'OTEnvironmentVariableTextMapSetter',
	#superclass : 'Object',
	#classVars : [
		'Current'
	],
	#category : 'OpenTelemetry-Instrumentation',
	#package : 'OpenTelemetry-Instrumentation'
}

{ #category : 'accessing' }
OTEnvironmentVariableTextMapSetter class >> current [

	^ Current ifNil: [ Current := self new ]
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

	^ aCharacter = $_ or: [ aCharacter isUppercase and: [ aCharacter isLetter ] ]
]

{ #category : 'normalizing' }
OTEnvironmentVariableTextMapSetter class >> isNormalizedTrailingCharacter: aCharacter [

	^ aCharacter = $_ or: [ aCharacter isDigit or: [ aCharacter isUppercase and: [ aCharacter isLetter ] ] ]
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
	(aCharacter isDigit or: [ aCharacter = $_ ]) ifTrue: [ ^ aCharacter ].
	^ $_
]

{ #category : 'class initialization' }
OTEnvironmentVariableTextMapSetter class >> reset [

	Current := nil
]

{ #category : 'accessing' }
OTEnvironmentVariableTextMapSetter >> setIn: aCarrier key: aString value: aValue [

	(aCarrier isNil or: [ aValue isNil ]) ifTrue: [ ^ self ].
	aCarrier at: (self class normalizeKey: aString) put: aValue
]
