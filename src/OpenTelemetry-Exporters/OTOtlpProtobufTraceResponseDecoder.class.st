"
A minimal protobuf response decoder for OTLP trace ExportTraceServiceResponse payloads.
"
Class {
	#name : 'OTOtlpProtobufTraceResponseDecoder',
	#superclass : 'Object',
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'decoding' }
OTOtlpProtobufTraceResponseDecoder >> decodePartialSuccess: aByteArray [

	| partialSuccess reader |
	reader := OTProtobufReader on: aByteArray.
	partialSuccess := OrderedDictionary new.
	[ reader atEnd ] whileFalse: [
			| tag |
			tag := reader readTag.
			tag first = 1 ifTrue: [
					tag second = 0
						ifTrue: [ partialSuccess at: 'rejectedSpans' put: reader readVarint ]
						ifFalse: [ reader skipWireType: tag second ] ].
			tag first = 2 ifTrue: [
					tag second = 2
						ifTrue: [ partialSuccess at: 'errorMessage' put: reader readString ]
						ifFalse: [ reader skipWireType: tag second ] ].
			(tag first ~= 1 and: [ tag first ~= 2 ]) ifTrue: [ reader skipWireType: tag second ] ].
	^ partialSuccess
]

{ #category : 'decoding' }
OTOtlpProtobufTraceResponseDecoder >> decodeResponse: aByteArray [

	| partialSuccess reader response |
	reader := OTProtobufReader on: aByteArray.
	response := OrderedDictionary new.
	[ reader atEnd ] whileFalse: [
			| tag |
			tag := reader readTag.
			(tag first = 1 and: [ tag second = 2 ])
				ifTrue: [
						partialSuccess := self decodePartialSuccess: reader readBytes.
						response at: 'partialSuccess' put: partialSuccess ]
				ifFalse: [ reader skipWireType: tag second ] ].
	^ response
]
