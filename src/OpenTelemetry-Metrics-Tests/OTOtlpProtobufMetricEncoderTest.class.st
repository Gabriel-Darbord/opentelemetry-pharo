Class {
	#name : 'OTOtlpProtobufMetricEncoderTest',
	#superclass : 'TestCase',
	#instVars : [
		'encoder'
	],
	#category : 'OpenTelemetry-Metrics-Tests',
	#package : 'OpenTelemetry-Metrics-Tests'
}

{ #category : 'private' }
OTOtlpProtobufMetricEncoderTest >> assertReader: aReader readsField: aFieldNumber wireType: aWireType [

	| tag |
	tag := aReader readTag.
	self assert: tag first equals: aFieldNumber.
	self assert: tag second equals: aWireType
]

{ #category : 'private' }
OTOtlpProtobufMetricEncoderTest >> bytesForFieldNumber: aFieldNumber fromReader: aReader [

	[ aReader atEnd ] whileFalse: [
			| tag |
			tag := aReader readTag.
			tag first = aFieldNumber ifTrue: [ ^ aReader readBytes ].
			aReader skipWireType: tag second ].
	self fail: 'Expected field ' , aFieldNumber asString
]

{ #category : 'running' }
OTOtlpProtobufMetricEncoderTest >> setUp [

	super setUp.
	encoder := OTOtlpProtobufMetricEncoder new
]

{ #category : 'tests' }
OTOtlpProtobufMetricEncoderTest >> testEncodeMetricEncodesMetadata [

	| metadataReader metric reader writer |
	metric := OTSumMetricData new.
	metric
		instrumentationScope: (OTInstrumentationScope named: 'instrumentation');
		name: 'requests.total';
		description: 'Request count';
		unit: '1';
		points: #(  );
		monotonic: true;
		temporality: #cumulative;
		metadata: { ('prometheus.type' -> 'unknown') }.
	writer := OTProtobufWriter withBytes.
	encoder encodeMetric: metric on: writer.
	reader := OTProtobufReader on: writer contents.
	self assertReader: reader readsField: 1 wireType: 2.
	self assert: reader readString equals: 'requests.total'.
	self assertReader: reader readsField: 2 wireType: 2.
	reader readString.
	self assertReader: reader readsField: 3 wireType: 2.
	reader readString.
	reader readTag.
	reader readBytes.
	metadataReader := OTProtobufReader on: (self bytesForFieldNumber: 12 fromReader: reader).
	self assertReader: metadataReader readsField: 1 wireType: 2.
	self assert: metadataReader readString equals: 'prometheus.type'.
	self assertReader: metadataReader readsField: 2 wireType: 2
]

{ #category : 'tests' }
OTOtlpProtobufMetricEncoderTest >> testWriteNumberDataPointEncodesExemplar [

	| attributeReader exemplar exemplarReader point reader writer |
	exemplar := OTMetricExemplar new.
	exemplar
		value: 3;
		timestamp: DateAndTime unixEpoch + (Duration nanoSeconds: 6);
		filteredAttributes: { ('user' -> 'alice') };
		traceId: '1234567890abcdef1234567890abcdef';
		spanId: '1234567890abcdef'.
	point := OTNumberDataPoint
		         attributes: { ('method' -> 'GET') }
		         value: 4
		         startTimestamp: DateAndTime unixEpoch + (Duration nanoSeconds: 1)
		         timestamp: DateAndTime unixEpoch + (Duration nanoSeconds: 2).
	point exemplars: { exemplar }.
	writer := OTProtobufWriter withBytes.
	encoder writeNumberDataPoint: point on: writer.
	reader := OTProtobufReader on: writer contents.
	self assertReader: reader readsField: 7 wireType: 2.
	reader readBytes.
	self assertReader: reader readsField: 2 wireType: 1.
	self assert: reader readFixed64 equals: 1.
	self assertReader: reader readsField: 3 wireType: 1.
	self assert: reader readFixed64 equals: 2.
	self assertReader: reader readsField: 6 wireType: 1.
	self assert: reader readFixed64 equals: 4.
	exemplarReader := OTProtobufReader on: (self bytesForFieldNumber: 5 fromReader: reader).
	self assertReader: exemplarReader readsField: 2 wireType: 1.
	self assert: exemplarReader readFixed64 equals: 6.
	self assertReader: exemplarReader readsField: 6 wireType: 1.
	self assert: exemplarReader readFixed64 equals: 3.
	self assertReader: exemplarReader readsField: 4 wireType: 2.
	self assert: exemplarReader readBytes equals: (OTSpanContext byteArrayFromHex: '1234567890abcdef' size: 8).
	self assertReader: exemplarReader readsField: 5 wireType: 2.
	self assert: exemplarReader readBytes equals: (OTSpanContext byteArrayFromHex: '1234567890abcdef1234567890abcdef' size: 16).
	attributeReader := OTProtobufReader on: (self bytesForFieldNumber: 7 fromReader: exemplarReader).
	self assertReader: attributeReader readsField: 1 wireType: 2.
	self assert: attributeReader readString equals: 'user'
]

{ #category : 'tests' }
OTOtlpProtobufMetricEncoderTest >> testWriteSummaryDataPointEncodesCountSumAndQuantiles [

	| point quantileReader reader writer |
	point := OTSummaryDataPoint
		         attributes: { ('method' -> 'GET') }
		         count: 2
		         sum: 3.0
		         quantileValues: {
				         (OTSummaryQuantileValue quantile: 0.5 value: 1.5).
				         (OTSummaryQuantileValue quantile: 0.9 value: 2.5) }
		         startTimestamp: DateAndTime unixEpoch + (Duration nanoSeconds: 1)
		         timestamp: DateAndTime unixEpoch + (Duration nanoSeconds: 2).
	writer := OTProtobufWriter withBytes.
	encoder writeSummaryDataPoint: point on: writer.
	reader := OTProtobufReader on: writer contents.
	self assertReader: reader readsField: 7 wireType: 2.
	reader readBytes.
	self assertReader: reader readsField: 2 wireType: 1.
	self assert: reader readFixed64 equals: 1.
	self assertReader: reader readsField: 3 wireType: 1.
	self assert: reader readFixed64 equals: 2.
	self assertReader: reader readsField: 4 wireType: 1.
	self assert: reader readFixed64 equals: 2.
	self assertReader: reader readsField: 5 wireType: 1.
	self assert: reader readDouble equals: 3.0.
	quantileReader := OTProtobufReader on: (self bytesForFieldNumber: 6 fromReader: reader).
	self assertReader: quantileReader readsField: 1 wireType: 1.
	self assert: quantileReader readDouble equals: 0.5.
	self assertReader: quantileReader readsField: 2 wireType: 1.
	self assert: quantileReader readDouble equals: 1.5
]

{ #category : 'tests' }
OTOtlpProtobufMetricEncoderTest >> testWriteSummaryDataPointNormalizesNegativeQuantileValuesToZero [

	| point quantileReader reader writer |
	point := OTSummaryDataPoint
		         attributes: { ('method' -> 'GET') }
		         count: 2
		         sum: 3.0
		         quantileValues: {
				         (OTSummaryQuantileValue quantile: 0.5 value: 1.5).
				         (OTSummaryQuantileValue quantile: 0.9 value: Float negativeInfinity) }
		         startTimestamp: DateAndTime unixEpoch + (Duration nanoSeconds: 1)
		         timestamp: DateAndTime unixEpoch + (Duration nanoSeconds: 2).
	writer := OTProtobufWriter withBytes.
	encoder writeSummaryDataPoint: point on: writer.
	reader := OTProtobufReader on: writer contents.
	self assertReader: reader readsField: 7 wireType: 2.
	reader readBytes.
	self assertReader: reader readsField: 2 wireType: 1.
	reader readFixed64.
	self assertReader: reader readsField: 3 wireType: 1.
	reader readFixed64.
	self assertReader: reader readsField: 4 wireType: 1.
	reader readFixed64.
	self assertReader: reader readsField: 5 wireType: 1.
	reader readDouble.
	reader readTag.
	reader readBytes.
	quantileReader := OTProtobufReader on: (self bytesForFieldNumber: 6 fromReader: reader).
	self assertReader: quantileReader readsField: 1 wireType: 1.
	self assert: quantileReader readDouble equals: 0.9.
	self assertReader: quantileReader readsField: 2 wireType: 1.
	self assert: quantileReader readDouble equals: 0.0
]
