"
Configurable limits for log-record attributes.
"
Class {
	#name : 'OTLogRecordLimits',
	#superclass : 'Object',
	#instVars : [
		'attributeCountLimit',
		'attributeValueDepthLimit',
		'attributeValueLengthLimit'
	],
	#category : 'OpenTelemetry-Logs',
	#package : 'OpenTelemetry-Logs'
}

{ #category : 'instance creation' }
OTLogRecordLimits class >> default [

	^ self new
]

{ #category : 'comparing' }
OTLogRecordLimits >> = anObject [

	self == anObject ifTrue: [ ^ true ].
	anObject class = self class ifFalse: [ ^ false ].
	^ self attributeValueDepthLimit = anObject attributeValueDepthLimit and: [
		  attributeCountLimit = anObject attributeCountLimit and: [ attributeValueLengthLimit = anObject attributeValueLengthLimit ] ]
]

{ #category : 'accessing' }
OTLogRecordLimits >> attributeCountLimit [

	^ attributeCountLimit
]

{ #category : 'accessing' }
OTLogRecordLimits >> attributeCountLimit: anInteger [

	attributeCountLimit := self normalizedLimit: anInteger allowNil: false.
	^ attributeCountLimit
]

{ #category : 'accessing' }
OTLogRecordLimits >> attributeValueDepthLimit [

	^ attributeValueDepthLimit ifNil: [ 64 ]
]

{ #category : 'accessing' }
OTLogRecordLimits >> attributeValueDepthLimit: anInteger [

	attributeValueDepthLimit := self normalizedLimit: anInteger allowNil: false.
	^ attributeValueDepthLimit
]

{ #category : 'accessing' }
OTLogRecordLimits >> attributeValueLengthLimit [

	^ attributeValueLengthLimit
]

{ #category : 'accessing' }
OTLogRecordLimits >> attributeValueLengthLimit: anInteger [

	attributeValueLengthLimit := self normalizedLimit: anInteger allowNil: true.
	^ attributeValueLengthLimit
]

{ #category : 'comparing' }
OTLogRecordLimits >> hash [

	^ {
		  attributeCountLimit.
		  attributeValueLengthLimit.
		  self attributeValueDepthLimit } hash
]

{ #category : 'initialization' }
OTLogRecordLimits >> initialize [

	super initialize.
	attributeCountLimit := 128.
	attributeValueDepthLimit := 64.
	attributeValueLengthLimit := nil
]

{ #category : 'private' }
OTLogRecordLimits >> normalizedLimit: aNumber allowNil: aBoolean [

	aNumber ifNil: [
			aBoolean ifTrue: [ ^ nil ].
			Error signal: 'OpenTelemetry limits must be non-negative integers' ].
	(aNumber isInteger and: [ aNumber >= 0 ]) ifFalse: [ Error signal: 'OpenTelemetry limits must be non-negative integers' ].
	^ aNumber
]

{ #category : 'copying' }
OTLogRecordLimits >> postCopy [

	super postCopy.
	attributeCountLimit := attributeCountLimit copy.
	attributeValueLengthLimit := attributeValueLengthLimit ifNotNil: [ attributeValueLengthLimit copy ]
]
