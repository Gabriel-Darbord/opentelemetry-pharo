"
An OTLP metrics exporter that sends protobuf-encoded ExportMetricsServiceRequest payloads over gRPC.
"
Class {
	#name : 'OTOtlpGrpcMetricExporter',
	#superclass : 'OTOtlpGrpcSpanExporter',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'accessing' }
OTOtlpGrpcMetricExporter >> encoder [

	^ encoder ifNil: [ encoder := OTOtlpProtobufMetricEncoder new ]
]

{ #category : 'exporting' }
OTOtlpGrpcMetricExporter >> export: anOTMetricSnapshot [

	self isShutdown ifTrue: [ ^ false ].
	^ self exportAttemptNumber: 1 payloadBytes: (self payloadBytesFrom: anOTMetricSnapshot)
]

{ #category : 'private - logging' }
OTOtlpGrpcMetricExporter >> noteInvalidGrpcSuccessResponse: anError [

	self warningSink value: 'OpenTelemetry OTLP metric export returned an invalid gRPC success response: ' , anError messageText
]

{ #category : 'private - logging' }
OTOtlpGrpcMetricExporter >> notePartialSuccess: aDictionary [

	self warningSink value: 'OpenTelemetry OTLP metric export reported partial success: ' , aDictionary printString
]

{ #category : 'private - logging' }
OTOtlpGrpcMetricExporter >> noteRetryExhaustedForError: anError [

	self warningSink value:
		'OpenTelemetry OTLP metric export exhausted retries after a retryable transport failure: ' , anError messageText
]

{ #category : 'private - logging' }
OTOtlpGrpcMetricExporter >> noteRetryExhaustedForStatus: aStatus [

	self warningSink value:
		'OpenTelemetry OTLP metric export exhausted retries after gRPC status ' , aStatus codeName , ' (' , aStatus code asString , ')'
]

{ #category : 'private - encoding' }
OTOtlpGrpcMetricExporter >> payloadBytesFrom: anOTMetricSnapshot [

	^ self encoder encodeSnapshot: anOTMetricSnapshot
]

{ #category : 'accessing' }
OTOtlpGrpcMetricExporter >> responseDecoder [

	^ responseDecoder ifNil: [ responseDecoder := OTOtlpProtobufMetricResponseDecoder new ]
]

{ #category : 'private - grpc' }
OTOtlpGrpcMetricExporter >> traceServiceName [

	^ 'opentelemetry.proto.collector.metrics.v1.MetricsService'
]
