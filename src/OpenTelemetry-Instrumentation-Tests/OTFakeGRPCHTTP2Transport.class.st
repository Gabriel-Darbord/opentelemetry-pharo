Class {
	#name : 'OTFakeGRPCHTTP2Transport',
	#superclass : 'Object',
	#instVars : [
		'streamFactory',
		'requestExecutor',
		'response'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'accessing' }
OTFakeGRPCHTTP2Transport >> requestExecutor: aBlock [

	requestExecutor := aBlock
]

{ #category : 'accessing' }
OTFakeGRPCHTTP2Transport >> response: anObject [

	response := anObject
]

{ #category : 'executing' }
OTFakeGRPCHTTP2Transport >> executeUnaryRequest: aRequest endpoint: anEndpoint defaultMetadata: aMetadata userAgent: aString [

	requestExecutor ifNotNil: [ ^ requestExecutor value: aRequest ].
	response ifNotNil: [ ^ response ].
	Error signal: 'No fake gRPC transport response configured'
]

{ #category : 'accessing' }
OTFakeGRPCHTTP2Transport >> streamFactory [

	^ streamFactory
]

{ #category : 'accessing' }
OTFakeGRPCHTTP2Transport >> streamFactory: aBlock [

	streamFactory := aBlock
]
