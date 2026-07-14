"
A stateless case-insensitive getter for dictionary-like text-map carriers.
"
Class {
	#name : 'OTDictionaryTextMapGetter',
	#superclass : 'Object',
	#classVars : [
		'Current'
	],
	#category : 'OpenTelemetry-Instrumentation',
	#package : 'OpenTelemetry-Instrumentation'
}

{ #category : 'accessing' }
OTDictionaryTextMapGetter class >> current [

	^ Current ifNil: [ Current := self new ]
]

{ #category : 'class initialization' }
OTDictionaryTextMapGetter class >> reset [

	Current := nil
]

{ #category : 'private' }
OTDictionaryTextMapGetter >> addHeaderValuesFrom: anObject to: aCollection [

	anObject ifNil: [ ^ self ].
	(anObject isString or: [ anObject isSymbol ]) ifTrue: [
		aCollection add: anObject asString.
		^ self ].
	anObject isCollection ifTrue: [
		anObject do: [ :each |
			each ifNotNil: [ aCollection add: each asString ] ].
		^ self ].
	aCollection add: anObject asString
]

{ #category : 'accessing' }
OTDictionaryTextMapGetter >> getAllFrom: aCarrier key: aString [

	| expectedKey values |
	aCarrier ifNil: [ ^ #() ].
	expectedKey := aString asString asLowercase.
	values := OrderedCollection new.
	aCarrier keysAndValuesDo: [ :eachKey :eachValue |
		(eachKey asString asLowercase = expectedKey) ifTrue: [
			self addHeaderValuesFrom: eachValue to: values ] ].
	^ values asArray
]

{ #category : 'accessing' }
OTDictionaryTextMapGetter >> getFrom: aCarrier key: aString [

	| expectedKey |
	aCarrier ifNil: [ ^ nil ].
	expectedKey := aString asString asLowercase.
	aCarrier keysAndValuesDo: [ :eachKey :eachValue |
		(eachKey asString asLowercase = expectedKey) ifTrue: [ ^ eachValue ] ].
	^ nil
]

{ #category : 'accessing' }
OTDictionaryTextMapGetter >> keysIn: aCarrier [

	aCarrier ifNil: [ ^ #() ].
	^ aCarrier keys collect: [ :each | each asString ]
]
