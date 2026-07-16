Class {
	#name : 'OTPrometheusTextEncoder',
	#superclass : 'Object',
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

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

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> prometheusMetricNameFor: anOTMetricData type: aTypeSymbol [

	| metricName |
	metricName := self normalizedPrometheusNameFrom: anOTMetricData name allowingColon: true.
	(aTypeSymbol = #counter and: [ (metricName endsWith: '_total') not ])
		ifTrue: [ ^ metricName , '_total' ].
	^ metricName
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> prometheusLabelNameFor: aString [

	^ self normalizedPrometheusNameFrom: aString allowingColon: false
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> prometheusStringValueFor: anObject [

	anObject ifNil: [ ^ '' ].
	anObject isString ifTrue: [ ^ anObject ].
	^ anObject printString
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> prometheusValueStringFor: aNumber [

	^ aNumber printString
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> prometheusBoundaryStringFor: aNumber [

	aNumber = Float infinity ifTrue: [ ^ '+Inf' ].
	aNumber = Float negativeInfinity ifTrue: [ ^ '-Inf' ].
	^ aNumber printString
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

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> joinValues: someValues [

	^ String streamContents: [ :stream |
		someValues doWithIndex: [ :each :index |
			index > 1 ifTrue: [ stream nextPut: $; ].
			stream nextPutAll: each ] ]
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
OTPrometheusTextEncoder >> pointLabels: someAttributes scope: anOTInstrumentationScope [

	| rawLabels reservedScopeLabels |
	rawLabels := OrderedCollection new.
	someAttributes associationsDo: [ :each |
		rawLabels add: each key asString -> (self prometheusStringValueFor: each value) ].
	rawLabels
		add: 'otel_scope_name' -> anOTInstrumentationScope name;
		add: 'otel_scope_version' -> anOTInstrumentationScope version;
		add: 'otel_scope_schema_url' -> anOTInstrumentationScope schemaUrl.
	reservedScopeLabels := Set withAll: #( 'otel_scope_name' 'otel_scope_version' 'otel_scope_schema_url' ).
	anOTInstrumentationScope allAttributes associationsDo: [ :each |
		| prefixed normalized |
		prefixed := 'otel_scope_' , each key asString.
		normalized := self prometheusLabelNameFor: prefixed.
		(reservedScopeLabels includes: normalized) ifFalse: [
			rawLabels add: prefixed -> (self prometheusStringValueFor: each value) ] ].
	^ self prometheusLabelsFromAssociations: rawLabels
]

{ #category : 'private - formatting' }
OTPrometheusTextEncoder >> labelsByAdding: aLabelName value: aValue to: someLabels [

	| labels |
	labels := someLabels copy.
	labels at: aLabelName put: aValue.
	^ labels
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
OTPrometheusTextEncoder >> writeSampleNamed: aMetricName labels: someLabels value: aValue on: aStream [

	aStream nextPutAll: aMetricName.
	someLabels isEmpty ifFalse: [ self writeLabels: someLabels on: aStream ].
	aStream
		space;
		nextPutAll: (self prometheusValueStringFor: aValue);
		lf
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> writeGauge: anOTGaugeMetricData on: aStream [

	| metricName |
	metricName := self prometheusMetricNameFor: anOTGaugeMetricData type: #gauge.
	self
		writeMetricHeaderNamed: metricName
		help: anOTGaugeMetricData description
		type: 'gauge'
		on: aStream.
	anOTGaugeMetricData points do: [ :each |
		self
			writeSampleNamed: metricName
			labels: (self
				pointLabels: each attributes
				scope: anOTGaugeMetricData instrumentationScope)
			value: each value
			on: aStream ]
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> writeSum: anOTSumMetricData on: aStream [

	| metricName metricType metricSymbol |
	metricType := anOTSumMetricData monotonic
		ifTrue: [ 'counter' ]
		ifFalse: [ 'gauge' ].
	metricSymbol := anOTSumMetricData monotonic
		ifTrue: [ #counter ]
		ifFalse: [ #gauge ].
	metricName := self prometheusMetricNameFor: anOTSumMetricData type: metricSymbol.
	self
		writeMetricHeaderNamed: metricName
		help: anOTSumMetricData description
		type: metricType
		on: aStream.
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
OTPrometheusTextEncoder >> writeHistogram: anOTHistogramMetricData on: aStream [

	| metricName |
	metricName := self prometheusMetricNameFor: anOTHistogramMetricData type: #histogram.
	self
		writeMetricHeaderNamed: metricName
		help: anOTHistogramMetricData description
		type: 'histogram'
		on: aStream.
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
OTPrometheusTextEncoder >> writeTargetInfoFor: anOTResource on: aStream [

	| labels rawLabels |
	anOTResource ifNil: [ ^ self ].
	anOTResource isEmpty ifTrue: [ ^ self ].
	rawLabels := OrderedCollection new.
	rawLabels
		add: 'job' -> (self jobLabelForResource: anOTResource);
		add: 'instance'
			-> (self
				prometheusStringValueFor:
					(anOTResource attributeAt: 'service.instance.id' ifAbsent: [ '' ])).
	anOTResource allAttributes associationsDo: [ :each |
		rawLabels add: each key asString -> (self prometheusStringValueFor: each value) ].
	labels := self prometheusLabelsFromAssociations: rawLabels.
	self
		writeMetricHeaderNamed: 'target_info'
		help: 'Target metadata'
		type: 'gauge'
		on: aStream.
	self
		writeSampleNamed: 'target_info'
		labels: labels
		value: 1
		on: aStream
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> writeMetric: anOTMetricData on: aStream [

	anOTMetricData class = OTGaugeMetricData ifTrue: [
		^ self writeGauge: anOTMetricData on: aStream ].
	anOTMetricData class = OTSumMetricData ifTrue: [
		^ self writeSum: anOTMetricData on: aStream ].
	anOTMetricData class = OTHistogramMetricData ifTrue: [
		^ self writeHistogram: anOTMetricData on: aStream ].
	anOTMetricData class = OTExponentialHistogramMetricData ifTrue: [ ^ self ].
	^ self
]

{ #category : 'private - writing' }
OTPrometheusTextEncoder >> writeSnapshot: anOTMetricSnapshot format: aFormatSymbol on: aStream [

	self writeTargetInfoFor: anOTMetricSnapshot resource on: aStream.
	anOTMetricSnapshot metrics do: [ :each |
		self writeMetric: each on: aStream ].
	aFormatSymbol = #openMetricsText100 ifTrue: [
		aStream
			nextPutAll: '# EOF';
			lf ]
]
