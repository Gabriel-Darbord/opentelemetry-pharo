"
I describe a metrics view that rewrites or filters instrument streams at collection time.
I can match instruments and choose stream identity, attribute retention, aggregation, cardinality, and exemplar behavior.
"
Class {
	#name : 'OTMetricView',
	#superclass : 'Object',
	#instVars : [
		'namePattern',
		'instrumentType',
		'unit',
		'meterName',
		'meterVersion',
		'meterSchemaUrl',
		'streamName',
		'streamDescription',
		'attributeKeys',
		'excludedAttributeKeys',
		'aggregation',
		'cardinalityLimit',
		'aggregationParameters',
		'exemplarReservoirFactory'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTMetricView class >> all [

	^ self named: '*'
]

{ #category : 'instance creation' }
OTMetricView class >> named: aString [

	^ self new
		  namePattern: aString;
		  yourself
]

{ #category : 'normalization' }
OTMetricView class >> normalizedAggregationFrom: anObject [

	| normalized |
	anObject ifNil: [ ^ #default ].
	anObject isSymbol ifTrue: [ normalized := anObject asString ].
	anObject isString ifTrue: [ normalized := anObject ].
	normalized ifNil: [ ^ #default ].
	normalized := (normalized select: [ :each | each isAlphaNumeric ]) asLowercase.
	normalized = 'drop' ifTrue: [ ^ #drop ].
	normalized = 'dropaggregation' ifTrue: [ ^ #drop ].
	normalized = 'default' ifTrue: [ ^ #default ].
	normalized = 'defaultaggregation' ifTrue: [ ^ #default ].
	normalized = 'sum' ifTrue: [ ^ #sum ].
	normalized = 'sumaggregation' ifTrue: [ ^ #sum ].
	normalized = 'lastvalue' ifTrue: [ ^ #lastValue ].
	normalized = 'lastvalueaggregation' ifTrue: [ ^ #lastValue ].
	normalized = 'explicitbuckethistogram' ifTrue: [ ^ #explicitBucketHistogram ].
	normalized = 'explicitbuckethistogramaggregation' ifTrue: [ ^ #explicitBucketHistogram ].
	normalized = 'base2exponentialbuckethistogram' ifTrue: [ ^ #base2ExponentialBucketHistogram ].
	normalized = 'base2exponentialbuckethistogramaggregation' ifTrue: [ ^ #base2ExponentialBucketHistogram ].
	^ #default
]

{ #category : 'normalization' }
OTMetricView class >> normalizedAggregationParameterKeyFrom: anObject [

	| normalized |
	anObject ifNil: [ ^ nil ].
	anObject isSymbol ifTrue: [ normalized := anObject asString ].
	anObject isString ifTrue: [ normalized := anObject ].
	normalized ifNil: [ ^ nil ].
	normalized := (normalized select: [ :each | each isAlphaNumeric ]) asLowercase.
	normalized = 'boundaries' ifTrue: [ ^ #boundaries ].
	normalized = 'recordminmax' ifTrue: [ ^ #recordMinMax ].
	normalized = 'maxsize' ifTrue: [ ^ #maxSize ].
	normalized = 'maxscale' ifTrue: [ ^ #maxScale ].
	^ nil
]

{ #category : 'normalization' }
OTMetricView class >> normalizedAggregationParametersFrom: aCollection [

	| normalized |
	aCollection ifNil: [ ^ nil ].
	normalized := OrderedDictionary new.
	aCollection associationsDo: [ :each |
			| key |
			key := self normalizedAggregationParameterKeyFrom: each key.
			key ifNotNil: [ normalized at: key put: each value ] ].
	^ normalized
]

{ #category : 'normalization' }
OTMetricView class >> normalizedInstrumentTypeFrom: anObject [

	| normalized |
	anObject ifNil: [ ^ nil ].
	anObject = OTCounter ifTrue: [ ^ #counter ].
	anObject = OTUpDownCounter ifTrue: [ ^ #upDownCounter ].
	anObject = OTHistogram ifTrue: [ ^ #histogram ].
	anObject = OTGauge ifTrue: [ ^ #gauge ].
	anObject = OTObservableCounter ifTrue: [ ^ #observableCounter ].
	anObject = OTObservableGauge ifTrue: [ ^ #observableGauge ].
	anObject = OTObservableUpDownCounter ifTrue: [ ^ #observableUpDownCounter ].
	anObject isSymbol ifTrue: [ normalized := anObject asString ].
	anObject isString ifTrue: [ normalized := anObject ].
	normalized ifNil: [ ^ nil ].
	normalized := (normalized select: [ :each | each isAlphaNumeric ]) asLowercase.
	normalized = 'counter' ifTrue: [ ^ #counter ].
	normalized = 'updowncounter' ifTrue: [ ^ #upDownCounter ].
	normalized = 'histogram' ifTrue: [ ^ #histogram ].
	normalized = 'gauge' ifTrue: [ ^ #gauge ].
	normalized = 'observablecounter' ifTrue: [ ^ #observableCounter ].
	normalized = 'observablegauge' ifTrue: [ ^ #observableGauge ].
	normalized = 'observableupdowncounter' ifTrue: [ ^ #observableUpDownCounter ].
	^ nil
]

{ #category : 'accessing' }
OTMetricView >> aggregation [

	^ aggregation ifNil: [ #default ]
]

{ #category : 'accessing' }
OTMetricView >> aggregation: anObject [

	aggregation := self class normalizedAggregationFrom: anObject
]

{ #category : 'accessing' }
OTMetricView >> aggregationCardinalityLimit [

	^ cardinalityLimit
]

{ #category : 'accessing' }
OTMetricView >> aggregationCardinalityLimit: anInteger [

	cardinalityLimit := (anInteger isInteger and: [ anInteger > 0 ])
		                    ifTrue: [ anInteger ]
		                    ifFalse: [ nil ]
]

{ #category : 'accessing' }
OTMetricView >> aggregationParameters [

	^ aggregationParameters
]

{ #category : 'accessing' }
OTMetricView >> aggregationParameters: aCollection [

	aggregationParameters := self class normalizedAggregationParametersFrom: aCollection
]

{ #category : 'applying' }
OTMetricView >> applyToMetricData: anOTMetricData [

	streamName ifNotNil: [ anOTMetricData name: streamName ].
	streamDescription ifNotNil: [ anOTMetricData description: streamDescription ].
	^ anOTMetricData
]

{ #category : 'accessing' }
OTMetricView >> attributeKeys [

	^ attributeKeys
]

{ #category : 'accessing' }
OTMetricView >> attributeKeys: aCollection [

	attributeKeys := aCollection ifNil: [ nil ] ifNotNil: [ aCollection collect: [ :each | each asString ] ]
]

{ #category : 'accessing' }
OTMetricView >> excludedAttributeKeys [

	^ excludedAttributeKeys
]

{ #category : 'accessing' }
OTMetricView >> excludedAttributeKeys: aCollection [

	excludedAttributeKeys := aCollection ifNil: [ nil ] ifNotNil: [ aCollection collect: [ :each | each asString ] ]
]

{ #category : 'accessing' }
OTMetricView >> exemplarReservoirFactory [

	^ exemplarReservoirFactory
]

{ #category : 'accessing' }
OTMetricView >> exemplarReservoirFactory: aBlockClosure [

	exemplarReservoirFactory := aBlockClosure
]

{ #category : 'accessing' }
OTMetricView >> instrumentType [

	^ instrumentType
]

{ #category : 'accessing' }
OTMetricView >> instrumentType: anObject [

	instrumentType := self class normalizedInstrumentTypeFrom: anObject
]

{ #category : 'matching' }
OTMetricView >> matchesInstrument: anOTMetricInstrument [

	^ (self matchesInstrumentName: anOTMetricInstrument name) and: [
			  (self matchesInstrumentType: anOTMetricInstrument instrumentType) and: [
					  (self matchesUnit: anOTMetricInstrument unit) and: [
							  (self matchesMeterName: anOTMetricInstrument instrumentationScope name) and: [
									  (self matchesMeterVersion: anOTMetricInstrument instrumentationScope version) and: [
										  self matchesMeterSchemaUrl: anOTMetricInstrument instrumentationScope schemaUrl ] ] ] ] ]
]

{ #category : 'matching' }
OTMetricView >> matchesInstrumentName: aString [

	namePattern ifNil: [ ^ true ].
	namePattern = '*' ifTrue: [ ^ true ].
	((namePattern includes: $*) or: [ namePattern includes: $? ]) ifTrue: [ ^ self wildcardPattern: namePattern matches: aString ].
	^ namePattern = aString
]

{ #category : 'matching' }
OTMetricView >> matchesInstrumentType: aSymbol [

	instrumentType ifNil: [ ^ true ].
	^ instrumentType = aSymbol
]

{ #category : 'matching' }
OTMetricView >> matchesMeterName: aString [

	meterName ifNil: [ ^ true ].
	^ meterName = aString
]

{ #category : 'matching' }
OTMetricView >> matchesMeterSchemaUrl: aString [

	meterSchemaUrl ifNil: [ ^ true ].
	^ meterSchemaUrl = aString
]

{ #category : 'matching' }
OTMetricView >> matchesMeterVersion: aString [

	meterVersion ifNil: [ ^ true ].
	^ meterVersion = aString
]

{ #category : 'matching' }
OTMetricView >> matchesUnit: aString [

	unit ifNil: [ ^ true ].
	^ unit = aString
]

{ #category : 'accessing' }
OTMetricView >> meterName [

	^ meterName
]

{ #category : 'accessing' }
OTMetricView >> meterName: aString [

	meterName := aString ifNil: [ nil ] ifNotNil: [ aString asString ]
]

{ #category : 'accessing' }
OTMetricView >> meterSchemaUrl [

	^ meterSchemaUrl
]

{ #category : 'accessing' }
OTMetricView >> meterSchemaUrl: aString [

	meterSchemaUrl := aString ifNil: [ nil ] ifNotNil: [ aString asString ]
]

{ #category : 'accessing' }
OTMetricView >> meterVersion [

	^ meterVersion
]

{ #category : 'accessing' }
OTMetricView >> meterVersion: aString [

	meterVersion := aString ifNil: [ nil ] ifNotNil: [ aString asString ]
]

{ #category : 'accessing' }
OTMetricView >> namePattern [

	^ namePattern
]

{ #category : 'accessing' }
OTMetricView >> namePattern: aString [

	namePattern := aString ifNil: [ nil ] ifNotNil: [ aString asString ]
]

{ #category : 'resolving' }
OTMetricView >> resolvedAggregationFor: anOTMetricInstrument reader: anOTMetricReader [

	aggregation ifNil: [ ^ anOTMetricReader aggregationFor: anOTMetricInstrument ].
	^ aggregation
]

{ #category : 'resolving' }
OTMetricView >> resolvedAggregationParametersFor: anOTMetricInstrument reader: anOTMetricReader [

	^ aggregationParameters
]

{ #category : 'resolving' }
OTMetricView >> resolvedAttributeFilterFor: anOTMetricInstrument [

	(attributeKeys isNil and: [ excludedAttributeKeys isNil ]) ifTrue: [ ^ anOTMetricInstrument attributeFilter ].
	^ OTMetricAttributeFilter included: attributeKeys excluded: excludedAttributeKeys
]

{ #category : 'resolving' }
OTMetricView >> resolvedCardinalityLimitFor: anOTMetricInstrument reader: anOTMetricReader [

	cardinalityLimit ifNotNil: [ ^ cardinalityLimit ].
	^ anOTMetricReader cardinalityLimitFor: anOTMetricInstrument
]

{ #category : 'resolving' }
OTMetricView >> resolvedExemplarReservoirFactoryFor: anOTMetricInstrument reader: anOTMetricReader [

	^ exemplarReservoirFactory
]

{ #category : 'resolving' }
OTMetricView >> resolvedRetainedAttributeKeysFor: anOTMetricInstrument [

	^ (self resolvedAttributeFilterFor: anOTMetricInstrument) includedKeys
]

{ #category : 'accessing' }
OTMetricView >> streamDescription [

	^ streamDescription
]

{ #category : 'accessing' }
OTMetricView >> streamDescription: aString [

	streamDescription := aString ifNil: [ nil ] ifNotNil: [ aString asString ]
]

{ #category : 'accessing' }
OTMetricView >> streamName [

	^ streamName
]

{ #category : 'accessing' }
OTMetricView >> streamName: aString [

	streamName := aString ifNil: [ nil ] ifNotNil: [ aString asString ]
]

{ #category : 'accessing' }
OTMetricView >> unit [

	^ unit
]

{ #category : 'accessing' }
OTMetricView >> unit: aString [

	unit := aString ifNil: [ nil ] ifNotNil: [ aString asString ]
]

{ #category : 'matching' }
OTMetricView >> wildcardPattern: aPattern at: patternIndex matches: aString at: stringIndex [

	| character |
	patternIndex > aPattern size ifTrue: [ ^ stringIndex > aString size ].
	character := aPattern at: patternIndex.
	character = $* ifTrue: [
			patternIndex = aPattern size ifTrue: [ ^ true ].
			stringIndex to: aString size + 1 do: [ :eachIndex |
					(self
						 wildcardPattern: aPattern
						 at: patternIndex + 1
						 matches: aString
						 at: eachIndex) ifTrue: [ ^ true ] ].
			^ false ].
	stringIndex > aString size ifTrue: [ ^ false ].
	(character = $? or: [ character = (aString at: stringIndex) ]) ifFalse: [ ^ false ].
	^ self
		  wildcardPattern: aPattern
		  at: patternIndex + 1
		  matches: aString
		  at: stringIndex + 1
]

{ #category : 'matching' }
OTMetricView >> wildcardPattern: aPattern matches: aString [

	^ self
		  wildcardPattern: aPattern
		  at: 1
		  matches: aString
		  at: 1
]
