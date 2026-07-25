"
An OTLP metric encoder that emits the OpenTelemetry JSON protobuf shape for ExportMetricsServiceRequest payloads.
"
Class {
	#name : 'OTOtlpJsonMetricEncoder',
	#superclass : 'OTOtlpJsonTraceEncoder',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'encoding' }
OTOtlpJsonMetricEncoder >> encodeSnapshot: anOTMetricSnapshot [

	^ OrderedDictionary new
		  at: 'resourceMetrics' put: (self resourceMetricsDataFor: anOTMetricSnapshot);
		  yourself
]

{ #category : 'private - encoding' }
OTOtlpJsonMetricEncoder >> exemplarDataFor: anOTMetricExemplar [

	| data |
	data := OrderedDictionary new.
	data
		at: 'timeUnixNano' put: (self unixNanosecondsStringFor: anOTMetricExemplar timestamp);
		at: 'filteredAttributes' put: (self keyValueDataFrom: anOTMetricExemplar filteredAttributes).
	anOTMetricExemplar value isInteger
		ifTrue: [ data at: 'asInt' put: anOTMetricExemplar value asString ]
		ifFalse: [ data at: 'asDouble' put: anOTMetricExemplar value asFloat ].
	anOTMetricExemplar spanId ifNotNil: [ data at: 'spanId' put: anOTMetricExemplar spanId ].
	anOTMetricExemplar traceId ifNotNil: [ data at: 'traceId' put: anOTMetricExemplar traceId ].
	^ data
]

{ #category : 'private - encoding' }
OTOtlpJsonMetricEncoder >> exponentialBucketRangeDataFor: anOTExponentialBucketRange [

	^ OrderedDictionary new
		  at: 'offset' put: anOTExponentialBucketRange offset;
		  at: 'bucketCounts' put: (anOTExponentialBucketRange bucketCounts collect: [ :each | each asString ]) asArray;
		  yourself
]

{ #category : 'private - encoding' }
OTOtlpJsonMetricEncoder >> exponentialHistogramDataFor: anOTExponentialHistogramMetricData [

	| data |
	data := OrderedDictionary new.
	data
		at: 'dataPoints'
		put: (anOTExponentialHistogramMetricData points collect: [ :each | self exponentialHistogramDataPointDataFor: each ]) asArray;
		at: 'aggregationTemporality' put: (self temporalityCodeFor: anOTExponentialHistogramMetricData temporality).
	^ data
]

{ #category : 'private - encoding' }
OTOtlpJsonMetricEncoder >> exponentialHistogramDataPointDataFor: anOTExponentialHistogramDataPoint [

	| data |
	data := OrderedDictionary new.
	anOTExponentialHistogramDataPoint startTimestamp ifNotNil: [
		data at: 'startTimeUnixNano' put: (self unixNanosecondsStringFor: anOTExponentialHistogramDataPoint startTimestamp) ].
	data
		at: 'timeUnixNano' put: (self unixNanosecondsStringFor: anOTExponentialHistogramDataPoint timestamp);
		at: 'count' put: anOTExponentialHistogramDataPoint count asString;
		at: 'sum' put: anOTExponentialHistogramDataPoint sum asFloat;
		at: 'scale' put: anOTExponentialHistogramDataPoint scale;
		at: 'zeroCount' put: anOTExponentialHistogramDataPoint zeroCount asString;
		at: 'positive' put: (self exponentialBucketRangeDataFor: anOTExponentialHistogramDataPoint positiveBuckets);
		at: 'negative' put: (self exponentialBucketRangeDataFor: anOTExponentialHistogramDataPoint negativeBuckets);
		at: 'attributes' put: (self keyValueDataFrom: anOTExponentialHistogramDataPoint attributes).
	anOTExponentialHistogramDataPoint min ifNotNil: [ data at: 'min' put: anOTExponentialHistogramDataPoint min asFloat ].
	anOTExponentialHistogramDataPoint max ifNotNil: [ data at: 'max' put: anOTExponentialHistogramDataPoint max asFloat ].
	anOTExponentialHistogramDataPoint zeroThreshold = 0 ifFalse: [
		data at: 'zeroThreshold' put: anOTExponentialHistogramDataPoint zeroThreshold asFloat ].
	anOTExponentialHistogramDataPoint exemplars ifNotEmpty: [
		data at: 'exemplars' put: (anOTExponentialHistogramDataPoint exemplars collect: [ :each | self exemplarDataFor: each ]) asArray ].
	^ data
]

{ #category : 'private - encoding' }
OTOtlpJsonMetricEncoder >> gaugeDataFor: anOTGaugeMetricData [

	^ OrderedDictionary new
		  at: 'dataPoints' put: (anOTGaugeMetricData points collect: [ :each | self numberDataPointDataFor: each ]) asArray;
		  yourself
]

{ #category : 'private - encoding' }
OTOtlpJsonMetricEncoder >> groupedMetricsFrom: someMetrics [

	| groupedMetrics |
	groupedMetrics := OrderedDictionary new.
	(someMetrics ifNil: [ #(  ) ]) do: [ :eachMetric |
		(groupedMetrics at: eachMetric instrumentationScope ifAbsentPut: [ OrderedCollection new ]) add: eachMetric ].
	^ groupedMetrics
]

{ #category : 'private - encoding' }
OTOtlpJsonMetricEncoder >> histogramDataFor: anOTHistogramMetricData [

	| data |
	data := OrderedDictionary new.
	data
		at: 'dataPoints' put: (anOTHistogramMetricData points collect: [ :each | self histogramDataPointDataFor: each ]) asArray;
		at: 'aggregationTemporality' put: (self temporalityCodeFor: anOTHistogramMetricData temporality).
	^ data
]

{ #category : 'private - encoding' }
OTOtlpJsonMetricEncoder >> histogramDataPointDataFor: anOTHistogramDataPoint [

	| data |
	data := OrderedDictionary new.
	anOTHistogramDataPoint startTimestamp ifNotNil: [
		data at: 'startTimeUnixNano' put: (self unixNanosecondsStringFor: anOTHistogramDataPoint startTimestamp) ].
	data
		at: 'timeUnixNano' put: (self unixNanosecondsStringFor: anOTHistogramDataPoint timestamp);
		at: 'count' put: anOTHistogramDataPoint count asString;
		at: 'sum' put: anOTHistogramDataPoint sum asFloat;
		at: 'attributes' put: (self keyValueDataFrom: anOTHistogramDataPoint attributes);
		at: 'bucketCounts' put: (anOTHistogramDataPoint bucketCounts collect: [ :each | each asString ]) asArray;
		at: 'explicitBounds' put: (anOTHistogramDataPoint explicitBounds collect: [ :each | each asFloat ]) asArray.
	anOTHistogramDataPoint min ifNotNil: [ data at: 'min' put: anOTHistogramDataPoint min asFloat ].
	anOTHistogramDataPoint max ifNotNil: [ data at: 'max' put: anOTHistogramDataPoint max asFloat ].
	anOTHistogramDataPoint exemplars ifNotEmpty: [
		data at: 'exemplars' put: (anOTHistogramDataPoint exemplars collect: [ :each | self exemplarDataFor: each ]) asArray ].
	^ data
]

{ #category : 'private - encoding' }
OTOtlpJsonMetricEncoder >> metricDataFor: anOTMetricData [

	| data |
	data := OrderedDictionary new.
	data
		at: 'name' put: anOTMetricData name;
		at: 'description' put: anOTMetricData description;
		at: 'unit' put: anOTMetricData unit.
	anOTMetricData metadata ifNotEmpty: [ data at: 'metadata' put: (self keyValueDataFrom: anOTMetricData metadata) ].
	anOTMetricData addOtlpJsonDataTo: data encoder: self.
	^ data
]

{ #category : 'private - encoding' }
OTOtlpJsonMetricEncoder >> numberDataPointDataFor: anOTNumberDataPoint [

	| data |
	data := OrderedDictionary new.
	anOTNumberDataPoint startTimestamp ifNotNil: [
		data at: 'startTimeUnixNano' put: (self unixNanosecondsStringFor: anOTNumberDataPoint startTimestamp) ].
	data
		at: 'timeUnixNano' put: (self unixNanosecondsStringFor: anOTNumberDataPoint timestamp);
		at: 'attributes' put: (self keyValueDataFrom: anOTNumberDataPoint attributes).
	anOTNumberDataPoint value isInteger
		ifTrue: [ data at: 'asInt' put: anOTNumberDataPoint value asString ]
		ifFalse: [ data at: 'asDouble' put: anOTNumberDataPoint value asFloat ].
	anOTNumberDataPoint exemplars ifNotEmpty: [
		data at: 'exemplars' put: (anOTNumberDataPoint exemplars collect: [ :each | self exemplarDataFor: each ]) asArray ].
	^ data
]

{ #category : 'private - encoding' }
OTOtlpJsonMetricEncoder >> resourceMetricsDataFor: anOTMetricSnapshot [

	| data groupedMetrics resource |
	anOTMetricSnapshot metrics ifEmpty: [ ^ #(  ) ].
	resource := anOTMetricSnapshot resource.
	groupedMetrics := self groupedMetricsFrom: anOTMetricSnapshot metrics.
	data := OrderedDictionary new.
	data
		at: 'resource' put: (self resourceDataFor: resource);
		at: 'scopeMetrics' put: (groupedMetrics associations collect: [ :eachScopeGroup |
					 self scopeMetricsDataForScope: eachScopeGroup key metrics: eachScopeGroup value ]) asArray.
	resource schemaUrl ifNotEmpty: [ data at: 'schemaUrl' put: resource schemaUrl ].
	^ { data }
]

{ #category : 'private - encoding' }
OTOtlpJsonMetricEncoder >> scopeMetricsDataForScope: anOTInstrumentationScope metrics: someMetrics [

	| data |
	data := OrderedDictionary new.
	data
		at: 'scope' put: (self scopeDataFor: anOTInstrumentationScope);
		at: 'metrics' put: (someMetrics collect: [ :each | self metricDataFor: each ]) asArray.
	anOTInstrumentationScope schemaUrl ifNotEmpty: [ data at: 'schemaUrl' put: anOTInstrumentationScope schemaUrl ].
	^ data
]

{ #category : 'private - encoding' }
OTOtlpJsonMetricEncoder >> sumDataFor: anOTSumMetricData [

	| data |
	data := OrderedDictionary new.
	data
		at: 'dataPoints' put: (anOTSumMetricData points collect: [ :each | self numberDataPointDataFor: each ]) asArray;
		at: 'aggregationTemporality' put: (self temporalityCodeFor: anOTSumMetricData temporality);
		at: 'isMonotonic' put: anOTSumMetricData monotonic.
	^ data
]

{ #category : 'private - encoding' }
OTOtlpJsonMetricEncoder >> summaryDataFor: anOTSummaryMetricData [

	^ OrderedDictionary new
		  at: 'dataPoints' put: (anOTSummaryMetricData points collect: [ :each | self summaryDataPointDataFor: each ]) asArray;
		  yourself
]

{ #category : 'private - encoding' }
OTOtlpJsonMetricEncoder >> summaryDataPointDataFor: anOTSummaryDataPoint [

	| data |
	data := OrderedDictionary new.
	anOTSummaryDataPoint startTimestamp ifNotNil: [
		data at: 'startTimeUnixNano' put: (self unixNanosecondsStringFor: anOTSummaryDataPoint startTimestamp) ].
	data
		at: 'timeUnixNano' put: (self unixNanosecondsStringFor: anOTSummaryDataPoint timestamp);
		at: 'count' put: anOTSummaryDataPoint count asString;
		at: 'sum' put: anOTSummaryDataPoint sum asFloat;
		at: 'attributes' put: (self keyValueDataFrom: anOTSummaryDataPoint attributes);
		at: 'quantileValues'
		put: (anOTSummaryDataPoint quantileValues collect: [ :each | self summaryValueAtQuantileDataFor: each ]) asArray.
	^ data
]

{ #category : 'private - encoding' }
OTOtlpJsonMetricEncoder >> summaryValueAtQuantileDataFor: anOTSummaryQuantileValue [

	^ OrderedDictionary new
		  at: 'quantile' put: anOTSummaryQuantileValue quantile asFloat;
		  at: 'value' put: anOTSummaryQuantileValue value asFloat;
		  yourself
]

{ #category : 'private - encoding' }
OTOtlpJsonMetricEncoder >> temporalityCodeFor: aSymbol [

	^ aSymbol = #delta
		  ifTrue: [ 1 ]
		  ifFalse: [ 2 ]
]
