"
A lightweight wrapper for a synchronous metric instrument with pre-bound
attributes.
"
Class {
	#name : 'OTBoundMetricInstrument',
	#superclass : 'Object',
	#instVars : [
		'instrument',
		'attributes'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTBoundMetricInstrument class >> instrument: anOTMetricInstrument attributes: aCollection [

	| boundInstrument |
	boundInstrument := self new.
	boundInstrument
		instrument: anOTMetricInstrument;
		attributes: aCollection.
	^ boundInstrument
]

{ #category : 'recording' }
OTBoundMetricInstrument >> add: aNumber [

	^ instrument add: aNumber attributes: self attributes
]

{ #category : 'recording' }
OTBoundMetricInstrument >> add: aNumber attributes: aCollection [

	^ instrument add: aNumber attributes: (self mergedAttributesWith: aCollection)
]

{ #category : 'accessing' }
OTBoundMetricInstrument >> attributes [

	^ attributes ifNil: [ OrderedDictionary new ]
]

{ #category : 'accessing' }
OTBoundMetricInstrument >> attributes: aCollection [

	attributes := OTAttributeNormalizer normalizeAttributes: aCollection
]

{ #category : 'testing' }
OTBoundMetricInstrument >> enabled [

	^ instrument enabled
]

{ #category : 'accessing' }
OTBoundMetricInstrument >> instrument [

	^ instrument
]

{ #category : 'accessing' }
OTBoundMetricInstrument >> instrument: anOTMetricInstrument [

	instrument := anOTMetricInstrument
]

{ #category : 'private' }
OTBoundMetricInstrument >> mergedAttributesWith: aCollection [

	| merged |
	merged := OrderedCollection withAll: self attributes associations.
	merged addAll: (OTAttributeNormalizer normalizeAttributes: aCollection) associations.
	^ OTAttributeNormalizer normalizeAttributes: merged
]

{ #category : 'recording' }
OTBoundMetricInstrument >> record: aNumber [

	^ instrument record: aNumber attributes: self attributes
]

{ #category : 'recording' }
OTBoundMetricInstrument >> record: aNumber attributes: aCollection [

	^ instrument record: aNumber attributes: (self mergedAttributesWith: aCollection)
]
