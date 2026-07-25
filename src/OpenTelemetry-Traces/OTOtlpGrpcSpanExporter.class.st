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
	#category : 'OpenTelemetry-Traces',
	#package : 'OpenTelemetry-Traces'
}

{ #category : 'private - grpc' }
OTOtlpGrpcSpanExporter class >> grpcDependencyResolver [

	^ OTClassStateStore
		  valueAt: #otGrpcDependencyResolver
		  forClass: OTOtlpGrpcSpanExporter
		  ifAbsent: [ [ :symbol | Smalltalk globals at: symbol ifAbsent: [ nil ] ] ]
]

{ #category : 'private - grpc' }
OTOtlpGrpcSpanExporter class >> grpcDependencyResolver: aBlockOrNil [

	aBlockOrNil
		ifNil: [ OTClassStateStore removeValueAt: #otGrpcDependencyResolver forClass: OTOtlpGrpcSpanExporter ifAbsent: [ ] ]
		ifNotNil: [ OTClassStateStore valueAt: #otGrpcDependencyResolver forClass: OTOtlpGrpcSpanExporter put: aBlockOrNil ].
	^ self grpcDependencyResolver
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

	^ requestExecutor ifNil: [ self grpcChannel executeUnaryRequest: aRequest ] ifNotNil: [ requestExecutor value: aRequest ]
]

{ #category : 'exporting' }
OTOtlpGrpcSpanExporter >> export: anObject [

	^ self withExportLockDo: [
			  self isShutdown ifTrue: [ ^ false ].
			  self exportAttemptNumber: 1 payloadBytes: (self payloadBytesFrom: anObject) ]
]

{ #category : 'exporting' }
OTOtlpGrpcSpanExporter >> exportAttemptNumber: attemptNumber payloadBytes: payloadBytes [

	| request response status |
	request := self grpcRequestForPayloadBytes: payloadBytes.
	[ response := self executeGrpcRequest: request ]
		on: Error
		do: [ :error |
				attemptNumber >= self maxExportAttempts ifTrue: [
						self noteRetryExhaustedForError: error.
						^ false ].
				self sleepForMilliseconds: (self retryDelayMillisForAttempt: attemptNumber response: nil).
				^ self exportAttemptNumber: attemptNumber + 1 payloadBytes: payloadBytes ].
	status := response status.
	status isOk ifTrue: [ ^ self handleSuccessGrpcResponse: response ].
	(self isRetryableStatus: status) ifFalse: [ ^ false ].
	attemptNumber >= self maxExportAttempts ifTrue: [
			self noteRetryExhaustedForStatus: status.
			^ false ].
	self sleepForMilliseconds: (self retryDelayMillisForAttempt: attemptNumber response: nil).
	^ self exportAttemptNumber: attemptNumber + 1 payloadBytes: payloadBytes
]

{ #category : 'private - grpc' }
OTOtlpGrpcSpanExporter >> grpcChannel [

	^ grpcChannel ifNil: [
			  grpcChannel := self grpcChannelClass
				                 endpoint: (self grpcEndpointClass fromString: self configuration resolvedGrpcEndpoint)
				                 transport: self grpcTransport ]
]

{ #category : 'private - grpc' }
OTOtlpGrpcSpanExporter >> grpcChannelClass [

	^ self grpcDependencyNamed: #GRPCChannel
]

{ #category : 'private - grpc' }
OTOtlpGrpcSpanExporter >> grpcDependencyNamed: aSymbol [

	| dependency |
	dependency := self class grpcDependencyResolver value: aSymbol.
	^ dependency
		  ifNil: [
				  Error signal: (String streamContents: [ :stream |
							   stream
								   nextPutAll: 'OTOtlpGrpcSpanExporter requires grpc-pharo to be loaded (missing ';
								   nextPutAll: aSymbol asString;
								   nextPut: $) ]) ]
		  ifNotNil: [ dependency ]
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
	self configuration headers associationsDo: [ :each | metadata addKey: each key asLowercase value: each value ].
	^ metadata
]

{ #category : 'private - grpc' }
OTOtlpGrpcSpanExporter >> grpcRequestClass [

	^ self grpcDependencyNamed: #GRPCRequest
]

{ #category : 'private - grpc' }
OTOtlpGrpcSpanExporter >> grpcRequestForPayloadBytes: payloadBytes [

	| request requestPayload timeoutMillis |
	requestPayload := self configuration usesGzipCompression
		                  ifTrue: [ self gzipCompressedBytesFor: payloadBytes ]
		                  ifFalse: [ payloadBytes ].
	request := self grpcRequestClass service: self grpcServiceName method: self grpcServiceMethodName payload: requestPayload.
	timeoutMillis := self configuration timeoutMillisOrNil.
	timeoutMillis ifNotNil: [ request timeoutNanos: timeoutMillis * 1000000 ].
	request metadata: self grpcMetadataFromConfigurationHeaders.
	(self hasUserAgentHeaderConfigured: self configuration headers) ifFalse: [ request userAgent: self configuration userAgent ].
	self configuration usesGzipCompression ifTrue: [ request messageEncoding: 'gzip' ].
	^ request
]

{ #category : 'private - grpc' }
OTOtlpGrpcSpanExporter >> grpcSecureSocketStreamClass [

	^ self grpcDependencyNamed: #ZdcSecureSocketStream
]

{ #category : 'private - grpc' }
OTOtlpGrpcSpanExporter >> grpcServiceMethodName [

	^ 'Export'
]

{ #category : 'private - grpc' }
OTOtlpGrpcSpanExporter >> grpcServiceName [

	^ 'opentelemetry.proto.collector.trace.v1.TraceService'
]

{ #category : 'private - grpc' }
OTOtlpGrpcSpanExporter >> grpcSocketStreamClass [

	^ self grpcDependencyNamed: #ZdcSocketStream
]

{ #category : 'private - grpc' }
OTOtlpGrpcSpanExporter >> grpcTimeoutSeconds [

	| timeoutMillis |
	timeoutMillis := self configuration timeoutMillisOrNil.
	timeoutMillis ifNil: [ ^ nil ].
	^ (timeoutMillis max: 1000) + 999 // 1000
]

{ #category : 'private - grpc' }
OTOtlpGrpcSpanExporter >> grpcTransport [

	^ grpcTransport ifNil: [
			  | transport |
			  transport := self grpcTransportClass new.
			  transport streamFactory: [ :endpoint | self openConfiguredGrpcStreamTo: endpoint ].
			  grpcTransport := transport ]
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
		(OTOtlpExportSupport invalidSuccessResponseMessageForSignal: self otlpSignalName transport: 'gRPC' error: anError)
]

{ #category : 'private - logging' }
OTOtlpGrpcSpanExporter >> noteRetryExhaustedForStatus: aStatus [

	self warningSink value: (OTOtlpExportSupport retryExhaustedForGrpcStatusMessageForSignal: self otlpSignalName status: aStatus)
]

{ #category : 'private - grpc' }
OTOtlpGrpcSpanExporter >> openConfiguredGrpcStreamTo: aGRPCEndpoint [

	| port timeoutSeconds |
	port := aGRPCEndpoint port ifNil: [
			        aGRPCEndpoint isSecure
				        ifTrue: [ 443 ]
				        ifFalse: [ 80 ] ].
	timeoutSeconds := self grpcTimeoutSeconds.
	aGRPCEndpoint isSecure ifFalse: [
			| socketStream |
			socketStream := self grpcSocketStreamClass openConnectionToHostNamed: aGRPCEndpoint host port: port.
			timeoutSeconds ifNotNil: [ socketStream timeout: timeoutSeconds ].
			^ socketStream ].
	^ self withConfiguredTlsDuring: [ :certificateName |
			  | socketStream |
			  socketStream := self grpcSecureSocketStreamClass openConnectionToHostNamed: aGRPCEndpoint host port: port.
			  timeoutSeconds ifNotNil: [ socketStream timeout: timeoutSeconds ].
			  certificateName ifNotNil: [ socketStream sslSession certificateName: certificateName ].
			  socketStream sslSession serverName: aGRPCEndpoint host.
			  socketStream connect.
			  socketStream ]
]

{ #category : 'private - encoding' }
OTOtlpGrpcSpanExporter >> payloadBytesFrom: anObject [

	^ self encoder perform: self payloadEncodingSelector with: (self normalizedPayloadForEncoding: anObject)
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
