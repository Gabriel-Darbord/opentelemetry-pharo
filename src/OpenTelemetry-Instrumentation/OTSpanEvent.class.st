"
A timestamped span event with optional attributes.
"
Class {
	#name : 'OTSpanEvent',
	#superclass : 'Object',
	#instVars : [
		'name',
		'timestamp',
		'attributes',
		'droppedAttributesCount'
	],
	#category : 'OpenTelemetry-Instrumentation',
	#package : 'OpenTelemetry-Instrumentation'
}

{ #category : 'ston persistence' }
OTSpanEvent class >> fromSton: stonReader [

	| representation |
	representation := stonReader parseMap.
	^ self
		named: (representation at: #name ifAbsent: [ '' ])
		attributes: (representation at: #attributes ifAbsent: [ #() ])
		timestamp: (representation at: #timestamp ifAbsent: [ DateAndTime now ])
		droppedAttributesCount: (representation at: #droppedAttributesCount ifAbsent: [ 0 ])
]

{ #category : 'instance creation' }
OTSpanEvent class >> named: aString [

	^ self named: aString attributes: #() timestamp: DateAndTime now
]

{ #category : 'instance creation' }
OTSpanEvent class >> named: aString attributes: aCollection [

	^ self named: aString attributes: aCollection timestamp: DateAndTime now
]

{ #category : 'instance creation' }
OTSpanEvent class >> named: aString attributes: aCollection timestamp: aDateAndTime [

	| event |
	event := self new.
	event
		name: (aString ifNil: [ '' ] ifNotNil: [ aString ]);
		timestamp: (aDateAndTime ifNil: [ DateAndTime now ] ifNotNil: [ aDateAndTime ]);
		attributes: aCollection.
	^ event
]

{ #category : 'instance creation' }
OTSpanEvent class >> named: aString attributes: aCollection timestamp: aDateAndTime droppedAttributesCount: anInteger [

	| event |
	event := self named: aString attributes: aCollection timestamp: aDateAndTime.
	event droppedAttributesCount: anInteger.
	^ event
]

{ #category : 'comparing' }
OTSpanEvent >> = anObject [

	self == anObject ifTrue: [ ^ true ].
	anObject class = self class ifFalse: [ ^ false ].
	^ self name = anObject name
		and: [ self timestamp = anObject timestamp
		and: [ self attributes = anObject attributes
		and: [ self droppedAttributesCount = anObject droppedAttributesCount ] ] ]
]

{ #category : 'accessing' }
OTSpanEvent >> allAttributes [

	^ self attributes copy
]

{ #category : 'accessing' }
OTSpanEvent >> attributeAt: aKey [

	^ self attributeAt: aKey ifAbsent: [ nil ]
]

{ #category : 'accessing' }
OTSpanEvent >> attributeAt: aKey ifAbsent: aBlock [

	^ self attributes at: aKey ifAbsent: aBlock
]

{ #category : 'accessing' }
OTSpanEvent >> attributes [

	^ attributes ifNil: [ OrderedDictionary new ]
]

{ #category : 'accessing' }
OTSpanEvent >> attributes: aCollection [

	attributes := OTAttributeNormalizer normalizeAttributes: aCollection.
	^ self
]

{ #category : 'accessing' }
OTSpanEvent >> droppedAttributesCount [

	^ droppedAttributesCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
OTSpanEvent >> droppedAttributesCount: anInteger [

	droppedAttributesCount := anInteger ifNil: [ 0 ] ifNotNil: [ anInteger ]
]

{ #category : 'comparing' }
OTSpanEvent >> hash [

	^ { self name. self timestamp. self attributes. self droppedAttributesCount } hash
]

{ #category : 'accessing' }
OTSpanEvent >> name [

	^ name ifNil: [ '' ]
]

{ #category : 'accessing' }
OTSpanEvent >> name: aString [

	name := aString.
	^ self
]

{ #category : 'printing' }
OTSpanEvent >> printOn: aStream [

	aStream nextPutAll: 'SpanEvent['.
	aStream nextPutAll: self name.
	aStream nextPut: $]
]

{ #category : 'ston persistence' }
OTSpanEvent >> stonOn: stonWriter [

	stonWriter writeObject: self streamMap: [ :map |
		map at: #name put: self name; at: #timestamp put: self timestamp.
		self attributes ifNotEmpty: [ map at: #attributes put: self attributes ].
		self droppedAttributesCount > 0 ifTrue: [
			map at: #droppedAttributesCount put: self droppedAttributesCount ] ]
]

{ #category : 'accessing' }
OTSpanEvent >> timestamp [

	^ timestamp ifNil: [ DateAndTime now ]
]

{ #category : 'accessing' }
OTSpanEvent >> timestamp: aDateAndTime [

	timestamp := aDateAndTime.
	^ self
]

{ #category : 'copying' }
OTSpanEvent >> withAttributeCountLimit: aCountLimit valueLengthLimit: aLengthLimit [

	| result |
	result := OTAttributeNormalizer normalizeAttributes: self attributes countLimit: aCountLimit valueLengthLimit: aLengthLimit.
	^ self class
		named: self name
		attributes: result first
		timestamp: self timestamp
		droppedAttributesCount: self droppedAttributesCount + result second
]
