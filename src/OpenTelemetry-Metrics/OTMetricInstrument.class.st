"
Abstract no-op metric instrument foundation.
"
Class {
	#name : 'OTMetricInstrument',
	#superclass : 'Object',
	#instVars : [
		'meter',
		'name',
		'unit',
		'description',
		'advice',
		'creationTimestamp'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTMetricInstrument class >> forMeter: anOTMeter name: aString unit: aUnitString description: aDescriptionString advice: aDictionary [

	| instrument |
	instrument := self new.
	instrument
		meter: anOTMeter;
		name: aString;
		unit: aUnitString;
		description: aDescriptionString;
		advice: aDictionary;
		creationTimestamp: DateAndTime now asUTC.
	^ instrument
]

{ #category : 'accessing' }
OTMetricInstrument >> advice [

	^ advice ifNil: [ Dictionary new ]
]

{ #category : 'accessing' }
OTMetricInstrument >> advice: aDictionary [

	advice := aDictionary
]

{ #category : 'aggregating' }
OTMetricInstrument >> attributeFilter [

	^ OTMetricAttributeFilter included: self retainedAttributeKeys excluded: nil
]

{ #category : 'binding' }
OTMetricInstrument >> bind: aCollection [

	self
]

{ #category : 'collecting' }
OTMetricInstrument >> collectFor: anOTMetricReader into: aCollection [

	self
]

{ #category : 'accessing' }
OTMetricInstrument >> creationTimestamp [

	^ creationTimestamp ifNil: [ DateAndTime now asUTC ]
]

{ #category : 'accessing' }
OTMetricInstrument >> creationTimestamp: aDateAndTime [

	creationTimestamp := aDateAndTime ifNil: [ DateAndTime now asUTC ] ifNotNil: [ aDateAndTime ]
]

{ #category : 'accessing' }
OTMetricInstrument >> description [

	^ description ifNil: [ '' ]
]

{ #category : 'accessing' }
OTMetricInstrument >> description: aString [

	description := aString
]

{ #category : 'testing' }
OTMetricInstrument >> enabled [

	^ false
]

{ #category : 'aggregating' }
OTMetricInstrument >> exemplarsFromMeasurements: someMeasurements pointAttributes: aCollection using: anOTMetricAggregationContext [

	| reservoir |
	reservoir := anOTMetricAggregationContext newExemplarReservoirForInstrument: self pointAttributes: aCollection.
	someMeasurements do: [ :each | reservoir offerMeasurement: each ].
	^ reservoir collectForPointAttributes: aCollection
]

{ #category : 'aggregating' }
OTMetricInstrument >> groupedMeasurementsByAttributes: someMeasurements [

	| grouped |
	grouped := OrderedDictionary new.
	someMeasurements do: [ :each |
		(grouped at: (self normalizedAttributesForMeasurement: each) ifAbsentPut: [ OrderedCollection new ]) add: each ].
	^ grouped
]

{ #category : 'accessing' }
OTMetricInstrument >> instrumentType [

	self subclassResponsibility
]

{ #category : 'accessing' }
OTMetricInstrument >> instrumentationScope [

	^ self meter ifNil: [ OTInstrumentationScope named: '' ] ifNotNil: [ :aMeter | aMeter instrumentationScope ]
]

{ #category : 'accessing' }
OTMetricInstrument >> meter [

	^ meter
]

{ #category : 'accessing' }
OTMetricInstrument >> meter: anOTMeter [

	meter := anOTMeter
]

{ #category : 'aggregating' }
OTMetricInstrument >> metricDataFromMeasurements: someMeasurements [

	^ self metricDataFromMeasurements: someMeasurements using: (OTMetricAggregationContext
			   collectedAt: DateAndTime now asUTC
			   startTimestamp: (someMeasurements ifEmpty: [ nil ] ifNotEmpty: [ someMeasurements first timestamp ])
			   temporality: #cumulative)
]

{ #category : 'aggregating' }
OTMetricInstrument >> metricDataFromMeasurements: someMeasurements using: anOTMetricAggregationContext [

	self subclassResponsibility
]

{ #category : 'accessing' }
OTMetricInstrument >> name [

	^ name ifNil: [ '' ]
]

{ #category : 'accessing' }
OTMetricInstrument >> name: aString [

	name := aString
]

{ #category : 'aggregating' }
OTMetricInstrument >> normalizedAttributesForMeasurement: anOTMetricMeasurement [

	^ self normalizedAttributesForMeasurement: anOTMetricMeasurement usingAttributeFilter: self attributeFilter
]

{ #category : 'aggregating' }
OTMetricInstrument >> normalizedAttributesForMeasurement: anOTMetricMeasurement retainingKeys: someKeys [

	^ self
		  normalizedAttributesForMeasurement: anOTMetricMeasurement
		  usingAttributeFilter: (OTMetricAttributeFilter included: someKeys excluded: nil)
]

{ #category : 'aggregating' }
OTMetricInstrument >> normalizedAttributesForMeasurement: anOTMetricMeasurement usingAttributeFilter: anOTMetricAttributeFilter [

	| normalized |
	normalized := OTAttributeNormalizer normalizeAttributes: anOTMetricMeasurement attributes.
	anOTMetricAttributeFilter ifNil: [ ^ normalized ].
	^ anOTMetricAttributeFilter selectedAttributesFrom: normalized
]

{ #category : 'aggregating' }
OTMetricInstrument >> otlpAggregationForPreference: aSymbol [

	^ #default
]

{ #category : 'aggregating' }
OTMetricInstrument >> otlpTemporalityForCumulativePreference [

	^ #cumulative
]

{ #category : 'aggregating' }
OTMetricInstrument >> otlpTemporalityForDeltaPreference [

	^ #cumulative
]

{ #category : 'aggregating' }
OTMetricInstrument >> otlpTemporalityForLowMemoryPreference [

	^ self otlpTemporalityForCumulativePreference
]

{ #category : 'aggregating' }
OTMetricInstrument >> otlpTemporalityForPreference: aSymbol [

	aSymbol = #delta ifTrue: [ ^ self otlpTemporalityForDeltaPreference ].
	aSymbol = #lowMemory ifTrue: [ ^ self otlpTemporalityForLowMemoryPreference ].
	^ self otlpTemporalityForCumulativePreference
]

{ #category : 'collecting' }
OTMetricInstrument >> preparedMeasurementsFrom: someMeasurements forReader: anOTMetricReader using: anOTMetricAggregationContext [

	^ someMeasurements
]

{ #category : 'aggregating' }
OTMetricInstrument >> retainedAttributeKeys [

	^ self advice at: 'Attributes' ifAbsent: [ self advice at: 'attributes' ifAbsent: [ nil ] ]
]

{ #category : 'collecting' }
OTMetricInstrument >> startTimestampForPreviousCollection: aDateAndTime temporality: aTemporalitySymbol [

	^ aTemporalitySymbol = #delta
		  ifTrue: [ aDateAndTime ifNil: [ self creationTimestamp ] ]
		  ifFalse: [ nil ]
]

{ #category : 'aggregating' }
OTMetricInstrument >> supportsAggregation: aSymbol [

	^ aSymbol = #default or: [ aSymbol = #drop ]
]

{ #category : 'accessing' }
OTMetricInstrument >> unit [

	^ unit ifNil: [ '' ]
]

{ #category : 'accessing' }
OTMetricInstrument >> unit: aString [

	unit := aString
]
