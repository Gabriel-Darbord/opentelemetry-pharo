"
An OTLP logs exporter that sends protobuf-encoded ExportLogsServiceRequest payloads over HTTP.

It inherits the same per-instance HTTP export serialization as the JSON OTLP HTTP exporter. ForceFlush and Shutdown may still race with exporter-managed work and therefore follow the lifecycle contract documented on the exporter base classes.
"
Class {
	#name : 'OTOtlpHttpProtobufLogRecordExporter',
	#superclass : 'OTOtlpHttpJsonLogRecordExporter',
	#instVars : [
		'responseDecoder'
	],
	#category : 'OpenTelemetry-Logs',
	#package : 'OpenTelemetry-Logs'
}

{ #category : 'accessing' }
OTOtlpHttpProtobufLogRecordExporter class >> supportedProtocol [

	^ 'http/protobuf'
]

{ #category : 'private - configuration' }
OTOtlpHttpProtobufLogRecordExporter >> applyConfigurationToHttpClient [

	super applyConfigurationToHttpClient.
	self httpClient headerAt: 'Content-Type' put: 'application/x-protobuf'
]

{ #category : 'private - encoding' }
OTOtlpHttpProtobufLogRecordExporter >> defaultEncoderClass [

	^ OTOtlpProtobufLogRecordEncoder
]

{ #category : 'accessing' }
OTOtlpHttpProtobufLogRecordExporter >> defaultResponseDecoderClass [

	^ OTOtlpProtobufLogRecordResponseDecoder
]

{ #category : 'private - encoding' }
OTOtlpHttpProtobufLogRecordExporter >> entityForPayload: aByteArray [

	| entity |
	entity := self configuration usesGzipCompression
		          ifTrue: [ ZnEntity bytes: (self gzipCompressedBytesFor: aByteArray) ]
		          ifFalse: [ ZnEntity bytes: aByteArray ].
	entity contentType: 'application/x-protobuf' asZnMimeType.
	^ entity
]

{ #category : 'private - encoding' }
OTOtlpHttpProtobufLogRecordExporter >> gzipCompressedBytesFor: aByteArray [

	^ ByteArray streamContents: [ :stream |
			  | zipper |
			  zipper := GZipWriteStream on: stream.
			  zipper nextPutAll: aByteArray.
			  zipper close ]
]

{ #category : 'private - encoding' }
OTOtlpHttpProtobufLogRecordExporter >> payloadStringFrom: logRecords [

	^ self encoder encodeLogRecords: logRecords asArray
]

{ #category : 'accessing' }
OTOtlpHttpProtobufLogRecordExporter >> responseDecoder [

	^ responseDecoder ifNil: [ responseDecoder := self defaultResponseDecoderClass new ]
]

{ #category : 'accessing' }
OTOtlpHttpProtobufLogRecordExporter >> responseDecoder: aResponseDecoder [

	responseDecoder := aResponseDecoder
]

{ #category : 'private - success handling' }
OTOtlpHttpProtobufLogRecordExporter >> successfulResponseRepresentationFrom: aResponse [

	| contents |
	contents := self decodedResponseContentsFrom: aResponse.
	contents ifNil: [ Error signal: 'Missing OTLP success response body' ].
	^ self responseDecoder decodeResponse: contents
]
