"
An OTLP logs exporter that sends protobuf-encoded ExportLogsServiceRequest payloads over gRPC.
"
Class {
	#name : 'OTOtlpGrpcLogRecordExporter',
	#superclass : 'OTOtlpGrpcSpanExporter',
	#category : 'OpenTelemetry-Logs',
	#package : 'OpenTelemetry-Logs'
}

{ #category : 'accessing' }
OTOtlpGrpcLogRecordExporter >> encoder [

	^ encoder ifNil: [ encoder := OTOtlpProtobufLogRecordEncoder new ]
]

{ #category : 'exporting' }
OTOtlpGrpcLogRecordExporter >> export: logRecords [

	self isShutdown ifTrue: [ ^ false ].
	^ self
		exportAttemptNumber: 1
		payloadBytes: (self payloadBytesFrom: logRecords)
]

{ #category : 'private - logging' }
OTOtlpGrpcLogRecordExporter >> noteInvalidGrpcSuccessResponse: anError [

	self warningSink value:
		'OpenTelemetry OTLP log export returned an invalid gRPC success response: '
			, anError messageText
]

{ #category : 'private - logging' }
OTOtlpGrpcLogRecordExporter >> notePartialSuccess: aDictionary [

	self warningSink value:
		'OpenTelemetry OTLP log export reported partial success: '
			, aDictionary printString
]

{ #category : 'private - logging' }
OTOtlpGrpcLogRecordExporter >> noteRetryExhaustedForError: anError [

	self warningSink value:
		'OpenTelemetry OTLP log export exhausted retries after a retryable transport failure: '
			, anError messageText
]

{ #category : 'private - logging' }
OTOtlpGrpcLogRecordExporter >> noteRetryExhaustedForStatus: aStatus [

	self warningSink value:
		'OpenTelemetry OTLP log export exhausted retries after gRPC status '
			, aStatus codeName, ' (', aStatus code asString, ')'
]

{ #category : 'private - encoding' }
OTOtlpGrpcLogRecordExporter >> payloadBytesFrom: logRecords [

	^ self encoder encodeLogRecords: logRecords asArray
]

{ #category : 'accessing' }
OTOtlpGrpcLogRecordExporter >> responseDecoder [

	^ responseDecoder ifNil: [
		  responseDecoder := OTOtlpProtobufLogRecordResponseDecoder new ]
]

{ #category : 'private - grpc' }
OTOtlpGrpcLogRecordExporter >> traceServiceName [

	^ 'opentelemetry.proto.collector.logs.v1.LogsService'
]
