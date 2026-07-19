Class {
	#name : 'OTPrometheusTextEncoder',
	#superclass : 'Object',
	#instVars : [
		'warningSink'
	],
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

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

	^ String streamContents: [ :stream |
		self
			writeSnapshot: anOTMetricSnapshot
			format: aFormatSymbol
			on: stream ]
]

{ #category : 'initialization' }
OTPrometheusTextEncoder >> initialize [

	super initialize.
	warningSink := self defaultWarningSink
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
	^ (value >= 65 and: [ value <= 90 ])
		or: [ value >= 97 and: [ value <= 122 ] ]
]

{ #category : 'private - testing' }
OTPrometheusTextEncoder >> isPrometheusNameCharacter: aCharacter allowingColon: aBoolean [

	^ (self isAsciiLetter: aCharacter)
		or: [ (self isAsciiDigit: aCharacter)
			or: [ aCharacter = $_
				or: [ aBoolean and: [ aCharacter = $: ] ] ] ]
]

{ #category : 'private - testing' }
OTPrometheusTextEncoder >> isPrometheusNameStartCharacter: aCharacter [

	^ (self isAsciiLetter: aCharacter) or: [ aCharacter = $_ ]
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

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> normalizedPrometheusNameFrom: aString allowingColon: aBoolean [

	| normalized previousUnderscore stream |
	stream := String new writeStream.
	previousUnderscore := false.
	aString asString do: [ :each |
		| character |
		character := (self
			isPrometheusNameCharacter: each
			allowingColon: aBoolean)
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
	(self isPrometheusNameStartCharacter: normalized first)
		ifTrue: [ ^ normalized ].
	^ '_' , normalized
]

{ #category : 'private - logging' }
OTPrometheusTextEncoder >> noteDroppedMetricFamilyNamed: aMetricName dueToConflictingTypes: someTypes [

	self warningSink value:
		'OpenTelemetry dropped Prometheus metric family due to conflicting types for '
			, aMetricName printString
			, ': '
			, (String streamContents: [ :stream |
				(someTypes asArray sort)
					doWithIndex: [ :each :index |
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
		'OpenTelemetry ignored conflicting Prometheus '
			, aMetadataName
			, ' metadata for '
			, aMetricName printString
			, ': '
			, (String streamContents: [ :stream |
				(someValues asArray sort)
					doWithIndex: [ :each :index |
						index > 1 ifTrue: [ stream nextPutAll: ', ' ].
						stream nextPutAll: each printString ] ])
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> pointLabels: someAttributes scope: anOTInstrumentationScope [

	| rawLabels reservedScopeLabels |
	rawLabels := OrderedCollection new.
	someAttributes associationsDo: [ :each | rawLabels add: each key asString -> (self prometheusStringValueFor: each value) ].
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
			((each ~= $\) and: [ each ~= Character lf and: [ each ~= Character cr ] ])
								ifTrue: [ stream nextPut: each ] ] ]
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> prometheusLabelNameFor: aString [

	^ self normalizedPrometheusNameFrom: aString allowingColon: false
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
	(grouped keys asSortedCollection) do: [ :eachLabel |
		| values |
		values := (grouped at: eachLabel) asSortedCollection: [ :left :right |
			left key asString <= right key asString ].
		result
			at: eachLabel
			put: (self joinValues: (values collect: [ :each | each value ])) ].
	^ result
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> prometheusMetricNameFor: anOTMetricData type: aTypeSymbol [

	^ self
		prometheusMetricNameFor: anOTMetricData
		type: aTypeSymbol
		format: #prometheusText004
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> prometheusMetricNameFor: anOTMetricData type: aTypeSymbol format: aFormatSymbol [

	| suffix stem unitWord |
	stem := self prometheusMetricStemFor: anOTMetricData type: aTypeSymbol.
	unitWord := (self typeUsesPrometheusUnitSuffix: aTypeSymbol)
		ifTrue: [ self prometheusUnitWordFrom: anOTMetricData unit ]
		ifFalse: [ nil ].
	(unitWord notNil and: [
		((stem endsWith: '_' , unitWord) not)
			and: [ stem ~= unitWord ] ])
		ifTrue: [ stem := stem , '_' , unitWord ].
	suffix := self suffixForPrometheusMetricType: aTypeSymbol format: aFormatSymbol.
	^ stem , suffix
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> prometheusMetricStemFor: anOTMetricData type: aTypeSymbol [

	| normalizedName |
	normalizedName := self
		normalizedPrometheusNameFrom: anOTMetricData name
		allowingColon: true.
	(aTypeSymbol = #counter and: [ normalizedName endsWith: '_total' ])
		ifTrue: [ ^ normalizedName allButLast: '_total' size ].
	((#( #info #infoGauge ) includes: aTypeSymbol)
		and: [ normalizedName endsWith: '_info' ])
		ifTrue: [ ^ normalizedName allButLast: '_info' size ].
	^ normalizedName
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> prometheusMetricTypeFor: anOTMetricData [

	^ self
		prometheusMetricTypeFor: anOTMetricData
		format: #prometheusText004
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
OTPrometheusTextEncoder >> prometheusTypeHintFor: anOTMetricData [

	| normalized |
	normalized := anOTMetricData
		metadataValueAt: 'prometheus.type'
		ifAbsent: [ ^ nil ].
	normalized := normalized asString trimBoth asLowercase.
	normalized = 'unkown' ifTrue: [ normalized := 'unknown' ].
	(#( 'gauge' 'unknown' 'info' 'stateset' ) includes: normalized)
		ifFalse: [ ^ nil ].
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
			each = ${ ifTrue: [
				depth := depth + 1 ] ifFalse: [
					each = $} ifTrue: [
						depth := (depth - 1) max: 0 ] ifFalse: [
							depth = 0 ifTrue: [ stream nextPut: each ] ] ] ] ].
	cleaned := cleaned trimBoth.
	cleaned isEmpty ifTrue: [ ^ nil ].
	cleaned = '1' ifTrue: [ ^ nil ].
	slashIndex := cleaned indexOf: $/ ifAbsent: [ 0 ].
	slashIndex > 0 ifTrue: [
		numerator := (cleaned copyFrom: 1 to: slashIndex - 1) trimBoth.
		denominator := (cleaned copyFrom: slashIndex + 1 to: cleaned size) trimBoth.
		((numerator isEmpty) or: [ denominator isEmpty ]) ifTrue: [
			^ self prometheusUnitPartWordFrom: cleaned ].
		((self prometheusUnitPartWordFrom: numerator) isNil
			or: [ (self prometheusUnitPartWordFrom: denominator) isNil ]) ifTrue: [
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
			((each ~= $\)
				and: [ each ~= $"
				and: [ each ~= Character lf and: [ each ~= Character cr ] ] ])
								ifTrue: [ stream nextPut: each ] ] ]
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

	^ {
		  aMetricName.
		  someLabels.
		  aValue }
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> sampleSpecificationsForGauge: anOTGaugeMetricData type: aTypeSymbol format: aFormatSymbol [

	| metricName sampleSpecifications |
	metricName := self prometheusMetricNameFor: anOTGaugeMetricData type: aTypeSymbol format: aFormatSymbol.
	sampleSpecifications := OrderedCollection new: anOTGaugeMetricData points size.
	anOTGaugeMetricData points do: [ :each |
			sampleSpecifications add: (self
					 sampleSpecificationNamed: metricName
					 labels: (self pointLabels: each attributes scope: anOTGaugeMetricData instrumentationScope)
					 value: (self prometheusValueForGaugeLikePoint: each type: aTypeSymbol)) ].
	^ sampleSpecifications
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> sampleSpecificationsForHistogram: anOTHistogramMetricData [

	| metricName sampleSpecifications |
	metricName := self prometheusMetricNameFor: anOTHistogramMetricData type: #histogram.
	sampleSpecifications := OrderedCollection new.
	anOTHistogramMetricData points do: [ :eachPoint |
			| baseLabels cumulative |
			baseLabels := self pointLabels: eachPoint attributes scope: anOTHistogramMetricData instrumentationScope.
			cumulative := 0.
			1 to: eachPoint explicitBounds size do: [ :index |
					cumulative := cumulative + (eachPoint bucketCounts at: index ifAbsent: [ 0 ]).
					sampleSpecifications add: (self
							 sampleSpecificationNamed: metricName , '_bucket'
							 labels:
							 (self labelsByAdding: 'le' value: (self prometheusBoundaryStringFor: (eachPoint explicitBounds at: index)) to: baseLabels)
							 value: cumulative) ].
			cumulative := cumulative + (eachPoint bucketCounts at: eachPoint explicitBounds size + 1 ifAbsent: [ 0 ]).
			sampleSpecifications
				add: (self
						 sampleSpecificationNamed: metricName , '_bucket'
						 labels: (self labelsByAdding: 'le' value: '+Inf' to: baseLabels)
						 value: cumulative);
				add: (self sampleSpecificationNamed: metricName , '_sum' labels: baseLabels value: eachPoint sum);
				add: (self sampleSpecificationNamed: metricName , '_count' labels: baseLabels value: eachPoint count) ].
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
					  labels: (self pointLabels: each attributes scope: anOTSumMetricData instrumentationScope)
					  value: each value ]
		  as: OrderedCollection
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> sampleSpecificationsForSummary: anOTSummaryMetricData [

	| metricName sampleSpecifications |
	metricName := self prometheusMetricNameFor: anOTSummaryMetricData type: #summary.
	sampleSpecifications := OrderedCollection new.
	anOTSummaryMetricData points do: [ :eachPoint |
			| baseLabels |
			baseLabels := self pointLabels: eachPoint attributes scope: anOTSummaryMetricData instrumentationScope.
			eachPoint quantileValues do: [ :eachQuantile |
					sampleSpecifications add: (self
							 sampleSpecificationNamed: metricName
							 labels: (self labelsByAdding: 'quantile' value: (self prometheusValueStringFor: eachQuantile quantile) to: baseLabels)
							 value: eachQuantile value) ].
			sampleSpecifications
				add: (self sampleSpecificationNamed: metricName , '_sum' labels: baseLabels value: eachPoint sum);
				add: (self sampleSpecificationNamed: metricName , '_count' labels: baseLabels value: eachPoint count) ].
	^ sampleSpecifications
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> suffixForPrometheusMetricType: aTypeSymbol format: aFormatSymbol [

	aTypeSymbol = #counter ifTrue: [ ^ '_total' ].
	(#( #info #infoGauge ) includes: aTypeSymbol) ifTrue: [ ^ '_info' ].
	^ ''
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> supportsUnitMetadataInFormat: aFormatSymbol [

	^ aFormatSymbol ~= #prometheusText004
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> typeUsesPrometheusUnitSuffix: aTypeSymbol [

	^ (#( #info #infoGauge #stateset #statesetGauge ) includes: aTypeSymbol) not
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
	metricName := self
		prometheusMetricNameFor: anOTGaugeMetricData
		type: aTypeSymbol
		format: aFormatSymbol.
	anOTGaugeMetricData points do: [ :each |
		self
			writeSampleNamed: metricName
			labels: (self
				pointLabels: each attributes
				scope: anOTGaugeMetricData instrumentationScope)
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
			scope: anOTHistogramMetricData instrumentationScope.
		cumulative := 0.
		1 to: eachPoint explicitBounds size do: [ :index |
			cumulative := cumulative + (eachPoint bucketCounts at: index ifAbsent: [ 0 ]).
			self
				writeSampleNamed: metricName , '_bucket'
				labels: (self
					labelsByAdding: 'le'
					value: (self prometheusBoundaryStringFor: (eachPoint explicitBounds at: index))
					to: baseLabels)
				value: cumulative
				on: aStream ].
		cumulative := cumulative
			+ (eachPoint bucketCounts
				at: eachPoint explicitBounds size + 1
				ifAbsent: [ 0 ]).
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
	associations doWithIndex: [ :each :index |
		aStream
			nextPutAll: each key;
			nextPutAll: '="';
			nextPutAll: (self quotedPrometheusValueFor: each value);
			nextPut: $".
		index < associations size ifTrue: [ aStream nextPut: $, ] ].
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

	^ self
		writeMetric: anOTMetricData
		format: #prometheusText004
		on: aStream
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
								self writeSampleSpecification: specification on: aStream.
								sampleIdentity := self sampleIdentityFor: specification.
								writtenSampleIdentities add: sampleIdentity ] ]
				ifNotNil: [ self noteDroppedMetricNamed: each name dueToDuplicatePrometheusSample: duplicateSampleIdentity ] ]
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> writeMetricHeaderNamed: aMetricName help: aHelpString type: aTypeString on: aStream [

	aStream
		nextPutAll: '# HELP ';
		nextPutAll: aMetricName;
		space;
		nextPutAll: (self prometheusHelpStringFor: aHelpString);
		lf;
		nextPutAll: '# TYPE ';
		nextPutAll: aMetricName;
		space;
		nextPutAll: aTypeString;
		lf
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> writeMetricHeaderNamed: aMetricName help: aHelpString unit: aUnitString type: aTypeString format: aFormatSymbol on: aStream [

	aHelpString isNotEmpty ifTrue: [
		aStream
			nextPutAll: '# HELP ';
			nextPutAll: aMetricName;
			space;
			nextPutAll: (self prometheusHelpStringFor: aHelpString);
			lf ].
	aStream
		nextPutAll: '# TYPE ';
		nextPutAll: aMetricName;
		space;
		nextPutAll: aTypeString;
		lf.
	((self supportsUnitMetadataInFormat: aFormatSymbol)
		and: [ aUnitString ifNil: [ false ] ifNotNil: [ aUnitString isNotEmpty ] ])
		ifTrue: [
			aStream
				nextPutAll: '# UNIT ';
				nextPutAll: aMetricName;
				space;
				nextPutAll: aUnitString;
				lf ]
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> writeSampleNamed: aMetricName labels: someLabels value: aValue on: aStream [

	| labels |
	labels := self prometheusLabelsFromAssociations: someLabels.
	aStream nextPutAll: aMetricName.
	labels isEmpty ifFalse: [ self writeLabels: labels on: aStream ].
	aStream
		space;
		nextPutAll: (self prometheusValueStringFor: aValue);
		lf
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> writeSampleSpecification: aSampleSpecification on: aStream [

	self
		writeSampleNamed: aSampleSpecification first
		labels: aSampleSpecification second
		value: aSampleSpecification third
		on: aStream
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> writeSnapshot: anOTMetricSnapshot format: aFormatSymbol on: aStream [

	| metricFamilies |
	self writeTargetInfoFor: anOTMetricSnapshot resource on: aStream.
	metricFamilies := OrderedDictionary new.
	anOTMetricSnapshot metrics do: [ :each |
		| type familyName |
		type := self prometheusMetricTypeFor: each format: aFormatSymbol.
		type = #drop ifFalse: [
			familyName := self
				prometheusMetricNameFor: each
				type: type
				format: aFormatSymbol.
			(metricFamilies
				at: familyName
				ifAbsentPut: [ OrderedCollection new ]) add: each ] ].
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
	metricSymbol := anOTSumMetricData monotonic ifTrue: [ #counter ] ifFalse: [ #gauge ].
	metricName := self prometheusMetricNameFor: anOTSumMetricData type: metricSymbol.
	anOTSumMetricData points do: [ :each |
		self
			writeSampleNamed: metricName
			labels: (self
				pointLabels: each attributes
				scope: anOTSumMetricData instrumentationScope)
			value: each value
			on: aStream ]
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> writeSum: anOTSumMetricData type: aTypeSymbol format: aFormatSymbol on: aStream [

	aTypeSymbol = #counter ifFalse: [
		^ self writeGauge: anOTSumMetricData type: aTypeSymbol format: aFormatSymbol on: aStream ].
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
			scope: anOTSummaryMetricData instrumentationScope.
		eachPoint quantileValues do: [ :eachQuantile |
			self
				writeSampleNamed: metricName
				labels: (self
					labelsByAdding: 'quantile'
					value: (self prometheusValueStringFor: eachQuantile quantile)
					to: baseLabels)
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
