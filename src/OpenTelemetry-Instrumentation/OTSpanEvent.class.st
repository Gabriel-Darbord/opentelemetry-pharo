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

	| event eventName timestamp |
	event := self newInternal.
	eventName := (aString isString or: [ aString isSymbol ])
		             ifTrue: [ aString asString ]
		             ifFalse: [
				             aString ifNotNil: [
					             OTSpan noteIgnoredInvalidArgument: aString forOperation: 'OTSpanEvent class>>named:attributes:timestamp:' ].
				             '' ].
	timestamp := OTSpan
		             normalizedTimestamp: aDateAndTime
		             forOperation: 'OTSpanEvent class>>named:attributes:timestamp:'
		             default: [ DateAndTime now ].
	event
		restoreName: eventName;
		restoreTimestamp: timestamp.
	[ event restoreAttributes: aCollection ]
		on: Error
		do: [
				OTSpan noteIgnoredInvalidArgument: aCollection forOperation: 'OTSpanEvent class>>named:attributes:timestamp:'.
				event restoreAttributes: #(  ) ].
	^ event
]

{ #category : 'instance creation' }
OTSpanEvent class >> named: aString attributes: aCollection timestamp: aDateAndTime droppedAttributesCount: anInteger [

	| event |
	event := self named: aString attributes: aCollection timestamp: aDateAndTime.
	event restoreDroppedAttributesCount: anInteger.
	^ event
]

{ #category : 'instance creation' }
OTSpanEvent class >> new [

	Error signal: 'Span events are immutable. Use OTSpanEvent class-side constructors.'
]

{ #category : 'private' }
OTSpanEvent class >> newInternal [

	^ super new
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

	^ OTAttributeNormalizer normalizeAttributes: attributes
]

{ #category : 'accessing' }
OTSpanEvent >> droppedAttributesCount [

	^ droppedAttributesCount ifNil: [ 0 ]
]

{ #category : 'comparing' }
OTSpanEvent >> hash [

	^ { self name. self timestamp. self attributes. self droppedAttributesCount } hash
]

{ #category : 'accessing' }
OTSpanEvent >> name [

	^ name ifNil: [ '' ]
]

{ #category : 'printing' }
OTSpanEvent >> printOn: aStream [

	aStream nextPutAll: 'SpanEvent['.
	aStream nextPutAll: self name.
	aStream nextPut: $]
]

{ #category : 'private' }
OTSpanEvent >> restoreAttributes: aCollection [

	attributes := OTAttributeNormalizer normalizeAttributes: aCollection
]

{ #category : 'private' }
OTSpanEvent >> restoreDroppedAttributesCount: anInteger [

	droppedAttributesCount := anInteger ifNil: [ 0 ] ifNotNil: [ anInteger ]
]

{ #category : 'private' }
OTSpanEvent >> restoreName: aString [

	name := aString
]

{ #category : 'private' }
OTSpanEvent >> restoreTimestamp: aDateAndTime [

	timestamp := aDateAndTime
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
