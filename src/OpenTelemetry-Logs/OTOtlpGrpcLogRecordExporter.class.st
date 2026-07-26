"
An OTLP logs exporter that sends protobuf-encoded ExportLogsServiceRequest payloads over gRPC.

Per exporter instance, exports run through the shared OTLP gRPC export lock so the SDK never invokes transport sends concurrently. ForceFlush and Shutdown may still race with exporter-managed work and therefore follow the lifecycle contract documented on the exporter base classes.
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

{ #category : 'private - encoding' }
OTOtlpGrpcLogRecordExporter >> encodedPayloadFrom: logRecords [

	^ self encoder encodeLogRecords: logRecords
]

{ #category : 'private - grpc' }
OTOtlpGrpcLogRecordExporter >> grpcServiceName [

	^ 'opentelemetry.proto.collector.logs.v1.LogsService'
]

{ #category : 'private - logging' }
OTOtlpGrpcLogRecordExporter >> otlpSignalName [

	^ 'log'
]
