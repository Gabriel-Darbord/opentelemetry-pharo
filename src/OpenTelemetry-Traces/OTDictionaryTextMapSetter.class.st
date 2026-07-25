"
A stateless setter for dictionary-like text-map carriers.
"
Class {
	#name : 'OTDictionaryTextMapSetter',
	#superclass : 'Object',
	#classVars : [
		'Current'
	],
	#category : 'OpenTelemetry-Traces',
	#package : 'OpenTelemetry-Traces'
}

{ #category : 'accessing' }
OTDictionaryTextMapSetter class >> current [

	^ OTClassStateStore currentValueForClass: self ifAbsentPut: [ self new ]
]

{ #category : 'class initialization' }
OTDictionaryTextMapSetter class >> reset [

	OTClassStateStore removeCurrentValueForClass: self ifAbsent: [ ]
]

{ #category : 'accessing' }
OTDictionaryTextMapSetter >> setIn: aCarrier key: aString value: aValue [

	aCarrier ifNil: [ ^ self ].
	aCarrier at: aString put: aValue
]
