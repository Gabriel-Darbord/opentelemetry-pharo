Class {
	#name : 'OTFakeGRPCChannel',
	#superclass : 'Object',
	#instVars : [
		'endpoint',
		'transport',
		'defaultMetadata',
		'userAgent'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'instance creation' }
OTFakeGRPCChannel class >> endpoint: anEndpoint transport: aTransport [

	^ self new
		  endpoint: anEndpoint;
		  transport: aTransport;
		  yourself
]

{ #category : 'initialization' }
OTFakeGRPCChannel >> initialize [

	super initialize.
	defaultMetadata := OTFakeGRPCMetadata new.
	userAgent := 'grpc-pharo/fake'
]

{ #category : 'accessing' }
OTFakeGRPCChannel >> defaultMetadata [

	^ defaultMetadata
]

{ #category : 'accessing' }
OTFakeGRPCChannel >> defaultMetadata: aMetadata [

	defaultMetadata := aMetadata
]

{ #category : 'accessing' }
OTFakeGRPCChannel >> endpoint [

	^ endpoint
]

{ #category : 'accessing' }
OTFakeGRPCChannel >> endpoint: anEndpoint [

	endpoint := anEndpoint
]

{ #category : 'executing' }
OTFakeGRPCChannel >> executeUnaryRequest: aRequest [

	^ self transport
		  executeUnaryRequest: aRequest
		  endpoint: self endpoint
		  defaultMetadata: self defaultMetadata
		  userAgent: self userAgent
]

{ #category : 'accessing' }
OTFakeGRPCChannel >> transport [

	^ transport
]

{ #category : 'accessing' }
OTFakeGRPCChannel >> transport: aTransport [

	transport := aTransport
]

{ #category : 'accessing' }
OTFakeGRPCChannel >> userAgent [

	^ userAgent
]

{ #category : 'accessing' }
OTFakeGRPCChannel >> userAgent: aString [

	userAgent := aString
]
