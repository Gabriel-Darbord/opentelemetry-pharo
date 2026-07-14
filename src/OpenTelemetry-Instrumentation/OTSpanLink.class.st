"
An immutable link to another span context with optional attributes.
"
Class {
	#name : 'OTSpanLink',
	#superclass : 'Object',
	#instVars : [
		'spanContext',
		'attributes',
		'droppedAttributesCount'
	],
	#category : 'OpenTelemetry-Instrumentation',
	#package : 'OpenTelemetry-Instrumentation'
}

{ #category : 'ston persistence' }
OTSpanLink class >> fromSton: stonReader [

	| representation |
	representation := stonReader parseMap.
	^ self
		spanContext: (representation at: #spanContext)
		attributes: (representation at: #attributes ifAbsent: [ #() ])
		droppedAttributesCount: (representation at: #droppedAttributesCount ifAbsent: [ 0 ])
]

{ #category : 'instance creation' }
OTSpanLink class >> spanContext: aSpanContext [

	^ self spanContext: aSpanContext attributes: nil
]

{ #category : 'instance creation' }
OTSpanLink class >> span: aSpan [

	^ self span: aSpan attributes: nil
]

{ #category : 'instance creation' }
OTSpanLink class >> span: aSpan attributes: aDictionary [

	^ self spanContext: (self spanContextFrom: aSpan) attributes: aDictionary
]

{ #category : 'private' }
OTSpanLink class >> spanContextFrom: anObject [

	anObject ifNil: [ Error signal: 'OpenTelemetry links require a span or span context' ].
	^ [ anObject asSpanContext ]
		on: MessageNotUnderstood
		do: [ Error signal: 'OpenTelemetry links require a span or span context' ]
]

{ #category : 'instance creation' }
OTSpanLink class >> spanContext: aSpanContext attributes: aDictionary [

	^ self new
		spanContext: aSpanContext;
		attributes: aDictionary;
		yourself
]

{ #category : 'instance creation' }
OTSpanLink class >> spanContext: aSpanContext attributes: aDictionary droppedAttributesCount: anInteger [

	^ self new
		spanContext: aSpanContext;
		attributes: aDictionary;
		droppedAttributesCount: anInteger;
		yourself
]

{ #category : 'comparing' }
OTSpanLink >> = anObject [

	self == anObject ifTrue: [ ^ true ].
	self class = anObject class ifFalse: [ ^ false ].
	^ spanContext = anObject spanContext
		and: [ self attributes = anObject attributes
		and: [ self droppedAttributesCount = anObject droppedAttributesCount ] ]
]

{ #category : 'accessing' }
OTSpanLink >> attributes [

	^ attributes ifNil: [ #() ]
]

{ #category : 'accessing' }
OTSpanLink >> attributes: aDictionary [

	attributes := OTAttributeNormalizer normalizeAttributes: aDictionary
]

{ #category : 'accessing' }
OTSpanLink >> droppedAttributesCount [

	^ droppedAttributesCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
OTSpanLink >> droppedAttributesCount: anInteger [

	droppedAttributesCount := anInteger ifNil: [ 0 ] ifNotNil: [ anInteger ]
]

{ #category : 'comparing' }
OTSpanLink >> hash [

	^ { spanContext. self attributes. self droppedAttributesCount } hash
]

{ #category : 'accessing' }
OTSpanLink >> spanContext [

	^ spanContext
]

{ #category : 'accessing' }
OTSpanLink >> spanContext: aSpanContext [

	spanContext := self class spanContextFrom: aSpanContext
]

{ #category : 'ston persistence' }
OTSpanLink >> stonOn: stonWriter [

	stonWriter writeObject: self streamMap: [ :map |
		map at: #spanContext put: self spanContext.
		self attributes ifNotEmpty: [ map at: #attributes put: self attributes ].
		self droppedAttributesCount > 0 ifTrue: [
			map at: #droppedAttributesCount put: self droppedAttributesCount ] ]
]

{ #category : 'copying' }
OTSpanLink >> withAttributeCountLimit: aCountLimit valueLengthLimit: aLengthLimit [

	| result |
	result := OTAttributeNormalizer normalizeAttributes: self attributes countLimit: aCountLimit valueLengthLimit: aLengthLimit.
	^ self class
		spanContext: self spanContext
		attributes: result first
		droppedAttributesCount: self droppedAttributesCount + result second
]
