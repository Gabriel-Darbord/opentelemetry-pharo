"
An OTLP metrics exporter that sends protobuf-encoded ExportMetricsServiceRequest payloads over HTTP.
"
Class {
	#name : 'OTOtlpHttpProtobufMetricExporter',
	#superclass : 'OTOtlpHttpJsonMetricExporter',
	#instVars : [
		'responseDecoder'
	],
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'accessing' }
OTOtlpHttpProtobufMetricExporter class >> supportedProtocol [

	^ 'http/protobuf'
]

{ #category : 'private - configuration' }
OTOtlpHttpProtobufMetricExporter >> applyConfigurationToHttpClient [

	super applyConfigurationToHttpClient.
	self httpClient headerAt: 'Content-Type' put: 'application/x-protobuf'
]

{ #category : 'accessing' }
OTOtlpHttpProtobufMetricExporter >> encoder [

	^ encoder ifNil: [ encoder := OTOtlpProtobufMetricEncoder new ]
]

{ #category : 'private - encoding' }
OTOtlpHttpProtobufMetricExporter >> entityForPayload: aByteArray [

	| entity |
	entity := self configuration usesGzipCompression
		ifTrue: [ ZnEntity bytes: (self gzipCompressedBytesFor: aByteArray) ]
		ifFalse: [ ZnEntity bytes: aByteArray ].
	entity contentType: 'application/x-protobuf' asZnMimeType.
	^ entity
]

{ #category : 'private - encoding' }
OTOtlpHttpProtobufMetricExporter >> gzipCompressedBytesFor: aByteArray [

	^ ByteArray streamContents: [ :stream |
		| zipper |
		zipper := GZipWriteStream on: stream.
		zipper nextPutAll: aByteArray.
		zipper close ]
]

{ #category : 'private - encoding' }
OTOtlpHttpProtobufMetricExporter >> payloadStringFrom: anOTMetricSnapshot [

	^ self encoder encodeSnapshot: anOTMetricSnapshot
]

{ #category : 'accessing' }
OTOtlpHttpProtobufMetricExporter >> responseDecoder [

	^ responseDecoder ifNil: [
		  responseDecoder := OTOtlpProtobufMetricResponseDecoder new ]
]

{ #category : 'accessing' }
OTOtlpHttpProtobufMetricExporter >> responseDecoder: aResponseDecoder [

	responseDecoder := aResponseDecoder
]

{ #category : 'private - success handling' }
OTOtlpHttpProtobufMetricExporter >> successfulResponseRepresentationFrom: aResponse [

	| contents |
	contents := self decodedResponseContentsFrom: aResponse.
	contents ifNil: [ Error signal: 'Missing OTLP success response body' ].
	^ self responseDecoder decodeResponse: contents
]
