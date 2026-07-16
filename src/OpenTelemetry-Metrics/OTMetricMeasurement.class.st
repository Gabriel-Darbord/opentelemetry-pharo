"
A lightweight internal representation of one synchronous metric recording.
"
Class {
	#name : 'OTMetricMeasurement',
	#superclass : 'Object',
	#instVars : [
		'instrument',
		'value',
		'attributes'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTMetricMeasurement class >> instrument: anOTMetricInstrument value: aNumber attributes: aCollection [

	| measurement |
	measurement := self new.
	measurement
		instrument: anOTMetricInstrument;
		value: aNumber;
		attributes: aCollection.
	^ measurement
]

{ #category : 'accessing' }
OTMetricMeasurement >> attributes [

	^ attributes ifNil: [ OrderedDictionary new ]
]

{ #category : 'accessing' }
OTMetricMeasurement >> attributes: aCollection [

	attributes := OTAttributeNormalizer normalizeAttributes: aCollection
]

{ #category : 'accessing' }
OTMetricMeasurement >> instrument [

	^ instrument
]

{ #category : 'accessing' }
OTMetricMeasurement >> instrument: anOTMetricInstrument [

	instrument := anOTMetricInstrument
]

{ #category : 'accessing' }
OTMetricMeasurement >> value [

	^ value
]

{ #category : 'accessing' }
OTMetricMeasurement >> value: aNumber [

	value := aNumber
]
