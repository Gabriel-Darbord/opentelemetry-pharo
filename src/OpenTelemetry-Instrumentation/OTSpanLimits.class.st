"
Configurable limits for span attributes, events, links, and nested attribute collections.
"
Class {
	#name : 'OTSpanLimits',
	#superclass : 'Object',
	#instVars : [
		'attributeCountLimit',
		'attributeValueLengthLimit',
		'eventCountLimit',
		'linkCountLimit',
		'attributePerEventCountLimit',
		'attributePerLinkCountLimit'
	],
	#category : 'OpenTelemetry-Instrumentation',
	#package : 'OpenTelemetry-Instrumentation'
}

{ #category : 'instance creation' }
OTSpanLimits class >> default [

	^ self new
]

{ #category : 'comparing' }
OTSpanLimits >> = anObject [

	self == anObject ifTrue: [ ^ true ].
	anObject class = self class ifFalse: [ ^ false ].
	^ attributeCountLimit = anObject attributeCountLimit and: [
			  attributeValueLengthLimit = anObject attributeValueLengthLimit and: [
					  eventCountLimit = anObject eventCountLimit and: [
							  linkCountLimit = anObject linkCountLimit and: [
									  attributePerEventCountLimit = anObject attributePerEventCountLimit and: [
										  attributePerLinkCountLimit = anObject attributePerLinkCountLimit ] ] ] ] ]
]

{ #category : 'accessing' }
OTSpanLimits >> attributeCountLimit [

	^ attributeCountLimit
]

{ #category : 'accessing' }
OTSpanLimits >> attributeCountLimit: anInteger [

	attributeCountLimit := self normalizedLimit: anInteger allowNil: false.
	^ attributeCountLimit
]

{ #category : 'accessing' }
OTSpanLimits >> attributePerEventCountLimit [

	^ attributePerEventCountLimit
]

{ #category : 'accessing' }
OTSpanLimits >> attributePerEventCountLimit: anInteger [

	attributePerEventCountLimit := self normalizedLimit: anInteger allowNil: false.
	^ attributePerEventCountLimit
]

{ #category : 'accessing' }
OTSpanLimits >> attributePerLinkCountLimit [

	^ attributePerLinkCountLimit
]

{ #category : 'accessing' }
OTSpanLimits >> attributePerLinkCountLimit: anInteger [

	attributePerLinkCountLimit := self normalizedLimit: anInteger allowNil: false.
	^ attributePerLinkCountLimit
]

{ #category : 'accessing' }
OTSpanLimits >> attributeValueLengthLimit [

	^ attributeValueLengthLimit
]

{ #category : 'accessing' }
OTSpanLimits >> attributeValueLengthLimit: anInteger [

	attributeValueLengthLimit := self normalizedLimit: anInteger allowNil: true.
	^ attributeValueLengthLimit
]

{ #category : 'accessing' }
OTSpanLimits >> eventCountLimit [

	^ eventCountLimit
]

{ #category : 'accessing' }
OTSpanLimits >> eventCountLimit: anInteger [

	eventCountLimit := self normalizedLimit: anInteger allowNil: false.
	^ eventCountLimit
]

{ #category : 'comparing' }
OTSpanLimits >> hash [

	^ {
		  attributeCountLimit.
		  attributeValueLengthLimit.
		  eventCountLimit.
		  linkCountLimit.
		  attributePerEventCountLimit.
		  attributePerLinkCountLimit } hash
]

{ #category : 'initialization' }
OTSpanLimits >> initialize [

	super initialize.
	attributeCountLimit := 128.
	attributeValueLengthLimit := nil.
	eventCountLimit := 128.
	linkCountLimit := 128.
	attributePerEventCountLimit := 128.
	attributePerLinkCountLimit := 128
]

{ #category : 'accessing' }
OTSpanLimits >> linkCountLimit [

	^ linkCountLimit
]

{ #category : 'accessing' }
OTSpanLimits >> linkCountLimit: anInteger [

	linkCountLimit := self normalizedLimit: anInteger allowNil: false.
	^ linkCountLimit
]

{ #category : 'private' }
OTSpanLimits >> normalizedLimit: aNumber allowNil: aBoolean [

	aNumber ifNil: [
			aBoolean ifTrue: [ ^ nil ].
			Error signal: 'OpenTelemetry limits must be non-negative integers' ].
	(aNumber isInteger and: [ aNumber >= 0 ]) ifFalse: [ Error signal: 'OpenTelemetry limits must be non-negative integers' ].
	^ aNumber
]

{ #category : 'copying' }
OTSpanLimits >> postCopy [

	super postCopy.
	attributeCountLimit := attributeCountLimit copy.
	attributeValueLengthLimit := attributeValueLengthLimit ifNil: [ nil ] ifNotNil: [ attributeValueLengthLimit copy ].
	eventCountLimit := eventCountLimit copy.
	linkCountLimit := linkCountLimit copy.
	attributePerEventCountLimit := attributePerEventCountLimit copy.
	attributePerLinkCountLimit := attributePerLinkCountLimit copy
]
