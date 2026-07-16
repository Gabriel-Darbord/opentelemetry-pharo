"
An OTLP metric encoder that emits the OpenTelemetry JSON protobuf shape for ExportMetricsServiceRequest payloads.
"
Class {
	#name : 'OTOtlpJsonMetricEncoder',
	#superclass : 'OTOtlpJsonTraceEncoder',
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'encoding' }
OTOtlpJsonMetricEncoder >> encodeSnapshot: anOTMetricSnapshot [

	^ OrderedDictionary new
		at: 'resourceMetrics' put: (self resourceMetricsDataFor: anOTMetricSnapshot);
		yourself
]

{ #category : 'private - encoding' }
OTOtlpJsonMetricEncoder >> gaugeDataFor: anOTGaugeMetricData [

	^ OrderedDictionary new
		at: 'dataPoints'
			put: (anOTGaugeMetricData points collect: [ :each | self numberDataPointDataFor: each ]) asArray;
		yourself
]

{ #category : 'private - encoding' }
OTOtlpJsonMetricEncoder >> groupedMetricsFrom: someMetrics [

	| groupedMetrics |
	groupedMetrics := OrderedDictionary new.
	(someMetrics ifNil: [ #() ]) do: [ :eachMetric |
		(groupedMetrics
			at: eachMetric instrumentationScope
			ifAbsentPut: [ OrderedCollection new ]) add: eachMetric ].
	^ groupedMetrics
]

{ #category : 'private - encoding' }
OTOtlpJsonMetricEncoder >> histogramDataFor: anOTHistogramMetricData [

	| data |
	data := OrderedDictionary new.
	data
		at: 'dataPoints'
			put: (anOTHistogramMetricData points collect: [ :each | self histogramDataPointDataFor: each ]) asArray;
		at: 'aggregationTemporality'
			put: (self temporalityCodeFor: anOTHistogramMetricData temporality).
	^ data
]

{ #category : 'private - encoding' }
OTOtlpJsonMetricEncoder >> histogramDataPointDataFor: anOTHistogramDataPoint [

	| data |
	data := OrderedDictionary new.
	anOTHistogramDataPoint startTimestamp ifNotNil: [
		data
			at: 'startTimeUnixNano'
			put: (self unixNanosecondsStringFor: anOTHistogramDataPoint startTimestamp) ].
	data
		at: 'timeUnixNano'
			put: (self unixNanosecondsStringFor: anOTHistogramDataPoint timestamp);
		at: 'count' put: anOTHistogramDataPoint count asString;
		at: 'sum' put: anOTHistogramDataPoint sum asFloat;
		at: 'attributes' put: (self keyValueDataFrom: anOTHistogramDataPoint attributes);
		at: 'bucketCounts' put: (anOTHistogramDataPoint bucketCounts collect: [ :each | each asString ]) asArray;
		at: 'explicitBounds' put: (anOTHistogramDataPoint explicitBounds collect: [ :each | each asFloat ]) asArray.
	anOTHistogramDataPoint min ifNotNil: [ data at: 'min' put: anOTHistogramDataPoint min asFloat ].
	anOTHistogramDataPoint max ifNotNil: [ data at: 'max' put: anOTHistogramDataPoint max asFloat ].
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
	anOTMetricData addOtlpJsonDataTo: data encoder: self.
	^ data
]

{ #category : 'private - encoding' }
OTOtlpJsonMetricEncoder >> numberDataPointDataFor: anOTNumberDataPoint [

	| data |
	data := OrderedDictionary new.
	anOTNumberDataPoint startTimestamp ifNotNil: [
		data
			at: 'startTimeUnixNano'
			put: (self unixNanosecondsStringFor: anOTNumberDataPoint startTimestamp) ].
	data
		at: 'timeUnixNano'
			put: (self unixNanosecondsStringFor: anOTNumberDataPoint timestamp);
		at: 'attributes' put: (self keyValueDataFrom: anOTNumberDataPoint attributes).
	anOTNumberDataPoint value isInteger
		ifTrue: [ data at: 'asInt' put: anOTNumberDataPoint value asString ]
		ifFalse: [ data at: 'asDouble' put: anOTNumberDataPoint value asFloat ].
	^ data
]

{ #category : 'private - encoding' }
OTOtlpJsonMetricEncoder >> resourceMetricsDataFor: anOTMetricSnapshot [

	| data groupedMetrics resource |
	anOTMetricSnapshot metrics ifEmpty: [ ^ #() ].
	resource := anOTMetricSnapshot resource.
	groupedMetrics := self groupedMetricsFrom: anOTMetricSnapshot metrics.
	data := OrderedDictionary new.
	data
		at: 'resource' put: (self resourceDataFor: resource);
		at: 'scopeMetrics' put: (groupedMetrics associations collect: [ :eachScopeGroup |
				 self
					 scopeMetricsDataForScope: eachScopeGroup key
					 metrics: eachScopeGroup value ]) asArray.
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
	anOTInstrumentationScope schemaUrl ifNotEmpty: [
		data at: 'schemaUrl' put: anOTInstrumentationScope schemaUrl ].
	^ data
]

{ #category : 'private - encoding' }
OTOtlpJsonMetricEncoder >> sumDataFor: anOTSumMetricData [

	| data |
	data := OrderedDictionary new.
	data
		at: 'dataPoints'
			put: (anOTSumMetricData points collect: [ :each | self numberDataPointDataFor: each ]) asArray;
		at: 'aggregationTemporality'
			put: (self temporalityCodeFor: anOTSumMetricData temporality);
		at: 'isMonotonic' put: anOTSumMetricData monotonic.
	^ data
]

{ #category : 'private - encoding' }
OTOtlpJsonMetricEncoder >> temporalityCodeFor: aSymbol [

	^ aSymbol = #delta ifTrue: [ 1 ] ifFalse: [ 2 ]
]
