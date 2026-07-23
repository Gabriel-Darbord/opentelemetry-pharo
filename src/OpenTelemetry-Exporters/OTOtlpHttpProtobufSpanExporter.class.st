"
An OTLP traces exporter that sends protobuf-encoded ExportTraceServiceRequest payloads over HTTP.
"
Class {
	#name : 'OTOtlpHttpProtobufSpanExporter',
	#superclass : 'OTOtlpHttpJsonSpanExporter',
	#instVars : [
		'responseDecoder'
	],
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'instance creation' }
OTOtlpHttpProtobufSpanExporter class >> configuration: anOtlpConfiguration [

	^ self new
		  configuration: anOtlpConfiguration;
		  yourself
]

{ #category : 'accessing' }
OTOtlpHttpProtobufSpanExporter class >> supportedProtocol [

	^ 'http/protobuf'
]

{ #category : 'private - configuration' }
OTOtlpHttpProtobufSpanExporter >> applyConfigurationToHttpClient [

	super applyConfigurationToHttpClient.
	self httpClient headerAt: 'Content-Type' put: 'application/x-protobuf'
]

{ #category : 'accessing' }
OTOtlpHttpProtobufSpanExporter >> encoder [

	^ encoder ifNil: [ encoder := OTOtlpProtobufTraceEncoder new ]
]

{ #category : 'private - encoding' }
OTOtlpHttpProtobufSpanExporter >> entityForPayload: aByteArray [

	| entity |
	entity := self configuration usesGzipCompression
		          ifTrue: [ ZnEntity bytes: (self gzipCompressedBytesFor: aByteArray) ]
		          ifFalse: [ ZnEntity bytes: aByteArray ].
	entity contentType: 'application/x-protobuf' asZnMimeType.
	^ entity
]

{ #category : 'private - encoding' }
OTOtlpHttpProtobufSpanExporter >> gzipCompressedBytesFor: aByteArray [

	^ ByteArray streamContents: [ :stream |
			  | zipper |
			  zipper := GZipWriteStream on: stream.
			  zipper nextPutAll: aByteArray.
			  zipper close ]
]

{ #category : 'private - encoding' }
OTOtlpHttpProtobufSpanExporter >> payloadStringFrom: spans [

	^ self encoder encodeSpans: spans asArray
]

{ #category : 'accessing' }
OTOtlpHttpProtobufSpanExporter >> responseDecoder [

	^ responseDecoder ifNil: [ responseDecoder := OTOtlpProtobufTraceResponseDecoder new ]
]

{ #category : 'accessing' }
OTOtlpHttpProtobufSpanExporter >> responseDecoder: aResponseDecoder [

	responseDecoder := aResponseDecoder
]

{ #category : 'private - success handling' }
OTOtlpHttpProtobufSpanExporter >> successfulResponseRepresentationFrom: aResponse [

	| contents |
	contents := self decodedResponseContentsFrom: aResponse.
	contents ifNil: [ Error signal: 'Missing OTLP success response body' ].
	^ self responseDecoder decodeResponse: contents
]
