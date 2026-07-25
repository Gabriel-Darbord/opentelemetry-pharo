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
OTOtlpGrpcMetricExporter >> defaultEncoderClass [

	^ OTOtlpProtobufMetricEncoder
]

{ #category : 'accessing' }
OTOtlpGrpcMetricExporter >> defaultResponseDecoderClass [

	^ OTOtlpProtobufMetricResponseDecoder
]

{ #category : 'private - grpc' }
OTOtlpGrpcMetricExporter >> grpcServiceName [

	^ 'opentelemetry.proto.collector.metrics.v1.MetricsService'
]

{ #category : 'private - encoding' }
OTOtlpGrpcMetricExporter >> normalizedPayloadForEncoding: anOTMetricSnapshot [

	^ anOTMetricSnapshot
]

{ #category : 'private - logging' }
OTOtlpGrpcMetricExporter >> otlpSignalName [

	^ 'metric'
]

{ #category : 'private - encoding' }
OTOtlpGrpcMetricExporter >> payloadEncodingSelector [

	^ #encodeSnapshot:
]
