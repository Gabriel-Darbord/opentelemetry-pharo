Class {
	#name : 'OTNumberDataPoint',
	#superclass : 'Object',
	#instVars : [
		'attributes',
		'value'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTNumberDataPoint class >> attributes: aCollection value: aNumber [

	| point |
	point := self new.
	point
		attributes: aCollection;
		value: aNumber.
	^ point
]

{ #category : 'accessing' }
OTNumberDataPoint >> attributes [

	^ attributes ifNil: [ OrderedDictionary new ]
]

{ #category : 'accessing' }
OTNumberDataPoint >> attributes: aCollection [

	attributes := OTAttributeNormalizer normalizeAttributes: aCollection
]

{ #category : 'accessing' }
OTNumberDataPoint >> value [

	^ value
]

{ #category : 'accessing' }
OTNumberDataPoint >> value: aNumber [

	value := aNumber
]
