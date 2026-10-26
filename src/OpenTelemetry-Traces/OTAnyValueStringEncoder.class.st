"
I encode AnyValue strings and JSON attribute collections for non-OTLP protocols.
"
Class {
	#name : 'OTAnyValueStringEncoder',
	#superclass : 'Object',
	#category : 'OpenTelemetry-Traces',
	#package : 'OpenTelemetry-Traces'
}

{ #category : 'encoding' }
OTAnyValueStringEncoder class >> jsonDoubleValueFor: aNumber [

	| value |
	value := aNumber asFloat.
	value isNaN ifTrue: [ ^ 'NaN' ].
	value isInfinite ifTrue: [
			^ value > 0
				  ifTrue: [ 'Infinity' ]
				  ifFalse: [ '-Infinity' ] ].
	^ value
]

{ #category : 'encoding' }
OTAnyValueStringEncoder class >> jsonValueFor: anObject [

	anObject ifNil: [ ^ nil ].
	(anObject isString or: [ anObject isSymbol ]) ifTrue: [ ^ anObject asString ].
	(OTAttributeNormalizer isBoolean: anObject) ifTrue: [ ^ anObject ].
	anObject isInteger ifTrue: [ ^ anObject ].
	anObject isNumber ifTrue: [ ^ self jsonDoubleValueFor: anObject ].
	(anObject isKindOf: ByteArray) ifTrue: [ ^ anObject base64Encoded ].
	(OTAttributeNormalizer isMapValue: anObject) ifTrue: [
			| values |
			values := OrderedDictionary new.
			anObject associationsDo: [ :each | values at: each key asString put: (self jsonValueFor: each value) ].
			^ values ].
	anObject isCollection ifTrue: [ ^ anObject collect: [ :each | self jsonValueFor: each ] as: Array ].
	Error signal: 'Unsupported OpenTelemetry AnyValue'
]

{ #category : 'encoding' }
OTAnyValueStringEncoder class >> stringFor: anObject [

	anObject ifNil: [ ^ '' ].
	(anObject isString or: [ anObject isSymbol ]) ifTrue: [ ^ anObject asString ].
	(anObject isKindOf: ByteArray) ifTrue: [ ^ anObject base64Encoded ].
	anObject isNumber ifTrue: [ ^ (self jsonValueFor: anObject) asString ].
	(OTAttributeNormalizer isBoolean: anObject) ifTrue: [ ^ anObject printString ].
	^ STONJSON toString: (self jsonValueFor: anObject)
]
