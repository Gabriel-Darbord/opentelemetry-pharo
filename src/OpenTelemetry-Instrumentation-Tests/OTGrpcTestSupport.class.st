Class {
	#name : 'OTGrpcTestSupport',
	#superclass : 'Object',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'accessing' }
OTGrpcTestSupport class >> actualGrpcClassNamed: aSymbol [

	^ Smalltalk globals at: aSymbol ifAbsent: [ nil ]
]

{ #category : 'accessing' }
OTGrpcTestSupport class >> fakeGrpcDependencyNamed: aSymbol [

	aSymbol = #GRPCChannel ifTrue: [ ^ OTFakeGRPCChannel ].
	aSymbol = #GRPCEndpoint ifTrue: [ ^ OTFakeGRPCEndpoint ].
	aSymbol = #GRPCMetadata ifTrue: [ ^ OTFakeGRPCMetadata ].
	aSymbol = #GRPCRequest ifTrue: [ ^ OTFakeGRPCRequest ].
	aSymbol = #GRPCHTTP2Transport ifTrue: [ ^ OTFakeGRPCHTTP2Transport ].
	^ self actualGrpcClassNamed: aSymbol
]

{ #category : 'testing' }
OTGrpcTestSupport class >> hasActualGrpcTransportStack [

	^ #( GRPCHTTP2DataFrame GRPCHTTP2FrameReader GRPCHTTP2FrameWriter GRPCHTTP2HeadersFrame GRPCHTTP2MockStream GRPCHTTP2Settings
	     GRPCHTTP2SettingsFrame GRPCHTTP2Transport GRPCMessageFramer ) allSatisfy: [ :each |
		  (self actualGrpcClassNamed: each) notNil ]
]

{ #category : 'running' }
OTGrpcTestSupport class >> installFakeGrpcResolvers [

	OTOtlpGrpcSpanExporter grpcDependencyResolver: [ :symbol | self fakeGrpcDependencyNamed: symbol ].
	OTJaegerRemoteSampler grpcDependencyResolver: [ :symbol | self fakeGrpcDependencyNamed: symbol ]
]

{ #category : 'running' }
OTGrpcTestSupport class >> removeFakeGrpcResolvers [

	OTOtlpGrpcSpanExporter grpcDependencyResolver: nil.
	OTJaegerRemoteSampler grpcDependencyResolver: nil
]
