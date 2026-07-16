"
A minimal protobuf response decoder for OTLP metrics ExportMetricsServiceResponse payloads.
"
Class {
	#name : 'OTOtlpProtobufMetricResponseDecoder',
	#superclass : 'OTOtlpProtobufTraceResponseDecoder',
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'decoding' }
OTOtlpProtobufMetricResponseDecoder >> decodePartialSuccess: aByteArray [

	| partialSuccess reader |
	reader := OTProtobufReader on: aByteArray.
	partialSuccess := OrderedDictionary new.
	[ reader atEnd ] whileFalse: [
		| tag |
		tag := reader readTag.
		tag first = 1 ifTrue: [
			tag second = 0
				ifTrue: [ partialSuccess at: 'rejectedDataPoints' put: reader readVarint ]
				ifFalse: [ reader skipWireType: tag second ] ].
		tag first = 2 ifTrue: [
			tag second = 2
				ifTrue: [ partialSuccess at: 'errorMessage' put: reader readString ]
				ifFalse: [ reader skipWireType: tag second ] ].
		((tag first ~= 1) and: [ tag first ~= 2 ]) ifTrue: [
			reader skipWireType: tag second ] ].
	^ partialSuccess
]
