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
		  attributes: (representation at: #attributes ifAbsent: [ #(  ) ])
		  droppedAttributesCount: (representation at: #droppedAttributesCount ifAbsent: [ 0 ])
]

{ #category : 'instance creation' }
OTSpanLink class >> new [

	Error signal: 'Span links are immutable. Use OTSpanLink class-side constructors.'
]

{ #category : 'private' }
OTSpanLink class >> newInternal [

	^ super new
]

{ #category : 'instance creation' }
OTSpanLink class >> span: aSpan [

	^ self span: aSpan attributes: nil
]

{ #category : 'instance creation' }
OTSpanLink class >> span: aSpan attributes: aDictionary [

	^ self spanContext: (self spanContextFrom: aSpan) attributes: aDictionary
]

{ #category : 'instance creation' }
OTSpanLink class >> spanContext: aSpanContext [

	^ self spanContext: aSpanContext attributes: nil
]

{ #category : 'instance creation' }
OTSpanLink class >> spanContext: aSpanContext attributes: aDictionary [

	| link |
	link := self newInternal.
	link restoreSpanContext: aSpanContext.
	[ link restoreAttributes: aDictionary ]
		on: Error
		do: [
				OTSpan noteIgnoredInvalidArgument: aDictionary forOperation: 'OTSpanLink class>>spanContext:attributes:'.
				link restoreAttributes: #(  ) ].
	^ link yourself
]

{ #category : 'instance creation' }
OTSpanLink class >> spanContext: aSpanContext attributes: aDictionary droppedAttributesCount: anInteger [

	^ self newInternal
		  restoreSpanContext: aSpanContext;
		  restoreAttributes: aDictionary;
		  restoreDroppedAttributesCount: anInteger;
		  yourself
]

{ #category : 'private' }
OTSpanLink class >> spanContextFrom: anObject [

	anObject ifNil: [
			OTSpan noteIgnoredInvalidArgument: anObject forOperation: 'OTSpanLink class>>spanContextFrom:'.
			^ OTSpanContext invalid ].
	(anObject isKindOf: OTSpanContext) ifTrue: [ ^ anObject ].
	(anObject isKindOf: OTSpan) ifTrue: [ ^ anObject spanContext ].
	OTSpan noteIgnoredInvalidArgument: anObject forOperation: 'OTSpanLink class>>spanContextFrom:'.
	^ OTSpanContext invalid
]

{ #category : 'comparing' }
OTSpanLink >> = anObject [

	self == anObject ifTrue: [ ^ true ].
	self class = anObject class ifFalse: [ ^ false ].
	^ spanContext = anObject spanContext and: [
		  self attributes = anObject attributes and: [ self droppedAttributesCount = anObject droppedAttributesCount ] ]
]

{ #category : 'accessing' }
OTSpanLink >> attributes [

	^ OTAttributeNormalizer normalizeAttributes: attributes
]

{ #category : 'accessing' }
OTSpanLink >> droppedAttributesCount [

	^ droppedAttributesCount ifNil: [ 0 ]
]

{ #category : 'comparing' }
OTSpanLink >> hash [

	^ {
		  spanContext.
		  self attributes.
		  self droppedAttributesCount } hash
]

{ #category : 'private' }
OTSpanLink >> restoreAttributes: aDictionary [

	attributes := OTAttributeNormalizer normalizeAttributes: aDictionary
]

{ #category : 'private' }
OTSpanLink >> restoreDroppedAttributesCount: anInteger [

	droppedAttributesCount := anInteger ifNil: [ 0 ] ifNotNil: [ anInteger ]
]

{ #category : 'private' }
OTSpanLink >> restoreSpanContext: aSpanContext [

	spanContext := self class spanContextFrom: aSpanContext
]

{ #category : 'accessing' }
OTSpanLink >> spanContext [

	^ spanContext
]

{ #category : 'ston persistence' }
OTSpanLink >> stonOn: stonWriter [

	stonWriter writeObject: self streamMap: [ :map |
			map at: #spanContext put: self spanContext.
			self attributes ifNotEmpty: [ map at: #attributes put: self attributes ].
			self droppedAttributesCount > 0 ifTrue: [ map at: #droppedAttributesCount put: self droppedAttributesCount ] ]
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
