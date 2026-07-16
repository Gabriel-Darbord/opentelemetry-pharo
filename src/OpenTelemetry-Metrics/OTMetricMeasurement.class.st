"
A lightweight internal representation of one synchronous metric recording.
"
Class {
	#name : 'OTMetricMeasurement',
	#superclass : 'Object',
	#instVars : [
		'instrument',
		'value',
		'attributes',
		'timestamp'
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
		attributes: aCollection;
		timestamp: DateAndTime now asUTC.
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
OTMetricMeasurement >> timestamp [

	^ timestamp ifNil: [ DateAndTime now asUTC ]
]

{ #category : 'accessing' }
OTMetricMeasurement >> timestamp: aDateAndTime [

	timestamp := aDateAndTime ifNil: [ DateAndTime now asUTC ] ifNotNil: [ aDateAndTime ]
]

{ #category : 'accessing' }
OTMetricMeasurement >> value [

	^ value
]

{ #category : 'accessing' }
OTMetricMeasurement >> value: aNumber [

	value := aNumber
]

{ #category : 'copying' }
OTMetricMeasurement >> withAttributes: aCollection [

	| measurement |
	measurement := self class new.
	measurement
		instrument: self instrument;
		value: self value;
		attributes: aCollection;
		timestamp: self timestamp.
	^ measurement
]
