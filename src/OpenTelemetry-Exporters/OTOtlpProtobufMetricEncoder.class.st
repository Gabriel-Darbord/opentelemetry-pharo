"
An OTLP metric encoder that emits protobuf-encoded ExportMetricsServiceRequest payloads.
"
Class {
	#name : 'OTOtlpProtobufMetricEncoder',
	#superclass : 'OTOtlpProtobufTraceEncoder',
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

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
	anOTMetricData writeOtlpProtobufDataOn: aWriter encoder: self
]

{ #category : 'private - encoding' }
OTOtlpProtobufMetricEncoder >> encodeResource: aResource scopeGroups: scopeGroups on: aWriter [

	aWriter
		writeTag: 1 wireType: 2;
		writeEmbedded: [ :resource |
			self encodeResource: aResource on: resource ].
	scopeGroups associationsDo: [ :scopeGroup |
		aWriter
			writeTag: 2 wireType: 2;
			writeEmbedded: [ :scopeMetrics |
				self
					encodeScope: scopeGroup key
					metrics: scopeGroup value
					on: scopeMetrics ] ].
	aResource schemaUrl ifNotEmpty: [
		aWriter
			writeTag: 3 wireType: 2;
			writeString: aResource schemaUrl ]
]

{ #category : 'private - encoding' }
OTOtlpProtobufMetricEncoder >> encodeScope: anInstrumentationScope metrics: someMetrics on: aWriter [

	aWriter
		writeTag: 1 wireType: 2;
		writeEmbedded: [ :scope |
			self encodeInstrumentationScope: anInstrumentationScope on: scope ].
	someMetrics do: [ :metric |
		aWriter
			writeTag: 2 wireType: 2;
			writeEmbedded: [ :embedded |
				self encodeMetric: metric on: embedded ] ].
	anInstrumentationScope schemaUrl ifNotEmpty: [
		aWriter
			writeTag: 3 wireType: 2;
			writeString: anInstrumentationScope schemaUrl ]
]

{ #category : 'private - encoding' }
OTOtlpProtobufMetricEncoder >> groupedMetricsFrom: someMetrics [

	| groupedMetrics |
	groupedMetrics := OrderedDictionary new.
	(someMetrics ifNil: [ #() ]) do: [ :eachMetric |
		(groupedMetrics
			at: eachMetric instrumentationScope
			ifAbsentPut: [ OrderedCollection new ]) add: eachMetric ].
	^ groupedMetrics
]

{ #category : 'private - encoding' }
OTOtlpProtobufMetricEncoder >> temporalityCodeFor: aSymbol [

	^ aSymbol = #delta ifTrue: [ 1 ] ifFalse: [ 2 ]
]

{ #category : 'private - encoding' }
OTOtlpProtobufMetricEncoder >> writeGauge: anOTGaugeMetricData on: aWriter [

	anOTGaugeMetricData points do: [ :point |
		aWriter
			writeTag: 1 wireType: 2;
			writeEmbedded: [ :embedded |
				self writeNumberDataPoint: point on: embedded ] ]
]

{ #category : 'private - encoding' }
OTOtlpProtobufMetricEncoder >> writeHistogram: anOTHistogramMetricData on: aWriter [

	anOTHistogramMetricData points do: [ :point |
		aWriter
			writeTag: 1 wireType: 2;
			writeEmbedded: [ :embedded |
				self writeHistogramDataPoint: point on: embedded ] ].
	aWriter
		writeTag: 2 wireType: 0;
		writeVarint: (self temporalityCodeFor: anOTHistogramMetricData temporality)
]

{ #category : 'private - encoding' }
OTOtlpProtobufMetricEncoder >> writeHistogramDataPoint: anOTHistogramDataPoint on: aWriter [

	self
		writeAttributes: anOTHistogramDataPoint attributes
		fieldNumber: 9
		on: aWriter.
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
			writeDouble: anOTHistogramDataPoint max ]
]

{ #category : 'private - encoding' }
OTOtlpProtobufMetricEncoder >> writeNumberDataPoint: anOTNumberDataPoint on: aWriter [

	self
		writeAttributes: anOTNumberDataPoint attributes
		fieldNumber: 7
		on: aWriter.
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
				writeDouble: anOTNumberDataPoint value ]
]

{ #category : 'private - encoding' }
OTOtlpProtobufMetricEncoder >> writeSum: anOTSumMetricData on: aWriter [

	anOTSumMetricData points do: [ :point |
		aWriter
			writeTag: 1 wireType: 2;
			writeEmbedded: [ :embedded |
				self writeNumberDataPoint: point on: embedded ] ].
	aWriter
		writeTag: 2 wireType: 0;
		writeVarint: (self temporalityCodeFor: anOTSumMetricData temporality);
		writeTag: 3 wireType: 0;
		writeVarint: (anOTSumMetricData monotonic ifTrue: [ 1 ] ifFalse: [ 0 ])
]
