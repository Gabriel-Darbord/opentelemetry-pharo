"
An OTLP traces exporter that sends protobuf-encoded ExportTraceServiceRequest payloads over gRPC.
"
Class {
	#name : 'OTOtlpGrpcSpanExporter',
	#superclass : 'OTOtlpHttpProtobufSpanExporter',
	#instVars : [
		'grpcChannel',
		'grpcTransport',
		'requestExecutor'
	],
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'instance creation' }
OTOtlpGrpcSpanExporter class >> configuration: anOtlpConfiguration [

	^ self new
		configuration: anOtlpConfiguration;
		yourself
]

{ #category : 'private - retry' }
OTOtlpGrpcSpanExporter class >> retryableStatusCodes [

	^ #( 1 4 8 10 11 14 15 ) asSet
]

{ #category : 'accessing' }
OTOtlpGrpcSpanExporter class >> supportedProtocol [

	^ 'grpc'
]

{ #category : 'private - grpc' }
OTOtlpGrpcSpanExporter >> executeGrpcRequest: aRequest [

	^ requestExecutor
		ifNil: [ self grpcChannel executeUnaryRequest: aRequest ]
		ifNotNil: [ requestExecutor value: aRequest ]
]

{ #category : 'exporting' }
OTOtlpGrpcSpanExporter >> export: spans [

	self isShutdown ifTrue: [ ^ false ].
	^ self
		exportAttemptNumber: 1
		payloadBytes: (self payloadBytesFrom: spans)
]

{ #category : 'exporting' }
OTOtlpGrpcSpanExporter >> exportAttemptNumber: attemptNumber payloadBytes: payloadBytes [

	| request response status |
	request := self grpcRequestForPayloadBytes: payloadBytes.
	[
	response := self executeGrpcRequest: request ]
		on: Error
		do: [ :error |
			attemptNumber >= self maxExportAttempts ifTrue: [
				self noteRetryExhaustedForError: error.
				^ false ].
			self sleepForMilliseconds:
				(self retryDelayMillisForAttempt: attemptNumber response: nil).
			^ self
				exportAttemptNumber: attemptNumber + 1
				payloadBytes: payloadBytes ].
	status := response status.
	status isOk ifTrue: [ ^ self handleSuccessGrpcResponse: response ].
	(self isRetryableStatus: status) ifFalse: [ ^ false ].
	attemptNumber >= self maxExportAttempts ifTrue: [
		self noteRetryExhaustedForStatus: status.
		^ false ].
	self sleepForMilliseconds:
		(self retryDelayMillisForAttempt: attemptNumber response: nil).
	^ self
		exportAttemptNumber: attemptNumber + 1
		payloadBytes: payloadBytes
]

{ #category : 'private - grpc' }
OTOtlpGrpcSpanExporter >> grpcChannel [

	^ grpcChannel ifNil: [
		  grpcChannel := self grpcChannelClass
			  endpoint: (self grpcEndpointClass fromString: self configuration endpoint)
			  transport: self grpcTransport ]
]

{ #category : 'private - grpc' }
OTOtlpGrpcSpanExporter >> grpcChannelClass [

	^ self grpcDependencyNamed: #GRPCChannel
]

{ #category : 'private - grpc' }
OTOtlpGrpcSpanExporter >> grpcDependencyNamed: aSymbol [

	^ Smalltalk globals
		at: aSymbol
		ifAbsent: [
			Error signal:
				'OTOtlpGrpcSpanExporter requires grpc-pharo to be loaded (missing ',
				aSymbol asString,
				')' ]
]

{ #category : 'private - grpc' }
OTOtlpGrpcSpanExporter >> grpcEndpointClass [

	^ self grpcDependencyNamed: #GRPCEndpoint
]

{ #category : 'private - grpc' }
OTOtlpGrpcSpanExporter >> grpcMetadataClass [

	^ self grpcDependencyNamed: #GRPCMetadata
]

{ #category : 'private - grpc' }
OTOtlpGrpcSpanExporter >> grpcMetadataFromConfigurationHeaders [

	| metadata |
	metadata := self grpcMetadataClass new.
	self configuration headers associationsDo: [ :each |
		metadata addKey: each key asLowercase value: each value ].
	^ metadata
]

{ #category : 'private - grpc' }
OTOtlpGrpcSpanExporter >> grpcRequestClass [

	^ self grpcDependencyNamed: #GRPCRequest
]

{ #category : 'private - grpc' }
OTOtlpGrpcSpanExporter >> grpcRequestForPayloadBytes: payloadBytes [

	| request requestPayload |
	requestPayload := self configuration usesGzipCompression
		ifTrue: [ self gzipCompressedBytesFor: payloadBytes ]
		ifFalse: [ payloadBytes ].
	request := self grpcRequestClass
		service: self traceServiceName
		method: self traceServiceMethodName
		payload: requestPayload.
	request
		timeoutNanos: self configuration timeoutMillis * 1000000;
		metadata: self grpcMetadataFromConfigurationHeaders.
	(self hasUserAgentHeaderConfigured: self configuration headers)
		ifFalse: [ request userAgent: self configuration userAgent ].
	self configuration usesGzipCompression ifTrue: [
		request messageEncoding: 'gzip' ].
	^ request
]

{ #category : 'private - grpc' }
OTOtlpGrpcSpanExporter >> grpcTransport [

	^ grpcTransport ifNil: [ grpcTransport := self grpcTransportClass new ]
]

{ #category : 'private - grpc' }
OTOtlpGrpcSpanExporter >> grpcTransport: aTransport [

	grpcTransport := aTransport.
	grpcChannel := nil
]

{ #category : 'private - grpc' }
OTOtlpGrpcSpanExporter >> grpcTransportClass [

	^ self grpcDependencyNamed: #GRPCHTTP2Transport
]

{ #category : 'private - success handling' }
OTOtlpGrpcSpanExporter >> handleSuccessGrpcResponse: aResponse [

	| partialSuccess responseRepresentation |
	responseRepresentation := [ self successfulResponseRepresentationFromGrpcResponse: aResponse ]
		on: Error
		do: [ :error |
			self noteInvalidGrpcSuccessResponse: error.
			^ false ].
	partialSuccess := self partialSuccessFrom: responseRepresentation.
	partialSuccess ifNil: [ ^ true ].
	self notePartialSuccess: partialSuccess.
	^ true
]

{ #category : 'private - retry' }
OTOtlpGrpcSpanExporter >> isRetryableStatus: aStatus [

	^ self class retryableStatusCodes includes: aStatus code
]

{ #category : 'private - logging' }
OTOtlpGrpcSpanExporter >> noteInvalidGrpcSuccessResponse: anError [

	self warningSink value:
		'OpenTelemetry OTLP trace export returned an invalid gRPC success response: '
			, anError messageText
]

{ #category : 'private - logging' }
OTOtlpGrpcSpanExporter >> noteRetryExhaustedForStatus: aStatus [

	self warningSink value:
		'OpenTelemetry OTLP trace export exhausted retries after gRPC status '
			, aStatus codeName, ' (', aStatus code asString, ')'
]

{ #category : 'private - encoding' }
OTOtlpGrpcSpanExporter >> payloadBytesFrom: spans [

	^ self encoder encodeSpans: spans asArray
]

{ #category : 'private - grpc' }
OTOtlpGrpcSpanExporter >> requestExecutor: aBlockClosure [

	requestExecutor := aBlockClosure
]

{ #category : 'private - success handling' }
OTOtlpGrpcSpanExporter >> successfulResponseRepresentationFromGrpcResponse: aResponse [

	| payload |
	payload := aResponse payload.
	payload ifNil: [ Error signal: 'Missing OTLP gRPC success response body' ].
	^ self responseDecoder decodeResponse: payload
]

{ #category : 'private - grpc' }
OTOtlpGrpcSpanExporter >> traceServiceMethodName [

	^ 'Export'
]

{ #category : 'private - grpc' }
OTOtlpGrpcSpanExporter >> traceServiceName [

	^ 'opentelemetry.proto.collector.trace.v1.TraceService'
]
