"
An OTLP logs exporter that sends protobuf-encoded ExportLogsServiceRequest payloads over HTTP.
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

{ #category : 'accessing' }
OTOtlpHttpProtobufLogRecordExporter >> encoder [

	^ encoder ifNil: [ encoder := OTOtlpProtobufLogRecordEncoder new ]
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

	^ responseDecoder ifNil: [ responseDecoder := OTOtlpProtobufLogRecordResponseDecoder new ]
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
