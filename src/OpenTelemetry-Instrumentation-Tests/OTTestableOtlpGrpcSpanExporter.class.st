Class {
	#name : 'OTTestableOtlpGrpcSpanExporter',
	#superclass : 'OTOtlpGrpcSpanExporter',
	#instVars : [
		'operatingSystemNameOverride',
		'grpcSecureSocketStreamClassOverride',
		'grpcSocketStreamClassOverride'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'private - grpc' }
OTTestableOtlpGrpcSpanExporter >> grpcSecureSocketStreamClass [

	^ grpcSecureSocketStreamClassOverride ifNil: [ super grpcSecureSocketStreamClass ]
]

{ #category : 'accessing' }
OTTestableOtlpGrpcSpanExporter >> grpcSecureSocketStreamClass: aClass [

	grpcSecureSocketStreamClassOverride := aClass
]

{ #category : 'private - grpc' }
OTTestableOtlpGrpcSpanExporter >> grpcSocketStreamClass [

	^ grpcSocketStreamClassOverride ifNil: [ super grpcSocketStreamClass ]
]

{ #category : 'accessing' }
OTTestableOtlpGrpcSpanExporter >> grpcSocketStreamClass: aClass [

	grpcSocketStreamClassOverride := aClass
]

{ #category : 'private - tls' }
OTTestableOtlpGrpcSpanExporter >> operatingSystemName [

	^ operatingSystemNameOverride ifNil: [ super operatingSystemName ]
]

{ #category : 'accessing' }
OTTestableOtlpGrpcSpanExporter >> operatingSystemName: aString [

	operatingSystemNameOverride := aString
]
