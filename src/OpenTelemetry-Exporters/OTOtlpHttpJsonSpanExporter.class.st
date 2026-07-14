"
An OTLP traces exporter that sends JSON-encoded ExportTraceServiceRequest payloads over HTTP.
"
Class {
	#name : 'OTOtlpHttpJsonSpanExporter',
	#superclass : 'OTSpanExporter',
	#instVars : [
		'configuration',
		'encoder',
		'httpClient'
	],
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'instance creation' }
OTOtlpHttpJsonSpanExporter class >> configuration: anOtlpConfiguration [

	^ self new
		configuration: anOtlpConfiguration;
		yourself
]

{ #category : 'accessing' }
OTOtlpHttpJsonSpanExporter class >> supportedProtocol [

	^ 'http/json'
]

{ #category : 'private - configuration' }
OTOtlpHttpJsonSpanExporter >> applyConfigurationToHttpClient [

	| client |
	client := self httpClient.
	client
		url: self configuration endpoint;
		method: #POST;
		timeout: self configuration timeoutMillis.
	self configuration headers associationsDo: [ :each |
		client headerAt: each key put: each value ].
	(self hasUserAgentHeaderConfigured: self configuration headers) ifFalse: [
		client headerAt: 'User-Agent' put: self configuration userAgent ].
	client headerAt: 'Content-Type' put: 'application/json'
]

{ #category : 'accessing' }
OTOtlpHttpJsonSpanExporter >> configuration [

	^ configuration ifNil: [
		  configuration := OTOtlpExporterConfiguration forSignalNamed: 'TRACES' ]
]

{ #category : 'accessing' }
OTOtlpHttpJsonSpanExporter >> configuration: anOtlpConfiguration [

	configuration := anOtlpConfiguration
]

{ #category : 'accessing' }
OTOtlpHttpJsonSpanExporter >> encoder [

	^ encoder ifNil: [ encoder := OTOtlpJsonTraceEncoder new ]
]

{ #category : 'accessing' }
OTOtlpHttpJsonSpanExporter >> encoder: anEncoder [

	encoder := anEncoder
]

{ #category : 'private - encoding' }
OTOtlpHttpJsonSpanExporter >> entityForPayload: aString [

	| entity |
	entity := self configuration usesGzipCompression
		ifTrue: [ ZnEntity bytes: (self gzipCompressedBytesFor: aString) ]
		ifFalse: [ ZnEntity with: aString type: ZnMimeType applicationJson ].
	entity contentType: ZnMimeType applicationJson.
	^ entity
]

{ #category : 'exporting' }
OTOtlpHttpJsonSpanExporter >> export: spans [

	self isShutdown ifTrue: [ ^ false ].
	^ [
		self applyConfigurationToHttpClient.
		self httpClient entity: (self entityForPayload: (self payloadStringFrom: spans)).
		self configuration usesGzipCompression ifTrue: [
			self httpClient headerAt: 'Content-Encoding' put: 'gzip' ].
		(self httpClient execute; response) code = 200 ]
		on: Error
		do: [ false ]
]

{ #category : 'private - encoding' }
OTOtlpHttpJsonSpanExporter >> gzipCompressedBytesFor: aString [

	^ ByteArray streamContents: [ :stream |
		| zipper |
		zipper := GZipWriteStream on: stream.
		zipper nextPutAll: aString utf8Encoded.
		zipper close ]
]

{ #category : 'testing' }
OTOtlpHttpJsonSpanExporter >> hasUserAgentHeaderConfigured: aDictionary [

	^ aDictionary keys anySatisfy: [ :each | each asString sameAs: 'User-Agent' ]
]

{ #category : 'accessing' }
OTOtlpHttpJsonSpanExporter >> httpClient [

	^ httpClient ifNil: [ httpClient := ZnClient new ]
]

{ #category : 'accessing' }
OTOtlpHttpJsonSpanExporter >> httpClient: anHttpClient [

	httpClient := anHttpClient
]

{ #category : 'private - encoding' }
OTOtlpHttpJsonSpanExporter >> payloadStringFrom: spans [

	^ ZnUtils defaultJSONWriter toString: (self encoder encodeSpans: spans asArray)
]
