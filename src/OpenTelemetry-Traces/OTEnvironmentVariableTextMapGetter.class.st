"
A stateless getter for environment-variable carriers that normalizes propagation keys per the OpenTelemetry environment carrier specification.
"
Class {
	#name : 'OTEnvironmentVariableTextMapGetter',
	#superclass : 'Object',
	#classVars : [
		'Current'
	],
	#category : 'OpenTelemetry-Traces',
	#package : 'OpenTelemetry-Traces'
}

{ #category : 'accessing' }
OTEnvironmentVariableTextMapGetter class >> current [

	^ OTClassStateStore currentValueForClass: self ifAbsentPut: [ self new ]
]

{ #category : 'class initialization' }
OTEnvironmentVariableTextMapGetter class >> reset [

	OTClassStateStore removeCurrentValueForClass: self ifAbsent: [ ]
]

{ #category : 'accessing' }
OTEnvironmentVariableTextMapGetter >> getAllFrom: aCarrier key: aString [

	| value |
	value := self getFrom: aCarrier key: aString.
	^ value ifNil: [ #(  ) ] ifNotNil: [ { value } ]
]

{ #category : 'accessing' }
OTEnvironmentVariableTextMapGetter >> getFrom: aCarrier key: aString [

	| normalizedKey |
	(aCarrier isNil or: [ aString isNil ]) ifTrue: [ ^ nil ].
	normalizedKey := OTEnvironmentVariableTextMapSetter normalizeKey: aString.
	^ aCarrier at: normalizedKey ifAbsent: [ nil ]
]

{ #category : 'accessing' }
OTEnvironmentVariableTextMapGetter >> keysFrom: aCarrier [

	^ self keysIn: aCarrier
]

{ #category : 'accessing' }
OTEnvironmentVariableTextMapGetter >> keysIn: aCarrier [

	aCarrier ifNil: [ ^ #(  ) ].
	^ aCarrier keys select: [ :each | OTEnvironmentVariableTextMapSetter isNormalizedKey: each asString ]
]
