"
An immutable baggage entry with a value and optional opaque metadata.
"
Class {
	#name : 'OTBaggageEntry',
	#superclass : 'Object',
	#instVars : [
		'value',
		'metadata'
	],
	#category : 'OpenTelemetry-Instrumentation',
	#package : 'OpenTelemetry-Instrumentation'
}

{ #category : 'instance creation' }
OTBaggageEntry class >> value: aString [

	^ self value: aString metadata: nil
]

{ #category : 'instance creation' }
OTBaggageEntry class >> value: aString metadata: aMetadataObject [

	^ self new
		value: aString;
		metadata: aMetadataObject;
		yourself
]

{ #category : 'comparing' }
OTBaggageEntry >> = anObject [

	self == anObject ifTrue: [ ^ true ].
	self class = anObject class ifFalse: [ ^ false ].
	^ value = anObject value
		and: [ metadata = anObject metadata ]
]

{ #category : 'testing' }
OTBaggageEntry >> hasMetadata [

	^ self metadata isEmpty not
]

{ #category : 'comparing' }
OTBaggageEntry >> hash [

	^ value hash bitXor: metadata hash
]

{ #category : 'accessing' }
OTBaggageEntry >> metadata [

	^ metadata ifNil: [ OTBaggageMetadata empty ]
]

{ #category : 'accessing' }
OTBaggageEntry >> metadata: anObject [

	metadata := OTBaggageMetadata from: anObject
]

{ #category : 'accessing' }
OTBaggageEntry >> value [

	^ value
]

{ #category : 'accessing' }
OTBaggageEntry >> value: aString [

	value := aString
]
