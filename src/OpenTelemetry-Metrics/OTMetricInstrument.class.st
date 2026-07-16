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
		'advice'
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
		advice: aDictionary.
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

{ #category : 'binding' }
OTMetricInstrument >> bind: aCollection [

	self
]

{ #category : 'collecting' }
OTMetricInstrument >> collectFor: anOTMetricReader into: aCollection [

	self
]

{ #category : 'aggregating' }
OTMetricInstrument >> groupedMeasurementsByAttributes: someMeasurements [

	| grouped |
	grouped := OrderedDictionary new.
	someMeasurements do: [ :each |
		(grouped
			at: (self normalizedAttributesForMeasurement: each)
			ifAbsentPut: [ OrderedCollection new ])
			add: each ].
	^ grouped
]

{ #category : 'accessing' }
OTMetricInstrument >> instrumentationScope [

	^ self meter
		ifNil: [ OTInstrumentationScope named: '' ]
		ifNotNil: [ :aMeter | aMeter instrumentationScope ]
]

{ #category : 'aggregating' }
OTMetricInstrument >> metricDataFromMeasurements: someMeasurements [

	^ self
		metricDataFromMeasurements: someMeasurements
		collectedAt: DateAndTime now asUTC
]

{ #category : 'aggregating' }
OTMetricInstrument >> metricDataFromMeasurements: someMeasurements collectedAt: aDateAndTime [

	self subclassResponsibility
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

{ #category : 'accessing' }
OTMetricInstrument >> meter [

	^ meter
]

{ #category : 'accessing' }
OTMetricInstrument >> meter: anOTMeter [

	meter := anOTMeter
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

	| normalized retainedKeys |
	normalized := OTAttributeNormalizer normalizeAttributes: anOTMetricMeasurement attributes.
	retainedKeys := self retainedAttributeKeys.
	retainedKeys ifNil: [ ^ normalized ].
	^ retainedKeys inject: OrderedDictionary new into: [ :selected :each |
		normalized
			at: each asString
			ifPresent: [ :value | selected at: each asString put: value ].
		selected ]
]

{ #category : 'aggregating' }
OTMetricInstrument >> retainedAttributeKeys [

	^ self advice
		at: 'Attributes'
		ifAbsent: [ self advice at: 'attributes' ifAbsent: [ nil ] ]
]

{ #category : 'accessing' }
OTMetricInstrument >> unit [

	^ unit ifNil: [ '' ]
]

{ #category : 'accessing' }
OTMetricInstrument >> unit: aString [

	unit := aString
]
