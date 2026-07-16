Class {
	#name : 'OTMetricExemplar',
	#superclass : 'Object',
	#instVars : [
		'value',
		'timestamp',
		'filteredAttributes',
		'traceId',
		'spanId'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTMetricExemplar class >> measurement: anOTMetricMeasurement pointAttributes: aCollection [

	| exemplar measurementAttributes pointAttributes |
	exemplar := self new.
	measurementAttributes := OTAttributeNormalizer
		normalizeAttributes: anOTMetricMeasurement exemplarAttributes.
	pointAttributes := OTAttributeNormalizer normalizeAttributes: aCollection.
	exemplar
		value: anOTMetricMeasurement value;
		timestamp: anOTMetricMeasurement timestamp;
		filteredAttributes:
			(self
				filteredAttributesFrom: measurementAttributes
				pointAttributes: pointAttributes);
		traceId: anOTMetricMeasurement exemplarTraceId;
		spanId: anOTMetricMeasurement exemplarSpanId.
	^ exemplar
]

{ #category : 'private' }
OTMetricExemplar class >> filteredAttributesFrom: someMeasurementAttributes pointAttributes: somePointAttributes [

	| filtered |
	filtered := OrderedDictionary new.
	someMeasurementAttributes associationsDo: [ :each |
		(somePointAttributes includesKey: each key) ifFalse: [
			filtered at: each key put: each value ] ].
	^ filtered
]

{ #category : 'accessing' }
OTMetricExemplar >> filteredAttributes [

	^ filteredAttributes ifNil: [ OrderedDictionary new ]
]

{ #category : 'accessing' }
OTMetricExemplar >> filteredAttributes: aCollection [

	filteredAttributes := OTAttributeNormalizer normalizeAttributes: aCollection
]

{ #category : 'accessing' }
OTMetricExemplar >> spanId [

	^ spanId
]

{ #category : 'accessing' }
OTMetricExemplar >> spanId: aString [

	spanId := aString ifNil: [ nil ] ifNotNil: [ aString asString ]
]

{ #category : 'accessing' }
OTMetricExemplar >> timestamp [

	^ timestamp
]

{ #category : 'accessing' }
OTMetricExemplar >> timestamp: aDateAndTime [

	timestamp := aDateAndTime
]

{ #category : 'accessing' }
OTMetricExemplar >> traceId [

	^ traceId
]

{ #category : 'accessing' }
OTMetricExemplar >> traceId: aString [

	traceId := aString ifNil: [ nil ] ifNotNil: [ aString asString ]
]

{ #category : 'accessing' }
OTMetricExemplar >> value [

	^ value
]

{ #category : 'accessing' }
OTMetricExemplar >> value: aNumber [

	value := aNumber
]
