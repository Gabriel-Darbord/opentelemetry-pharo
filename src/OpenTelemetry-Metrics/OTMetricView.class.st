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

{ #category : 'normalization' }
OTMetricView class >> aggregationFromNormalizedString: aString [

	aString ifNil: [ ^ #default ].
	aString = 'drop' ifTrue: [ ^ #drop ].
	aString = 'dropaggregation' ifTrue: [ ^ #drop ].
	aString = 'default' ifTrue: [ ^ #default ].
	aString = 'defaultaggregation' ifTrue: [ ^ #default ].
	aString = 'sum' ifTrue: [ ^ #sum ].
	aString = 'sumaggregation' ifTrue: [ ^ #sum ].
	aString = 'lastvalue' ifTrue: [ ^ #lastValue ].
	aString = 'lastvalueaggregation' ifTrue: [ ^ #lastValue ].
	aString = 'explicitbuckethistogram' ifTrue: [ ^ #explicitBucketHistogram ].
	aString = 'explicitbuckethistogramaggregation' ifTrue: [ ^ #explicitBucketHistogram ].
	aString = 'base2exponentialbuckethistogram' ifTrue: [ ^ #base2ExponentialBucketHistogram ].
	aString = 'base2exponentialbuckethistogramaggregation' ifTrue: [ ^ #base2ExponentialBucketHistogram ].
	^ #default
]

{ #category : 'normalization' }
OTMetricView class >> aggregationParameterKeyFromNormalizedString: aString [

	aString ifNil: [ ^ nil ].
	aString = 'boundaries' ifTrue: [ ^ #boundaries ].
	aString = 'recordminmax' ifTrue: [ ^ #recordMinMax ].
	aString = 'maxsize' ifTrue: [ ^ #maxSize ].
	aString = 'maxscale' ifTrue: [ ^ #maxScale ].
	^ nil
]

{ #category : 'instance creation' }
OTMetricView class >> all [

	^ self named: '*'
]

{ #category : 'normalization' }
OTMetricView class >> instrumentTypeFromNormalizedString: aString [

	aString ifNil: [ ^ nil ].
	aString = 'counter' ifTrue: [ ^ #counter ].
	aString = 'updowncounter' ifTrue: [ ^ #upDownCounter ].
	aString = 'histogram' ifTrue: [ ^ #histogram ].
	aString = 'gauge' ifTrue: [ ^ #gauge ].
	aString = 'observablecounter' ifTrue: [ ^ #observableCounter ].
	aString = 'observablegauge' ifTrue: [ ^ #observableGauge ].
	aString = 'observableupdowncounter' ifTrue: [ ^ #observableUpDownCounter ].
	^ nil
]

{ #category : 'instance creation' }
OTMetricView class >> named: aString [

	^ self new
		  namePattern: aString;
		  yourself
]

{ #category : 'normalization' }
OTMetricView class >> normalizedAggregationFrom: anObject [

	anObject ifNil: [ ^ #default ].
	^ self aggregationFromNormalizedString: (self normalizedStringFrom: anObject)
]

{ #category : 'normalization' }
OTMetricView class >> normalizedAggregationParameterKeyFrom: anObject [

	^ self aggregationParameterKeyFromNormalizedString: (self normalizedStringFrom: anObject)
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

	anObject ifNil: [ ^ nil ].
	anObject = OTCounter ifTrue: [ ^ #counter ].
	anObject = OTUpDownCounter ifTrue: [ ^ #upDownCounter ].
	anObject = OTHistogram ifTrue: [ ^ #histogram ].
	anObject = OTGauge ifTrue: [ ^ #gauge ].
	anObject = OTObservableCounter ifTrue: [ ^ #observableCounter ].
	anObject = OTObservableGauge ifTrue: [ ^ #observableGauge ].
	anObject = OTObservableUpDownCounter ifTrue: [ ^ #observableUpDownCounter ].
	^ self instrumentTypeFromNormalizedString: (self normalizedStringFrom: anObject)
]

{ #category : 'normalization' }
OTMetricView class >> normalizedStringFrom: anObject [

	anObject ifNil: [ ^ nil ].
	(anObject isString or: [ anObject isSymbol ]) ifFalse: [ ^ nil ].
	^ (anObject asString select: [ :each | each isAlphaNumeric ]) asLowercase
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

	attributeKeys := aCollection ifNotNil: [ aCollection collect: [ :each | each asString ] ]
]

{ #category : 'accessing' }
OTMetricView >> excludedAttributeKeys [

	^ excludedAttributeKeys
]

{ #category : 'accessing' }
OTMetricView >> excludedAttributeKeys: aCollection [

	excludedAttributeKeys := aCollection ifNotNil: [ aCollection collect: [ :each | each asString ] ]
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

	meterName := aString ifNotNil: [ aString asString ]
]

{ #category : 'accessing' }
OTMetricView >> meterSchemaUrl [

	^ meterSchemaUrl
]

{ #category : 'accessing' }
OTMetricView >> meterSchemaUrl: aString [

	meterSchemaUrl := aString ifNotNil: [ aString asString ]
]

{ #category : 'accessing' }
OTMetricView >> meterVersion [

	^ meterVersion
]

{ #category : 'accessing' }
OTMetricView >> meterVersion: aString [

	meterVersion := aString ifNotNil: [ aString asString ]
]

{ #category : 'accessing' }
OTMetricView >> namePattern [

	^ namePattern
]

{ #category : 'accessing' }
OTMetricView >> namePattern: aString [

	namePattern := aString ifNotNil: [ aString asString ]
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

	streamDescription := aString ifNotNil: [ aString asString ]
]

{ #category : 'accessing' }
OTMetricView >> streamName [

	^ streamName
]

{ #category : 'accessing' }
OTMetricView >> streamName: aString [

	streamName := aString ifNotNil: [ aString asString ]
]

{ #category : 'accessing' }
OTMetricView >> unit [

	^ unit
]

{ #category : 'accessing' }
OTMetricView >> unit: aString [

	unit := aString ifNotNil: [ aString asString ]
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
