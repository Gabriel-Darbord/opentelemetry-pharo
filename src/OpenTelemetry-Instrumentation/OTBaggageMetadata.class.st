"
An opaque wrapper for baggage metadata strings.
"
Class {
	#name : 'OTBaggageMetadata',
	#superclass : 'Object',
	#instVars : [
		'value'
	],
	#category : 'OpenTelemetry-Instrumentation',
	#package : 'OpenTelemetry-Instrumentation'
}

{ #category : 'instance creation' }
OTBaggageMetadata class >> empty [

	^ self value: ''
]

{ #category : 'instance creation' }
OTBaggageMetadata class >> from: anObject [

	anObject ifNil: [ ^ self empty ].
	anObject class = self ifTrue: [ ^ anObject ].
	^ self value: anObject asString
]

{ #category : 'instance creation' }
OTBaggageMetadata class >> value: aString [

	^ self new
		  value: (aString ifNil: [ '' ]);
		  yourself
]

{ #category : 'comparing' }
OTBaggageMetadata >> = anObject [

	self == anObject ifTrue: [ ^ true ].
	self class = anObject class ifFalse: [ ^ false ].
	^ value = anObject value
]

{ #category : 'printing' }
OTBaggageMetadata >> asString [

	^ value
]

{ #category : 'comparing' }
OTBaggageMetadata >> hash [

	^ value hash
]

{ #category : 'testing' }
OTBaggageMetadata >> isEmpty [

	^ value isEmpty
]

{ #category : 'accessing' }
OTBaggageMetadata >> value [

	^ value
]

{ #category : 'accessing' }
OTBaggageMetadata >> value: aString [

	value := aString ifNil: [ '' ]
]
