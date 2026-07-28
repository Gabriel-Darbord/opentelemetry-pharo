"
I encode aggregated metric snapshots into Prometheus text exposition formats.
I also normalize Prometheus names, types, labels, and warning paths.
"
Class {
	#name : 'OTPrometheusTextEncoder',
	#superclass : 'Object',
	#instVars : [
		'warningSink',
		'scopeInfoEnabled',
		'targetInfoEnabled',
		'resourceConstantLabels',
		'currentResource',
		'translationStrategy',
		'escapingMode'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'accessing' }
OTPrometheusTextEncoder class >> defaultTranslationStrategy [

	^ #underscoreEscapingWithSuffixes
]

{ #category : 'accessing' }
OTPrometheusTextEncoder class >> translationStrategyNameFor: aSymbol [

	aSymbol = #underscoreEscapingWithSuffixes ifTrue: [ ^ 'UnderscoreEscapingWithSuffixes' ].
	aSymbol = #underscoreEscapingWithoutSuffixes ifTrue: [ ^ 'UnderscoreEscapingWithoutSuffixes' ].
	aSymbol = #noUtf8EscapingWithSuffixes ifTrue: [ ^ 'NoUTF8EscapingWithSuffixes' ].
	aSymbol = #noTranslation ifTrue: [ ^ 'NoTranslation' ].
	^ nil
]

{ #category : 'accessing' }
OTPrometheusTextEncoder class >> translationStrategyNamed: aString ifAbsent: aBlock [

	| normalized |
	normalized := aString ifNil: [ '' ] ifNotNil: [ aString asString trimBoth ].
	normalized = 'UnderscoreEscapingWithSuffixes' ifTrue: [ ^ #underscoreEscapingWithSuffixes ].
	normalized = 'UnderscoreEscapingWithoutSuffixes' ifTrue: [ ^ #underscoreEscapingWithoutSuffixes ].
	normalized = 'NoUTF8EscapingWithSuffixes' ifTrue: [ ^ #noUtf8EscapingWithSuffixes ].
	normalized = 'NoTranslation' ifTrue: [ ^ #noTranslation ].
	^ aBlock value
]

{ #category : 'private - logging' }
OTPrometheusTextEncoder >> defaultWarningSink [

	^ OTDiagnosticLogger defaultWarningSink
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> duplicateSampleIdentityIn: sampleSpecifications against: seenSampleIdentities [

	| localSampleIdentities |
	localSampleIdentities := Set new.
	sampleSpecifications do: [ :each |
			| sampleIdentity |
			sampleIdentity := self sampleIdentityFor: each.
			((localSampleIdentities includes: sampleIdentity) or: [ seenSampleIdentities includes: sampleIdentity ]) ifTrue: [
				^ sampleIdentity ].
			localSampleIdentities add: sampleIdentity ].
	^ nil
]

{ #category : 'encoding' }
OTPrometheusTextEncoder >> encodeSnapshot: anOTMetricSnapshot [

	^ self encodeSnapshot: anOTMetricSnapshot format: #prometheusText004
]

{ #category : 'encoding' }
OTPrometheusTextEncoder >> encodeSnapshot: anOTMetricSnapshot format: aFormatSymbol [

	| previousResource |
	previousResource := currentResource.
	currentResource := anOTMetricSnapshot resource.
	^ [ String streamContents: [ :stream | self writeSnapshot: anOTMetricSnapshot format: aFormatSymbol on: stream ] ] ensure: [
		  currentResource := previousResource ]
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> histogramBucketIndexForExemplar: anOTMetricExemplar bounds: someBounds [

	1 to: someBounds size do: [ :index | anOTMetricExemplar value <= (someBounds at: index) ifTrue: [ ^ index ] ].
	^ someBounds size + 1
]

{ #category : 'initialization' }
OTPrometheusTextEncoder >> initialize [

	super initialize.
	warningSink := self defaultWarningSink.
	scopeInfoEnabled := true.
	targetInfoEnabled := true.
	resourceConstantLabels := nil.
	currentResource := OTResource empty.
	translationStrategy := self class defaultTranslationStrategy.
	escapingMode := nil
]

{ #category : 'private - testing' }
OTPrometheusTextEncoder >> isAsciiDigit: aCharacter [

	| value |
	value := aCharacter asInteger.
	^ value >= 48 and: [ value <= 57 ]
]

{ #category : 'private - testing' }
OTPrometheusTextEncoder >> isAsciiLetter: aCharacter [

	| value |
	value := aCharacter asInteger.
	^ (value >= 65 and: [ value <= 90 ]) or: [ value >= 97 and: [ value <= 122 ] ]
]

{ #category : 'private - testing' }
OTPrometheusTextEncoder >> isPrometheusNameCharacter: aCharacter allowingColon: aBoolean [

	^ (self isAsciiLetter: aCharacter) or: [
		  (self isAsciiDigit: aCharacter) or: [ aCharacter = $_ or: [ aBoolean and: [ aCharacter = $: ] ] ] ]
]

{ #category : 'private - testing' }
OTPrometheusTextEncoder >> isPrometheusNameStartCharacter: aCharacter [

	^ (self isAsciiLetter: aCharacter) or: [ aCharacter = $_ ]
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> attachesPrometheusNameSuffixes [

	^ #( #underscoreEscapingWithSuffixes #noUtf8EscapingWithSuffixes ) includes: self translationStrategy
]

{ #category : 'accessing' }
OTPrometheusTextEncoder >> escapingMode [

	^ escapingMode
]

{ #category : 'accessing' }
OTPrometheusTextEncoder >> escapingMode: aSymbolOrNil [

	escapingMode := aSymbolOrNil
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> escapedPrometheusQuotedNameFrom: aString [

	^ String streamContents: [ :stream |
			  aString asString do: [ :each |
					  each = $\ ifTrue: [ stream nextPutAll: '\\' ].
					  each = $" ifTrue: [ stream nextPutAll: '\"' ].
					  each = Character lf ifTrue: [ stream nextPutAll: '\n' ].
					  each = Character cr ifTrue: [ stream nextPutAll: '\n' ].
					  ((each ~= $\ and: [ each ~= $" ]) and: [ each ~= Character lf and: [ each ~= Character cr ] ]) ifTrue: [
							  stream nextPut: each ] ] ]
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> effectiveEscapingMode [

	(translationStrategy = #underscoreEscapingWithSuffixes
		 or: [ translationStrategy = #underscoreEscapingWithoutSuffixes ]) ifTrue: [ ^ #underscores ].
	^ escapingMode ifNil: [ #allowUtf8 ]
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> jobLabelForResource: anOTResource [

	| namespace serviceName |
	namespace := anOTResource attributeAt: 'service.namespace' ifAbsent: [ '' ].
	serviceName := anOTResource attributeAt: 'service.name' ifAbsent: [ '' ].
	namespace isEmpty ifTrue: [ ^ serviceName ].
	serviceName isEmpty ifTrue: [ ^ namespace ].
	^ namespace , '/' , serviceName
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> joinValues: someValues [

	^ String streamContents: [ :stream |
			  someValues doWithIndex: [ :each :index |
					  index > 1 ifTrue: [ stream nextPut: $; ].
					  stream nextPutAll: each ] ]
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> labelsByAdding: aLabelName value: aValue to: someLabels [

	| labels |
	labels := someLabels copy.
	labels add: aLabelName -> aValue.
	^ labels
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> latestExemplarIn: someExemplars [

	| latest |
	latest := nil.
	someExemplars do: [ :each |
		latest ifNil: [ latest := each ] ifNotNil: [ latest timestamp <= each timestamp ifTrue: [ latest := each ] ] ].
	^ latest
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> latestHistogramExemplarsByBucketFor: anOTHistogramDataPoint [

	| exemplarsByBucket |
	exemplarsByBucket := Dictionary new.
	anOTHistogramDataPoint exemplars do: [ :each |
			| bucketIndex current |
			bucketIndex := self histogramBucketIndexForExemplar: each bounds: anOTHistogramDataPoint explicitBounds.
			current := exemplarsByBucket at: bucketIndex ifAbsent: [ nil ].
			(current isNil or: [ current timestamp <= each timestamp ]) ifTrue: [ exemplarsByBucket at: bucketIndex put: each ] ].
	^ exemplarsByBucket
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> normalizedPrometheusNameFrom: aString allowingColon: aBoolean [

	| normalized previousUnderscore stream |
	stream := String new writeStream.
	previousUnderscore := false.
	aString asString do: [ :each |
			| character |
			character := (self isPrometheusNameCharacter: each allowingColon: aBoolean)
				             ifTrue: [ each ]
				             ifFalse: [ $_ ].
			character = $_
				ifTrue: [
						previousUnderscore ifFalse: [ stream nextPut: $_ ].
						previousUnderscore := true ]
				ifFalse: [
						stream nextPut: character.
						previousUnderscore := false ] ].
	normalized := stream contents.
	normalized ifEmpty: [ ^ '_' ].
	(self isPrometheusNameStartCharacter: normalized first) ifTrue: [ ^ normalized ].
	^ '_' , normalized
]

{ #category : 'private - logging' }
OTPrometheusTextEncoder >> noteDroppedMetricFamilyNamed: aMetricName dueToConflictingTypes: someTypes [

	self warningSink value:
		'OpenTelemetry dropped Prometheus metric family due to conflicting types for ' , aMetricName printString , ': '
		, (String streamContents: [ :stream |
					 someTypes asArray sort doWithIndex: [ :each :index |
							 index > 1 ifTrue: [ stream nextPutAll: ', ' ].
							 stream nextPutAll: each asString ] ])
]

{ #category : 'private - logging' }
OTPrometheusTextEncoder >> noteDroppedMetricNamed: aMetricName dueToDuplicatePrometheusSample: aSampleIdentity [

	self warningSink value:
		'OpenTelemetry dropped Prometheus metric due to duplicate sample identity for ' , aMetricName printString , ': '
		, aSampleIdentity
]

{ #category : 'private - logging' }
OTPrometheusTextEncoder >> noteIgnoredConflictingMetadataNamed: aMetadataName forMetricFamily: aMetricName values: someValues [

	self warningSink value:
		'OpenTelemetry ignored conflicting Prometheus ' , aMetadataName , ' metadata for ' , aMetricName printString , ': '
		, (String streamContents: [ :stream |
					 someValues asArray sort doWithIndex: [ :each :index |
							 index > 1 ifTrue: [ stream nextPutAll: ', ' ].
							 stream nextPutAll: each printString ] ])
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> pointLabels: someAttributes resource: anOTResource scope: anOTInstrumentationScope [

	| rawLabels reservedScopeLabels |
	rawLabels := OrderedCollection new.
	someAttributes associationsDo: [ :each | rawLabels add: each key asString -> (self prometheusStringValueFor: each value) ].
	self resourceConstantLabelAssociationsFrom: anOTResource do: [ :each | rawLabels add: each ].
	self scopeInfoEnabled ifFalse: [ ^ rawLabels ].
	rawLabels
		add: 'otel_scope_name' -> anOTInstrumentationScope name;
		add: 'otel_scope_version' -> anOTInstrumentationScope version;
		add: 'otel_scope_schema_url' -> anOTInstrumentationScope schemaUrl.
	reservedScopeLabels := Set withAll: #( 'otel_scope_name' 'otel_scope_version' 'otel_scope_schema_url' ).
	anOTInstrumentationScope allAttributes associationsDo: [ :each |
			| prefixed normalized |
			prefixed := 'otel_scope_' , each key asString.
			normalized := self prometheusLabelNameFor: prefixed.
			(reservedScopeLabels includes: normalized) ifFalse: [ rawLabels add: prefixed -> (self prometheusStringValueFor: each value) ] ].
	^ rawLabels
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> prometheusBoundaryStringFor: aNumber [

	aNumber = Float infinity ifTrue: [ ^ '+Inf' ].
	aNumber = Float negativeInfinity ifTrue: [ ^ '-Inf' ].
	^ aNumber printString
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> prometheusExemplarLabelLimitForFormat: aFormatSymbol [

	^ aFormatSymbol = #openMetricsText100
		  ifTrue: [ 128 ]
		  ifFalse: [ nil ]
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> prometheusExemplarLabelSizeFor: anAssociation [

	^ anAssociation key utf8Encoded size + anAssociation value asString utf8Encoded size
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> prometheusExemplarLabelsFor: anOTMetricExemplar format: aFormatSymbol [

	| currentSize filteredRawLabels finalLabels labelLimit requiredLabels trimmedLabels |
	requiredLabels := OrderedDictionary new.
	anOTMetricExemplar traceId ifNotNil: [ requiredLabels at: 'trace_id' put: anOTMetricExemplar traceId ].
	anOTMetricExemplar spanId ifNotNil: [ requiredLabels at: 'span_id' put: anOTMetricExemplar spanId ].
	filteredRawLabels := OrderedCollection new.
	anOTMetricExemplar filteredAttributes associationsDo: [ :each |
			| normalized |
			normalized := self prometheusLabelNameFor: each key.
			(requiredLabels includesKey: normalized) ifFalse: [
				filteredRawLabels add: each key asString -> (self prometheusStringValueFor: each value) ] ].
	trimmedLabels := self prometheusLabelsFromAssociations: filteredRawLabels.
	labelLimit := self prometheusExemplarLabelLimitForFormat: aFormatSymbol.
	finalLabels := OrderedDictionary new.
	currentSize := 0.
	requiredLabels associationsDo: [ :each |
			finalLabels at: each key put: each value.
			currentSize := currentSize + (self prometheusExemplarLabelSizeFor: each) ].
	trimmedLabels associationsDo: [ :each |
			(labelLimit isNil or: [ currentSize + (self prometheusExemplarLabelSizeFor: each) <= labelLimit ]) ifTrue: [
					finalLabels at: each key put: each value.
					currentSize := currentSize + (self prometheusExemplarLabelSizeFor: each) ] ].
	^ finalLabels
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> prometheusGaugeLikeMetricTypeFor: anOTMetricData format: aFormatSymbol [

	| hint |
	hint := self prometheusTypeHintFor: anOTMetricData.
	hint = #unknown ifTrue: [
			^ aFormatSymbol = #openMetricsText100
				  ifTrue: [ #unknown ]
				  ifFalse: [ #untyped ] ].
	hint = #info ifTrue: [
			^ aFormatSymbol = #openMetricsText100
				  ifTrue: [ #info ]
				  ifFalse: [ #infoGauge ] ].
	hint = #stateset ifTrue: [
			^ aFormatSymbol = #openMetricsText100
				  ifTrue: [ #stateset ]
				  ifFalse: [ #statesetGauge ] ].
	^ #gauge
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> prometheusHelpStringFor: aString [

	^ String streamContents: [ :stream |
			  aString asString do: [ :each |
					  each = $\ ifTrue: [ stream nextPutAll: '\\' ].
					  each = Character lf ifTrue: [ stream nextPutAll: '\n' ].
					  each = Character cr ifTrue: [ stream nextPutAll: '\n' ].
					  (each ~= $\ and: [ each ~= Character lf and: [ each ~= Character cr ] ]) ifTrue: [ stream nextPut: each ] ] ]
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> prometheusLabelNameFor: aString [

	^ self usesUnderscoreEscaping
		  ifTrue: [ self normalizedPrometheusNameFrom: aString allowingColon: false ]
		  ifFalse: [ aString asString ]
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> prometheusLabelsFromAssociations: someAssociations [

	| grouped result |
	grouped := Dictionary new.
	someAssociations do: [ :each |
			| normalized values |
			normalized := self prometheusLabelNameFor: each key.
			values := grouped at: normalized ifAbsentPut: [ OrderedCollection new ].
			values add: each ].
	result := OrderedDictionary new.
	grouped keys asSortedCollection do: [ :eachLabel |
			| values |
			values := (grouped at: eachLabel) asSortedCollection: [ :left :right | left key asString <= right key asString ].
			result at: eachLabel put: (self joinValues: (values collect: [ :each | each value ])) ].
	^ result
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> prometheusMetricNameFor: anOTMetricData type: aTypeSymbol [

	^ self prometheusMetricNameFor: anOTMetricData type: aTypeSymbol format: #prometheusText004
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> prometheusMetricNameFor: anOTMetricData type: aTypeSymbol format: aFormatSymbol [

	| suffix stem unitWord |
	stem := self prometheusMetricStemFor: anOTMetricData type: aTypeSymbol.
	unitWord := ((self attachesPrometheusNameSuffixes and: [ self typeUsesPrometheusUnitSuffix: aTypeSymbol ]))
		            ifTrue: [ self prometheusUnitWordFrom: anOTMetricData unit ]
		            ifFalse: [ nil ].
	(unitWord notNil and: [ (stem endsWith: '_' , unitWord) not and: [ stem ~= unitWord ] ]) ifTrue: [ stem := stem , '_' , unitWord ].
	suffix := self attachesPrometheusNameSuffixes
		          ifTrue: [ self suffixForPrometheusMetricType: aTypeSymbol format: aFormatSymbol ]
		          ifFalse: [ '' ].
	^ stem , suffix
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> prometheusMetricStemFor: anOTMetricData type: aTypeSymbol [

	| metricName |
	metricName := self usesUnderscoreEscaping
		              ifTrue: [ self normalizedPrometheusNameFrom: anOTMetricData name allowingColon: true ]
		              ifFalse: [ anOTMetricData name asString ].
	self attachesPrometheusNameSuffixes ifFalse: [ ^ metricName ].
	(aTypeSymbol = #counter and: [ metricName endsWith: '_total' ]) ifTrue: [ ^ metricName allButLast: '_total' size ].
	((#( #info #infoGauge ) includes: aTypeSymbol) and: [ metricName endsWith: '_info' ]) ifTrue: [
		^ metricName allButLast: '_info' size ].
	^ metricName
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> prometheusMetricTypeFor: anOTMetricData [

	^ self prometheusMetricTypeFor: anOTMetricData format: #prometheusText004
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> prometheusMetricTypeFor: anOTMetricData format: aFormatSymbol [

	^ anOTMetricData prometheusMetricTypeWith: self format: aFormatSymbol
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> prometheusMetricTypeStringFor: aTypeSymbol [

	aTypeSymbol = #counter ifTrue: [ ^ 'counter' ].
	aTypeSymbol = #histogram ifTrue: [ ^ 'histogram' ].
	aTypeSymbol = #summary ifTrue: [ ^ 'summary' ].
	aTypeSymbol = #unknown ifTrue: [ ^ 'unknown' ].
	aTypeSymbol = #untyped ifTrue: [ ^ 'untyped' ].
	aTypeSymbol = #info ifTrue: [ ^ 'info' ].
	aTypeSymbol = #stateset ifTrue: [ ^ 'stateset' ].
	^ 'gauge'
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> prometheusStringValueFor: anObject [

	anObject ifNil: [ ^ '' ].
	anObject isString ifTrue: [ ^ anObject ].
	^ anObject printString
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> prometheusTimestampStringFor: aDateAndTime [

	| fraction micros microseconds seconds |
	microseconds := (aDateAndTime ifNil: [ DateAndTime unixEpoch ]) asUnixMicroseconds.
	seconds := microseconds quo: 1000000.
	micros := microseconds \\ 1000000.
	micros = 0 ifTrue: [ ^ seconds asString ].
	fraction := micros printString.
	fraction size < 6 ifTrue: [ fraction := (String new: 6 - fraction size withAll: $0) , fraction ].
	[ fraction isNotEmpty and: [ fraction last = $0 ] ] whileTrue: [ fraction := fraction allButLast ].
	^ seconds asString , '.' , fraction
]

{ #category : 'private - testing' }
OTPrometheusTextEncoder >> requiresQuotedPrometheusLabelName: aString [

	aString isEmpty ifTrue: [ ^ true ].
	(self isPrometheusNameStartCharacter: aString first) ifFalse: [ ^ true ].
	^ aString allButFirst anySatisfy: [ :each | (self isPrometheusNameCharacter: each allowingColon: false) not ]
]

{ #category : 'private - testing' }
OTPrometheusTextEncoder >> requiresQuotedPrometheusMetricName: aString [

	aString isEmpty ifTrue: [ ^ true ].
	(self isPrometheusNameStartCharacter: aString first) ifFalse: [ ^ true ].
	^ aString allButFirst anySatisfy: [ :each | (self isPrometheusNameCharacter: each allowingColon: true) not ]
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> prometheusTypeHintFor: anOTMetricData [

	| normalized |
	normalized := anOTMetricData metadataValueAt: 'prometheus.type' ifAbsent: [ ^ nil ].
	normalized := normalized asString trimBoth asLowercase.
	normalized = 'unkown' ifTrue: [ normalized := 'unknown' ].
	(#( 'gauge' 'unknown' 'info' 'stateset' ) includes: normalized) ifFalse: [ ^ nil ].
	^ normalized asSymbol
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> prometheusUnitPartWordFrom: aString [

	| normalized |
	normalized := aString trimBoth.
	normalized isEmpty ifTrue: [ ^ nil ].
	normalized = '1' ifTrue: [ ^ nil ].
	normalized = 'd' ifTrue: [ ^ 'days' ].
	normalized = 'h' ifTrue: [ ^ 'hours' ].
	normalized = 'min' ifTrue: [ ^ 'minutes' ].
	normalized = 's' ifTrue: [ ^ 'seconds' ].
	normalized = 'ms' ifTrue: [ ^ 'milliseconds' ].
	normalized = 'us' ifTrue: [ ^ 'microseconds' ].
	normalized = 'ns' ifTrue: [ ^ 'nanoseconds' ].
	normalized = 'By' ifTrue: [ ^ 'bytes' ].
	normalized = 'KiBy' ifTrue: [ ^ 'kibibytes' ].
	normalized = 'MiBy' ifTrue: [ ^ 'mebibytes' ].
	normalized = 'GiBy' ifTrue: [ ^ 'gibibytes' ].
	normalized = 'TiBy' ifTrue: [ ^ 'tebibytes' ].
	normalized = 'kBy' ifTrue: [ ^ 'kilobytes' ].
	normalized = 'MBy' ifTrue: [ ^ 'megabytes' ].
	normalized = 'GBy' ifTrue: [ ^ 'gigabytes' ].
	normalized = 'TBy' ifTrue: [ ^ 'terabytes' ].
	normalized = 'm' ifTrue: [ ^ 'meters' ].
	normalized = 'V' ifTrue: [ ^ 'volts' ].
	normalized = 'A' ifTrue: [ ^ 'amperes' ].
	normalized = 'J' ifTrue: [ ^ 'joules' ].
	normalized = 'W' ifTrue: [ ^ 'watts' ].
	normalized = 'g' ifTrue: [ ^ 'grams' ].
	normalized = 'Cel' ifTrue: [ ^ 'celsius' ].
	normalized = 'Hz' ifTrue: [ ^ 'hertz' ].
	normalized = '%' ifTrue: [ ^ 'percent' ].
	^ self normalizedPrometheusNameFrom: normalized allowingColon: false
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> prometheusUnitWordFrom: aString [

	| cleaned denominator numerator partWord parts slashIndex |
	cleaned := String streamContents: [ :stream |
			           | depth |
			           depth := 0.
			           aString asString do: [ :each |
					           each = ${
						           ifTrue: [ depth := depth + 1 ]
						           ifFalse: [
								           each = $}
									           ifTrue: [ depth := depth - 1 max: 0 ]
									           ifFalse: [ depth = 0 ifTrue: [ stream nextPut: each ] ] ] ] ].
	cleaned := cleaned trimBoth.
	cleaned isEmpty ifTrue: [ ^ nil ].
	cleaned = '1' ifTrue: [ ^ nil ].
	slashIndex := cleaned indexOf: $/ ifAbsent: [ 0 ].
	slashIndex > 0 ifTrue: [
			numerator := (cleaned copyFrom: 1 to: slashIndex - 1) trimBoth.
			denominator := (cleaned copyFrom: slashIndex + 1 to: cleaned size) trimBoth.
			(numerator isEmpty or: [ denominator isEmpty ]) ifTrue: [ ^ self prometheusUnitPartWordFrom: cleaned ].
			((self prometheusUnitPartWordFrom: numerator) isNil or: [ (self prometheusUnitPartWordFrom: denominator) isNil ]) ifTrue: [
				^ nil ].
			^ String streamContents: [ :stream |
					  stream nextPutAll: (self prometheusUnitPartWordFrom: numerator).
					  stream nextPutAll: '_per_'.
					  stream nextPutAll: (self prometheusUnitPartWordFrom: denominator) ] ].
	parts := cleaned findTokens: ' .'.
	parts isEmpty ifTrue: [ ^ nil ].
	^ String streamContents: [ :stream |
			  parts doWithIndex: [ :each :index |
					  partWord := self prometheusUnitPartWordFrom: each.
					  partWord ifNotNil: [
							  stream position > 0 ifTrue: [ stream nextPut: $_ ].
							  stream nextPutAll: partWord ] ] ]
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> prometheusValueForGaugeLikePoint: anOTNumberDataPoint type: aTypeSymbol [

	(#( #info #infoGauge ) includes: aTypeSymbol) ifTrue: [ ^ 1 ].
	^ anOTNumberDataPoint value
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> prometheusValueStringFor: aNumber [

	^ aNumber printString
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> quotedPrometheusValueFor: aString [

	^ String streamContents: [ :stream |
			  aString asString do: [ :each |
					  each = $\ ifTrue: [ stream nextPutAll: '\\' ].
					  each = $" ifTrue: [ stream nextPutAll: '\"' ].
					  each = Character lf ifTrue: [ stream nextPutAll: '\n' ].
					  each = Character cr ifTrue: [ stream nextPutAll: '\n' ].
					  (each ~= $\ and: [ each ~= $" and: [ each ~= Character lf and: [ each ~= Character cr ] ] ]) ifTrue: [
						  stream nextPut: each ] ] ]
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> resourceConstantLabelAssociationsFrom: anOTResource do: aBlock [

	| filter selected |
	anOTResource ifNil: [ ^ self ].
	filter := self resourceConstantLabels.
	filter ifNil: [ ^ self ].
	selected := filter selectedAttributesFrom: anOTResource allAttributes.
	selected associationsDo: [ :each | aBlock value: each key asString -> (self prometheusStringValueFor: each value) ]
]

{ #category : 'accessing' }
OTPrometheusTextEncoder >> resourceConstantLabels [

	^ resourceConstantLabels
]

{ #category : 'accessing' }
OTPrometheusTextEncoder >> resourceConstantLabels: anOTMetricAttributeFilterOrNil [

	resourceConstantLabels := anOTMetricAttributeFilterOrNil
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> sampleIdentityFor: aSampleSpecification [

	| labels |
	labels := self prometheusLabelsFromAssociations: aSampleSpecification second.
	^ String streamContents: [ :stream |
			  stream nextPutAll: aSampleSpecification first.
			  stream nextPut: Character tab.
			  labels associationsDo: [ :each |
					  stream
						  nextPutAll: each key;
						  nextPut: $=;
						  nextPutAll: each value asString;
						  nextPut: Character tab ] ]
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> sampleSpecificationNamed: aMetricName labels: someLabels value: aValue [

	^ self
		  sampleSpecificationNamed: aMetricName
		  labels: someLabels
		  value: aValue
		  exemplar: nil
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> sampleSpecificationNamed: aMetricName labels: someLabels value: aValue exemplar: anOTMetricExemplarOrNil [

	^ {
		  aMetricName.
		  someLabels.
		  aValue.
		  anOTMetricExemplarOrNil }
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> sampleSpecificationsForGauge: anOTGaugeMetricData type: aTypeSymbol format: aFormatSymbol [

	| metricName sampleSpecifications |
	metricName := self prometheusMetricNameFor: anOTGaugeMetricData type: aTypeSymbol format: aFormatSymbol.
	sampleSpecifications := OrderedCollection new: anOTGaugeMetricData points size.
	anOTGaugeMetricData points do: [ :each |
			sampleSpecifications add: (self
					 sampleSpecificationNamed: metricName
					 labels: (self pointLabels: each attributes resource: currentResource scope: anOTGaugeMetricData instrumentationScope)
					 value: (self prometheusValueForGaugeLikePoint: each type: aTypeSymbol)) ].
	^ sampleSpecifications
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> sampleSpecificationsForHistogram: anOTHistogramMetricData [

	| bucketMetricName countMetricName metricName sampleSpecifications sumMetricName |
	metricName := self prometheusMetricNameFor: anOTHistogramMetricData type: #histogram.
	bucketMetricName := metricName , '_bucket'.
	sumMetricName := metricName , '_sum'.
	countMetricName := metricName , '_count'.
	sampleSpecifications := OrderedCollection new.
	anOTHistogramMetricData points do: [ :eachPoint |
			| baseLabels bucketExemplars cumulative |
			baseLabels := self
				              pointLabels: eachPoint attributes
				              resource: currentResource
				              scope: anOTHistogramMetricData instrumentationScope.
			bucketExemplars := self latestHistogramExemplarsByBucketFor: eachPoint.
			cumulative := 0.
			1 to: eachPoint explicitBounds size do: [ :index |
					cumulative := cumulative + (eachPoint bucketCounts at: index ifAbsent: [ 0 ]).
					sampleSpecifications add: (self
							 sampleSpecificationNamed: bucketMetricName
							 labels:
							 (self labelsByAdding: 'le' value: (self prometheusBoundaryStringFor: (eachPoint explicitBounds at: index)) to: baseLabels)
							 value: cumulative
							 exemplar: (bucketExemplars at: index ifAbsent: [ nil ])) ].
			cumulative := cumulative + (eachPoint bucketCounts at: eachPoint explicitBounds size + 1 ifAbsent: [ 0 ]).
			sampleSpecifications
				add: (self
						 sampleSpecificationNamed: bucketMetricName
						 labels: (self labelsByAdding: 'le' value: '+Inf' to: baseLabels)
						 value: cumulative
						 exemplar: (bucketExemplars at: eachPoint explicitBounds size + 1 ifAbsent: [ nil ]));
				add: (self sampleSpecificationNamed: sumMetricName labels: baseLabels value: eachPoint sum);
				add: (self sampleSpecificationNamed: countMetricName labels: baseLabels value: eachPoint count) ].
	^ sampleSpecifications
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> sampleSpecificationsForMetric: anOTMetricData format: aFormatSymbol [

	| type |
	type := self prometheusMetricTypeFor: anOTMetricData format: aFormatSymbol.
	type = #drop ifTrue: [ ^ #(  ) ].
	^ anOTMetricData prometheusSampleSpecificationsWith: self type: type format: aFormatSymbol
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> sampleSpecificationsForSum: anOTSumMetricData type: aTypeSymbol format: aFormatSymbol [

	aTypeSymbol = #counter ifFalse: [ ^ self sampleSpecificationsForGauge: anOTSumMetricData type: aTypeSymbol format: aFormatSymbol ].
	^ anOTSumMetricData points
		  collect: [ :each |
				  self
					  sampleSpecificationNamed: (self prometheusMetricNameFor: anOTSumMetricData type: #counter format: aFormatSymbol)
					  labels: (self pointLabels: each attributes resource: currentResource scope: anOTSumMetricData instrumentationScope)
					  value: each value
					  exemplar: (self latestExemplarIn: each exemplars) ]
		  as: OrderedCollection
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> sampleSpecificationsForSummary: anOTSummaryMetricData [

	| countMetricName metricName sampleSpecifications sumMetricName |
	metricName := self prometheusMetricNameFor: anOTSummaryMetricData type: #summary.
	sumMetricName := metricName , '_sum'.
	countMetricName := metricName , '_count'.
	sampleSpecifications := OrderedCollection new.
	anOTSummaryMetricData points do: [ :eachPoint |
			| baseLabels |
			baseLabels := self
				              pointLabels: eachPoint attributes
				              resource: currentResource
				              scope: anOTSummaryMetricData instrumentationScope.
			eachPoint quantileValues do: [ :eachQuantile |
					sampleSpecifications add: (self
							 sampleSpecificationNamed: metricName
							 labels: (self labelsByAdding: 'quantile' value: (self prometheusValueStringFor: eachQuantile quantile) to: baseLabels)
							 value: eachQuantile value) ].
			sampleSpecifications
				add: (self sampleSpecificationNamed: sumMetricName labels: baseLabels value: eachPoint sum);
				add: (self sampleSpecificationNamed: countMetricName labels: baseLabels value: eachPoint count) ].
	^ sampleSpecifications
]

{ #category : 'accessing' }
OTPrometheusTextEncoder >> scopeInfoEnabled [

	^ scopeInfoEnabled ifNil: [ true ]
]

{ #category : 'accessing' }
OTPrometheusTextEncoder >> scopeInfoEnabled: aBoolean [

	scopeInfoEnabled := aBoolean
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> suffixForPrometheusMetricType: aTypeSymbol format: aFormatSymbol [

	aTypeSymbol = #counter ifTrue: [ ^ '_total' ].
	(#( #info #infoGauge ) includes: aTypeSymbol) ifTrue: [ ^ '_info' ].
	^ ''
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> supportsPrometheusExemplarsInFormat: aFormatSymbol [

	^ aFormatSymbol = #openMetricsText100
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> supportsUnitMetadataInFormat: aFormatSymbol [

	^ aFormatSymbol ~= #prometheusText004
]

{ #category : 'accessing' }
OTPrometheusTextEncoder >> targetInfoEnabled [

	^ targetInfoEnabled ifNil: [ true ]
]

{ #category : 'accessing' }
OTPrometheusTextEncoder >> targetInfoEnabled: aBoolean [

	targetInfoEnabled := aBoolean
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> typeUsesPrometheusUnitSuffix: aTypeSymbol [

	^ (#( #info #infoGauge #stateset #statesetGauge ) includes: aTypeSymbol) not
]

{ #category : 'accessing' }
OTPrometheusTextEncoder >> translationStrategy [

	^ translationStrategy ifNil: [ self class defaultTranslationStrategy ]
]

{ #category : 'accessing' }
OTPrometheusTextEncoder >> translationStrategy: aSymbol [

	translationStrategy := aSymbol ifNil: [ self class defaultTranslationStrategy ]
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> usesUnderscoreEscaping [

	^ self effectiveEscapingMode = #underscores
]

{ #category : 'accessing' }
OTPrometheusTextEncoder >> warningSink [

	^ warningSink ifNil: [ warningSink := self defaultWarningSink ]
]

{ #category : 'accessing' }
OTPrometheusTextEncoder >> warningSink: aBlockClosure [

	warningSink := aBlockClosure ifNil: [ self defaultWarningSink ] ifNotNil: [ aBlockClosure ].
	^ self warningSink
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> writeGauge: anOTGaugeMetricData on: aStream [

	^ self
		  writeGauge: anOTGaugeMetricData
		  type: #gauge
		  format: #prometheusText004
		  on: aStream
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> writeGauge: anOTGaugeMetricData type: aTypeSymbol format: aFormatSymbol on: aStream [

	| metricName |
	metricName := self prometheusMetricNameFor: anOTGaugeMetricData type: aTypeSymbol format: aFormatSymbol.
	anOTGaugeMetricData points do: [ :each |
			self
				writeSampleNamed: metricName
				labels: (self pointLabels: each attributes resource: currentResource scope: anOTGaugeMetricData instrumentationScope)
				value: (self prometheusValueForGaugeLikePoint: each type: aTypeSymbol)
				on: aStream ]
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> writeHistogram: anOTHistogramMetricData on: aStream [

	| metricName |
	metricName := self prometheusMetricNameFor: anOTHistogramMetricData type: #histogram.
	anOTHistogramMetricData points do: [ :eachPoint |
			| baseLabels cumulative |
			baseLabels := self
				              pointLabels: eachPoint attributes
				              resource: currentResource
				              scope: anOTHistogramMetricData instrumentationScope.
			cumulative := 0.
			1 to: eachPoint explicitBounds size do: [ :index |
					cumulative := cumulative + (eachPoint bucketCounts at: index ifAbsent: [ 0 ]).
					self
						writeSampleNamed: metricName , '_bucket'
						labels:
						(self labelsByAdding: 'le' value: (self prometheusBoundaryStringFor: (eachPoint explicitBounds at: index)) to: baseLabels)
						value: cumulative
						on: aStream ].
			cumulative := cumulative + (eachPoint bucketCounts at: eachPoint explicitBounds size + 1 ifAbsent: [ 0 ]).
			self
				writeSampleNamed: metricName , '_bucket'
				labels: (self labelsByAdding: 'le' value: '+Inf' to: baseLabels)
				value: cumulative
				on: aStream.
			self
				writeSampleNamed: metricName , '_sum'
				labels: baseLabels
				value: eachPoint sum
				on: aStream.
			self
				writeSampleNamed: metricName , '_count'
				labels: baseLabels
				value: eachPoint count
				on: aStream ]
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> writeLabels: someLabels on: aStream [

	| associations |
	associations := someLabels associations asArray.
	aStream nextPut: ${.
	self writePrometheusLabelAssociations: associations on: aStream.
	aStream nextPut: $}
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> writeMetric: anOTMetricData format: aFormatSymbol on: aStream [

	| type |
	type := self prometheusMetricTypeFor: anOTMetricData format: aFormatSymbol.
	anOTMetricData
		writePrometheusWith: self
		type: type
		format: aFormatSymbol
		on: aStream
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> writeMetric: anOTMetricData on: aStream [

	^ self writeMetric: anOTMetricData format: #prometheusText004 on: aStream
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> writeMetricFamilyNamed: aMetricName metrics: someMetrics format: aFormatSymbol on: aStream [

	| chosenDescription chosenType chosenUnit descriptions sampleIdentity typeSymbols types unitValues writtenSampleIdentities |
	typeSymbols := OrderedCollection new.
	someMetrics do: [ :each |
			| type |
			type := self prometheusMetricTypeFor: each format: aFormatSymbol.
			type ~= #drop ifTrue: [ typeSymbols add: type ] ].
	typeSymbols isEmpty ifTrue: [ ^ self ].
	types := typeSymbols asSet.
	types size > 1 ifTrue: [
			self noteDroppedMetricFamilyNamed: aMetricName dueToConflictingTypes: types.
			^ self ].
	descriptions := Set new.
	unitValues := Set new.
	someMetrics do: [ :each |
			| unitWord |
			each description isNotEmpty ifTrue: [ descriptions add: each description ].
			unitWord := (self typeUsesPrometheusUnitSuffix: typeSymbols first)
				            ifTrue: [ self prometheusUnitWordFrom: each unit ]
				            ifFalse: [ nil ].
			(unitWord notNil and: [ unitWord isNotEmpty ]) ifTrue: [ unitValues add: unitWord ] ].
	descriptions size > 1 ifTrue: [
		self noteIgnoredConflictingMetadataNamed: 'HELP' forMetricFamily: aMetricName values: descriptions ].
	unitValues size > 1 ifTrue: [ self noteIgnoredConflictingMetadataNamed: 'UNIT' forMetricFamily: aMetricName values: unitValues ].
	chosenType := self prometheusMetricTypeStringFor: typeSymbols first.
	chosenDescription := ''.
	someMetrics do: [ :each |
		(chosenDescription isEmpty and: [ each description isNotEmpty ]) ifTrue: [ chosenDescription := each description ] ].
	chosenUnit := nil.
	someMetrics do: [ :each |
			| unitWord |
			unitWord := (self typeUsesPrometheusUnitSuffix: typeSymbols first)
				            ifTrue: [ self prometheusUnitWordFrom: each unit ]
				            ifFalse: [ nil ].
			(chosenUnit isNil and: [ unitWord notNil and: [ unitWord isNotEmpty ] ]) ifTrue: [ chosenUnit := unitWord ] ].
	self
		writeMetricHeaderNamed: aMetricName
		help: chosenDescription
		unit: chosenUnit
		type: chosenType
		format: aFormatSymbol
		on: aStream.
	writtenSampleIdentities := Set new.
	someMetrics do: [ :each |
			| duplicateSampleIdentity sampleSpecifications |
			sampleSpecifications := self sampleSpecificationsForMetric: each format: aFormatSymbol.
			duplicateSampleIdentity := self duplicateSampleIdentityIn: sampleSpecifications against: writtenSampleIdentities.
			duplicateSampleIdentity
				ifNil: [
						sampleSpecifications do: [ :specification |
								self writeSampleSpecification: specification on: aStream format: aFormatSymbol.
								sampleIdentity := self sampleIdentityFor: specification.
								writtenSampleIdentities add: sampleIdentity ] ]
				ifNotNil: [ self noteDroppedMetricNamed: each name dueToDuplicatePrometheusSample: duplicateSampleIdentity ] ]
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> writeMetricHeaderNamed: aMetricName help: aHelpString type: aTypeString on: aStream [

	aStream
		nextPutAll: '# HELP ';
		yourself.
	self writePrometheusMetricName: aMetricName on: aStream.
	aStream
		space;
		nextPutAll: (self prometheusHelpStringFor: aHelpString);
		lf;
		nextPutAll: '# TYPE ';
		yourself.
	self writePrometheusMetricName: aMetricName on: aStream.
	aStream
		space;
		nextPutAll: aTypeString;
		lf
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> writeMetricHeaderNamed: aMetricName help: aHelpString unit: aUnitString type: aTypeString format: aFormatSymbol on: aStream [

	aHelpString isNotEmpty ifTrue: [
			aStream
				nextPutAll: '# HELP ';
				yourself.
			self writePrometheusMetricName: aMetricName on: aStream.
			aStream
				space;
				nextPutAll: (self prometheusHelpStringFor: aHelpString);
				lf ].
	aStream
		nextPutAll: '# TYPE ';
		yourself.
	self writePrometheusMetricName: aMetricName on: aStream.
	aStream
		space;
		nextPutAll: aTypeString;
		lf.
	((self supportsUnitMetadataInFormat: aFormatSymbol) and: [ aUnitString ifNil: [ false ] ifNotNil: [ aUnitString isNotEmpty ] ])
		ifTrue: [
				aStream
					nextPutAll: '# UNIT ';
					yourself.
				self writePrometheusMetricName: aMetricName on: aStream.
				aStream
					space;
					nextPutAll: aUnitString;
					lf ]
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> writePrometheusLabelAssociations: someAssociations on: aStream [

	someAssociations doWithIndex: [ :each :index |
			self writePrometheusLabelName: each key on: aStream.
			aStream
				nextPutAll: '="';
				nextPutAll: (self quotedPrometheusValueFor: each value);
				nextPut: $".
			index < someAssociations size ifTrue: [ aStream nextPut: $, ] ]
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> writePrometheusLabelName: aString on: aStream [

	(self requiresQuotedPrometheusLabelName: aString)
		ifTrue: [
				aStream
					nextPut: $";
					nextPutAll: (self escapedPrometheusQuotedNameFrom: aString);
					nextPut: $" ]
		ifFalse: [ aStream nextPutAll: aString ]
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> writePrometheusMetricName: aString on: aStream [

	(self requiresQuotedPrometheusMetricName: aString)
		ifTrue: [
				aStream
					nextPut: $";
					nextPutAll: (self escapedPrometheusQuotedNameFrom: aString);
					nextPut: $" ]
		ifFalse: [ aStream nextPutAll: aString ]
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> writePrometheusSampleName: aMetricName labels: someLabels on: aStream [

	| associations |
	associations := someLabels associations asArray.
	(self requiresQuotedPrometheusMetricName: aMetricName)
		ifTrue: [
				aStream nextPut: ${.
				self writePrometheusMetricName: aMetricName on: aStream.
				associations isEmpty ifFalse: [
						aStream nextPut: $,.
						self writePrometheusLabelAssociations: associations on: aStream ].
				aStream nextPut: $} ]
		ifFalse: [
				aStream nextPutAll: aMetricName.
				associations isEmpty ifFalse: [ self writeLabels: someLabels on: aStream ] ]
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> writePrometheusExemplar: anOTMetricExemplar format: aFormatSymbol on: aStream [

	| labels |
	(self supportsPrometheusExemplarsInFormat: aFormatSymbol) ifFalse: [ ^ self ].
	anOTMetricExemplar ifNil: [ ^ self ].
	labels := self prometheusExemplarLabelsFor: anOTMetricExemplar format: aFormatSymbol.
	aStream nextPutAll: ' # '.
	self writeLabels: labels on: aStream.
	aStream
		space;
		nextPutAll: (self prometheusValueStringFor: anOTMetricExemplar value).
	anOTMetricExemplar timestamp ifNotNil: [
			aStream
				space;
				nextPutAll: (self prometheusTimestampStringFor: anOTMetricExemplar timestamp) ]
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> writeSampleNamed: aMetricName labels: someLabels value: aValue on: aStream [

	| labels |
	labels := self prometheusLabelsFromAssociations: someLabels.
	self writePrometheusSampleName: aMetricName labels: labels on: aStream.
	aStream
		space;
		nextPutAll: (self prometheusValueStringFor: aValue);
		lf
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> writeSampleSpecification: aSampleSpecification on: aStream [

	self writeSampleSpecification: aSampleSpecification on: aStream format: #prometheusText004
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> writeSampleSpecification: aSampleSpecification on: aStream format: aFormatSymbol [

	| labels |
	labels := self prometheusLabelsFromAssociations: aSampleSpecification second.
	self writePrometheusSampleName: aSampleSpecification first labels: labels on: aStream.
	aStream
		space;
		nextPutAll: (self prometheusValueStringFor: aSampleSpecification third).
	self writePrometheusExemplar: (aSampleSpecification at: 4 ifAbsent: [ nil ]) format: aFormatSymbol on: aStream.
	aStream lf
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> writeSnapshot: anOTMetricSnapshot format: aFormatSymbol on: aStream [

	| metricFamilies |
	self targetInfoEnabled ifTrue: [ self writeTargetInfoFor: anOTMetricSnapshot resource on: aStream ].
	metricFamilies := OrderedDictionary new.
	anOTMetricSnapshot metrics do: [ :each |
			| type familyName |
			type := self prometheusMetricTypeFor: each format: aFormatSymbol.
			type = #drop ifFalse: [
					familyName := self prometheusMetricNameFor: each type: type format: aFormatSymbol.
					(metricFamilies at: familyName ifAbsentPut: [ OrderedCollection new ]) add: each ] ].
	metricFamilies associationsDo: [ :each |
			self
				writeMetricFamilyNamed: each key
				metrics: each value
				format: aFormatSymbol
				on: aStream ].
	aFormatSymbol = #openMetricsText100 ifTrue: [
			aStream
				nextPutAll: '# EOF';
				lf ]
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> writeSum: anOTSumMetricData on: aStream [

	| metricName metricSymbol |
	metricSymbol := anOTSumMetricData monotonic
		                ifTrue: [ #counter ]
		                ifFalse: [ #gauge ].
	metricName := self prometheusMetricNameFor: anOTSumMetricData type: metricSymbol.
	anOTSumMetricData points do: [ :each |
			self
				writeSampleNamed: metricName
				labels: (self pointLabels: each attributes resource: currentResource scope: anOTSumMetricData instrumentationScope)
				value: each value
				on: aStream ]
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> writeSum: anOTSumMetricData type: aTypeSymbol format: aFormatSymbol on: aStream [

	aTypeSymbol = #counter ifFalse: [
			^ self
				  writeGauge: anOTSumMetricData
				  type: aTypeSymbol
				  format: aFormatSymbol
				  on: aStream ].
	^ self writeSum: anOTSumMetricData on: aStream
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> writeSummary: anOTSummaryMetricData on: aStream [

	| metricName |
	metricName := self prometheusMetricNameFor: anOTSummaryMetricData type: #summary.
	anOTSummaryMetricData points do: [ :eachPoint |
			| baseLabels |
			baseLabels := self
				              pointLabels: eachPoint attributes
				              resource: currentResource
				              scope: anOTSummaryMetricData instrumentationScope.
			eachPoint quantileValues do: [ :eachQuantile |
					self
						writeSampleNamed: metricName
						labels: (self labelsByAdding: 'quantile' value: (self prometheusValueStringFor: eachQuantile quantile) to: baseLabels)
						value: eachQuantile value
						on: aStream ].
			self
				writeSampleNamed: metricName , '_sum'
				labels: baseLabels
				value: eachPoint sum
				on: aStream.
			self
				writeSampleNamed: metricName , '_count'
				labels: baseLabels
				value: eachPoint count
				on: aStream ]
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> writeTargetInfoFor: anOTResource on: aStream [

	| rawLabels |
	anOTResource ifNil: [ ^ self ].
	anOTResource isEmpty ifTrue: [ ^ self ].
	rawLabels := OrderedCollection new.
	rawLabels
		add: 'job' -> (self jobLabelForResource: anOTResource);
		add: 'instance' -> (self prometheusStringValueFor: (anOTResource attributeAt: 'service.instance.id' ifAbsent: [ '' ])).
	anOTResource allAttributes associationsDo: [ :each |
		rawLabels add: each key asString -> (self prometheusStringValueFor: each value) ].
	self
		writeMetricHeaderNamed: 'target_info'
		help: 'Target metadata'
		type: 'gauge'
		on: aStream.
	self
		writeSampleNamed: 'target_info'
		labels: rawLabels
		value: 1
		on: aStream
]
