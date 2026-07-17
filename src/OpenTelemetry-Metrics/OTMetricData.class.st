Class {
	#name : 'OTMetricData',
	#superclass : 'Object',
	#instVars : [
		'instrumentationScope',
		'name',
		'description',
		'unit',
		'points',
		'metadata'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTMetricData class >> instrument: anOTMetricInstrument points: aCollection [

	| metric |
	metric := self new.
	metric
		instrumentationScope: anOTMetricInstrument instrumentationScope;
		name: anOTMetricInstrument name;
		description: anOTMetricInstrument description;
		unit: anOTMetricInstrument unit;
		points: aCollection.
	^ metric
]

{ #category : 'accessing' }
OTMetricData >> description [

	^ description ifNil: [ '' ]
]

{ #category : 'accessing' }
OTMetricData >> description: aString [

	description := aString ifNil: [ '' ] ifNotNil: [ aString ]
]

{ #category : 'accessing' }
OTMetricData >> instrumentationScope [

	^ instrumentationScope ifNil: [ OTInstrumentationScope named: '' ]
]

{ #category : 'accessing' }
OTMetricData >> instrumentationScope: anOTInstrumentationScope [

	instrumentationScope := anOTInstrumentationScope
		ifNil: [ OTInstrumentationScope named: '' ]
		ifNotNil: [ anOTInstrumentationScope ]
]

{ #category : 'accessing' }
OTMetricData >> name [

	^ name ifNil: [ '' ]
]

{ #category : 'accessing' }
OTMetricData >> name: aString [

	name := aString ifNil: [ '' ] ifNotNil: [ aString ]
]

{ #category : 'accessing' }
OTMetricData >> metadata [

	^ metadata ifNil: [ OrderedDictionary new ]
]

{ #category : 'accessing' }
OTMetricData >> metadata: aCollection [

	metadata := OTAttributeNormalizer normalizeAttributes: aCollection
]

{ #category : 'accessing' }
OTMetricData >> metadataValueAt: aString ifAbsent: aBlock [

	^ self metadata at: aString ifAbsent: aBlock
]

{ #category : 'accessing' }
OTMetricData >> points [

	^ points ifNil: [ #() ]
]

{ #category : 'accessing' }
OTMetricData >> points: aCollection [

	points := aCollection ifNil: [ #() ] ifNotNil: [ aCollection asArray ]
]

{ #category : 'accessing' }
OTMetricData >> unit [

	^ unit ifNil: [ '' ]
]

{ #category : 'accessing' }
OTMetricData >> unit: aString [

	unit := aString ifNil: [ '' ] ifNotNil: [ aString ]
]

{ #category : 'otlp - encoding' }
OTMetricData >> addOtlpJsonDataTo: aDictionary encoder: anEncoder [

	self subclassResponsibility
]

{ #category : 'otlp - encoding' }
OTMetricData >> writeOtlpProtobufDataOn: aWriter encoder: anEncoder [

	self subclassResponsibility
]
