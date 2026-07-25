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
OTOtlpGrpcLogRecordExporter >> defaultEncoderClass [

	^ OTOtlpProtobufLogRecordEncoder
]

{ #category : 'accessing' }
OTOtlpGrpcLogRecordExporter >> defaultResponseDecoderClass [

	^ OTOtlpProtobufLogRecordResponseDecoder
]

{ #category : 'private - grpc' }
OTOtlpGrpcLogRecordExporter >> grpcServiceName [

	^ 'opentelemetry.proto.collector.logs.v1.LogsService'
]

{ #category : 'private - logging' }
OTOtlpGrpcLogRecordExporter >> otlpSignalName [

	^ 'log'
]

{ #category : 'private - encoding' }
OTOtlpGrpcLogRecordExporter >> encodedPayloadFrom: logRecords [

	^ self encoder encodeLogRecords: logRecords
]
