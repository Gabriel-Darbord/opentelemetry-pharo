"
An OTLP metric encoder that emits protobuf-encoded ExportMetricsServiceRequest payloads.
"
Class {
	#name : 'OTOtlpProtobufMetricEncoder',
	#superclass : 'OTOtlpProtobufTraceEncoder',
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'private' }
OTOtlpProtobufMetricEncoder class >> byteArrayFromHex: aString size: anInteger [

	| bytes |
	bytes := ByteArray new: anInteger.
	1 to: anInteger do: [ :index |
			| start |
			start := index - 1 * 2 + 1.
			bytes at: index put: (Integer readFrom: (aString copyFrom: start to: start + 1) readStream base: 16) ].
	^ bytes
]

{ #category : 'private - encoding' }
OTOtlpProtobufMetricEncoder >> encodeMetric: anOTMetricData on: aWriter [

	aWriter
		writeTag: 1 wireType: 2;
		writeString: anOTMetricData name.
	anOTMetricData description ifNotEmpty: [
			aWriter
				writeTag: 2 wireType: 2;
				writeString: anOTMetricData description ].
	anOTMetricData unit ifNotEmpty: [
			aWriter
				writeTag: 3 wireType: 2;
				writeString: anOTMetricData unit ].
	anOTMetricData writeOtlpProtobufDataOn: aWriter encoder: self.
	self writeAttributes: anOTMetricData metadata fieldNumber: 12 on: aWriter
]

{ #category : 'private - encoding' }
OTOtlpProtobufMetricEncoder >> encodeResource: aResource scopeGroups: scopeGroups on: aWriter [

	aWriter
		writeTag: 1 wireType: 2;
		writeEmbedded: [ :resource | self encodeResource: aResource on: resource ].
	scopeGroups associationsDo: [ :scopeGroup |
			aWriter
				writeTag: 2 wireType: 2;
				writeEmbedded: [ :scopeMetrics | self encodeScope: scopeGroup key metrics: scopeGroup value on: scopeMetrics ] ].
	aResource schemaUrl ifNotEmpty: [
			aWriter
				writeTag: 3 wireType: 2;
				writeString: aResource schemaUrl ]
]

{ #category : 'private - encoding' }
OTOtlpProtobufMetricEncoder >> encodeScope: anInstrumentationScope metrics: someMetrics on: aWriter [

	aWriter
		writeTag: 1 wireType: 2;
		writeEmbedded: [ :scope | self encodeInstrumentationScope: anInstrumentationScope on: scope ].
	someMetrics do: [ :metric |
			aWriter
				writeTag: 2 wireType: 2;
				writeEmbedded: [ :embedded | self encodeMetric: metric on: embedded ] ].
	anInstrumentationScope schemaUrl ifNotEmpty: [
			aWriter
				writeTag: 3 wireType: 2;
				writeString: anInstrumentationScope schemaUrl ]
]

{ #category : 'encoding' }
OTOtlpProtobufMetricEncoder >> encodeSnapshot: anOTMetricSnapshot [

	| writer |
	writer := OTProtobufWriter withBytes.
	anOTMetricSnapshot metrics ifEmpty: [ ^ writer contents ].
	writer
		writeTag: 1 wireType: 2;
		writeEmbedded: [ :resourceMetrics |
				self
					encodeResource: anOTMetricSnapshot resource
					scopeGroups: (self groupedMetricsFrom: anOTMetricSnapshot metrics)
					on: resourceMetrics ].
	^ writer contents
]

{ #category : 'private - encoding' }
OTOtlpProtobufMetricEncoder >> groupedMetricsFrom: someMetrics [

	| groupedMetrics |
	groupedMetrics := OrderedDictionary new.
	(someMetrics ifNil: [ #(  ) ]) do: [ :eachMetric |
		(groupedMetrics at: eachMetric instrumentationScope ifAbsentPut: [ OrderedCollection new ]) add: eachMetric ].
	^ groupedMetrics
]

{ #category : 'private - encoding' }
OTOtlpProtobufMetricEncoder >> temporalityCodeFor: aSymbol [

	^ aSymbol = #delta
		  ifTrue: [ 1 ]
		  ifFalse: [ 2 ]
]

{ #category : 'private - encoding' }
OTOtlpProtobufMetricEncoder >> writeExemplar: anOTMetricExemplar on: aWriter [

	aWriter
		writeTag: 2 wireType: 1;
		writeFixed64: (self unixNanosecondsFor: anOTMetricExemplar timestamp).
	anOTMetricExemplar value isInteger
		ifTrue: [
				aWriter
					writeTag: 6 wireType: 1;
					writeFixed64: anOTMetricExemplar value ]
		ifFalse: [
				aWriter
					writeTag: 3 wireType: 1;
					writeDouble: anOTMetricExemplar value ].
	anOTMetricExemplar spanId ifNotNil: [
			aWriter
				writeTag: 4 wireType: 2;
				writeBytes: (self class byteArrayFromHex: anOTMetricExemplar spanId size: 8) ].
	anOTMetricExemplar traceId ifNotNil: [
			aWriter
				writeTag: 5 wireType: 2;
				writeBytes: (self class byteArrayFromHex: anOTMetricExemplar traceId size: 16) ].
	self writeAttributes: anOTMetricExemplar filteredAttributes fieldNumber: 7 on: aWriter
]

{ #category : 'private - encoding' }
OTOtlpProtobufMetricEncoder >> writeExponentialBucketRange: anOTExponentialBucketRange on: aWriter [

	anOTExponentialBucketRange bucketCounts ifEmpty: [ ^ self ].
	aWriter
		writeTag: 1 wireType: 0;
		writeSInt32: anOTExponentialBucketRange offset.
	anOTExponentialBucketRange bucketCounts do: [ :each |
			aWriter
				writeTag: 2 wireType: 0;
				writeVarint: each ]
]

{ #category : 'private - encoding' }
OTOtlpProtobufMetricEncoder >> writeExponentialHistogram: anOTExponentialHistogramMetricData on: aWriter [

	anOTExponentialHistogramMetricData points do: [ :point |
			aWriter
				writeTag: 1 wireType: 2;
				writeEmbedded: [ :embedded | self writeExponentialHistogramDataPoint: point on: embedded ] ].
	aWriter
		writeTag: 2 wireType: 0;
		writeVarint: (self temporalityCodeFor: anOTExponentialHistogramMetricData temporality)
]

{ #category : 'private - encoding' }
OTOtlpProtobufMetricEncoder >> writeExponentialHistogramDataPoint: anOTExponentialHistogramDataPoint on: aWriter [

	self writeAttributes: anOTExponentialHistogramDataPoint attributes fieldNumber: 1 on: aWriter.
	anOTExponentialHistogramDataPoint startTimestamp ifNotNil: [
			aWriter
				writeTag: 2 wireType: 1;
				writeFixed64: (self unixNanosecondsFor: anOTExponentialHistogramDataPoint startTimestamp) ].
	aWriter
		writeTag: 3 wireType: 1;
		writeFixed64: (self unixNanosecondsFor: anOTExponentialHistogramDataPoint timestamp);
		writeTag: 4 wireType: 1;
		writeFixed64: anOTExponentialHistogramDataPoint count;
		writeTag: 5 wireType: 1;
		writeDouble: anOTExponentialHistogramDataPoint sum;
		writeTag: 6 wireType: 0;
		writeSInt32: anOTExponentialHistogramDataPoint scale;
		writeTag: 7 wireType: 1;
		writeFixed64: anOTExponentialHistogramDataPoint zeroCount.
	anOTExponentialHistogramDataPoint positiveBuckets bucketCounts ifNotEmpty: [
			aWriter
				writeTag: 8 wireType: 2;
				writeEmbedded: [ :positive | self writeExponentialBucketRange: anOTExponentialHistogramDataPoint positiveBuckets on: positive ] ].
	anOTExponentialHistogramDataPoint negativeBuckets bucketCounts ifNotEmpty: [
			aWriter
				writeTag: 9 wireType: 2;
				writeEmbedded: [ :negative | self writeExponentialBucketRange: anOTExponentialHistogramDataPoint negativeBuckets on: negative ] ].
	anOTExponentialHistogramDataPoint min ifNotNil: [
			aWriter
				writeTag: 12 wireType: 1;
				writeDouble: anOTExponentialHistogramDataPoint min ].
	anOTExponentialHistogramDataPoint max ifNotNil: [
			aWriter
				writeTag: 13 wireType: 1;
				writeDouble: anOTExponentialHistogramDataPoint max ].
	anOTExponentialHistogramDataPoint zeroThreshold = 0 ifFalse: [
			aWriter
				writeTag: 14 wireType: 1;
				writeDouble: anOTExponentialHistogramDataPoint zeroThreshold ].
	anOTExponentialHistogramDataPoint exemplars do: [ :each |
			aWriter
				writeTag: 11 wireType: 2;
				writeEmbedded: [ :embedded | self writeExemplar: each on: embedded ] ]
]

{ #category : 'private - encoding' }
OTOtlpProtobufMetricEncoder >> writeGauge: anOTGaugeMetricData on: aWriter [

	anOTGaugeMetricData points do: [ :point |
			aWriter
				writeTag: 1 wireType: 2;
				writeEmbedded: [ :embedded | self writeNumberDataPoint: point on: embedded ] ]
]

{ #category : 'private - encoding' }
OTOtlpProtobufMetricEncoder >> writeHistogram: anOTHistogramMetricData on: aWriter [

	anOTHistogramMetricData points do: [ :point |
			aWriter
				writeTag: 1 wireType: 2;
				writeEmbedded: [ :embedded | self writeHistogramDataPoint: point on: embedded ] ].
	aWriter
		writeTag: 2 wireType: 0;
		writeVarint: (self temporalityCodeFor: anOTHistogramMetricData temporality)
]

{ #category : 'private - encoding' }
OTOtlpProtobufMetricEncoder >> writeHistogramDataPoint: anOTHistogramDataPoint on: aWriter [

	self writeAttributes: anOTHistogramDataPoint attributes fieldNumber: 9 on: aWriter.
	anOTHistogramDataPoint startTimestamp ifNotNil: [
			aWriter
				writeTag: 2 wireType: 1;
				writeFixed64: (self unixNanosecondsFor: anOTHistogramDataPoint startTimestamp) ].
	aWriter
		writeTag: 3 wireType: 1;
		writeFixed64: (self unixNanosecondsFor: anOTHistogramDataPoint timestamp);
		writeTag: 4 wireType: 1;
		writeFixed64: anOTHistogramDataPoint count.
	aWriter
		writeTag: 5 wireType: 1;
		writeDouble: anOTHistogramDataPoint sum.
	anOTHistogramDataPoint bucketCounts do: [ :each |
			aWriter
				writeTag: 6 wireType: 1;
				writeFixed64: each ].
	anOTHistogramDataPoint explicitBounds do: [ :each |
			aWriter
				writeTag: 7 wireType: 1;
				writeDouble: each ].
	anOTHistogramDataPoint min ifNotNil: [
			aWriter
				writeTag: 11 wireType: 1;
				writeDouble: anOTHistogramDataPoint min ].
	anOTHistogramDataPoint max ifNotNil: [
			aWriter
				writeTag: 12 wireType: 1;
				writeDouble: anOTHistogramDataPoint max ].
	anOTHistogramDataPoint exemplars do: [ :each |
			aWriter
				writeTag: 8 wireType: 2;
				writeEmbedded: [ :embedded | self writeExemplar: each on: embedded ] ]
]

{ #category : 'private - encoding' }
OTOtlpProtobufMetricEncoder >> writeNumberDataPoint: anOTNumberDataPoint on: aWriter [

	self writeAttributes: anOTNumberDataPoint attributes fieldNumber: 7 on: aWriter.
	anOTNumberDataPoint startTimestamp ifNotNil: [
			aWriter
				writeTag: 2 wireType: 1;
				writeFixed64: (self unixNanosecondsFor: anOTNumberDataPoint startTimestamp) ].
	aWriter
		writeTag: 3 wireType: 1;
		writeFixed64: (self unixNanosecondsFor: anOTNumberDataPoint timestamp).
	anOTNumberDataPoint value isInteger
		ifTrue: [
				aWriter
					writeTag: 6 wireType: 1;
					writeFixed64: anOTNumberDataPoint value ]
		ifFalse: [
				aWriter
					writeTag: 4 wireType: 1;
					writeDouble: anOTNumberDataPoint value ].
	anOTNumberDataPoint exemplars do: [ :each |
			aWriter
				writeTag: 5 wireType: 2;
				writeEmbedded: [ :embedded | self writeExemplar: each on: embedded ] ]
]

{ #category : 'private - encoding' }
OTOtlpProtobufMetricEncoder >> writeSum: anOTSumMetricData on: aWriter [

	anOTSumMetricData points do: [ :point |
			aWriter
				writeTag: 1 wireType: 2;
				writeEmbedded: [ :embedded | self writeNumberDataPoint: point on: embedded ] ].
	aWriter
		writeTag: 2 wireType: 0;
		writeVarint: (self temporalityCodeFor: anOTSumMetricData temporality);
		writeTag: 3 wireType: 0;
		writeVarint: (anOTSumMetricData monotonic
				 ifTrue: [ 1 ]
				 ifFalse: [ 0 ])
]

{ #category : 'private - encoding' }
OTOtlpProtobufMetricEncoder >> writeSummary: anOTSummaryMetricData on: aWriter [

	anOTSummaryMetricData points do: [ :point |
			aWriter
				writeTag: 1 wireType: 2;
				writeEmbedded: [ :embedded | self writeSummaryDataPoint: point on: embedded ] ]
]

{ #category : 'private - encoding' }
OTOtlpProtobufMetricEncoder >> writeSummaryDataPoint: anOTSummaryDataPoint on: aWriter [

	self writeAttributes: anOTSummaryDataPoint attributes fieldNumber: 7 on: aWriter.
	anOTSummaryDataPoint startTimestamp ifNotNil: [
			aWriter
				writeTag: 2 wireType: 1;
				writeFixed64: (self unixNanosecondsFor: anOTSummaryDataPoint startTimestamp) ].
	aWriter
		writeTag: 3 wireType: 1;
		writeFixed64: (self unixNanosecondsFor: anOTSummaryDataPoint timestamp);
		writeTag: 4 wireType: 1;
		writeFixed64: anOTSummaryDataPoint count;
		writeTag: 5 wireType: 1;
		writeDouble: anOTSummaryDataPoint sum.
	anOTSummaryDataPoint quantileValues do: [ :each |
			aWriter
				writeTag: 6 wireType: 2;
				writeEmbedded: [ :embedded | self writeSummaryValueAtQuantile: each on: embedded ] ]
]

{ #category : 'private - encoding' }
OTOtlpProtobufMetricEncoder >> writeSummaryValueAtQuantile: anOTSummaryQuantileValue on: aWriter [

	aWriter
		writeTag: 1 wireType: 1;
		writeDouble: anOTSummaryQuantileValue quantile;
		writeTag: 2 wireType: 1;
		writeDouble: anOTSummaryQuantileValue value
]
