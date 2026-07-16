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

{ #category : 'accessing' }
OTMetricInstrument >> unit [

	^ unit ifNil: [ '' ]
]

{ #category : 'accessing' }
OTMetricInstrument >> unit: aString [

	unit := aString
]
