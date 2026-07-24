Class {
	#name : 'OTFakeGRPCRequest',
	#superclass : 'Object',
	#instVars : [
		'serviceName',
		'methodName',
		'payload',
		'metadata',
		'timeoutNanos',
		'messageEncoding',
		'acceptedMessageEncodings',
		'contentType',
		'userAgent'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'instance creation' }
OTFakeGRPCRequest class >> service: aServiceName method: aMethodName payload: aByteArray [

	^ self new
		  serviceName: aServiceName;
		  methodName: aMethodName;
		  payload: aByteArray;
		  yourself
]

{ #category : 'timeouts' }
OTFakeGRPCRequest class >> timeoutHeaderValueForNanos: aPositiveInteger [

	| cutoff timeout |
	cutoff := 100000000.
	timeout := aPositiveInteger max: 1.
	timeout < cutoff ifTrue: [ ^ timeout asString , 'n' ].
	timeout < (cutoff * 1000) ifTrue: [ ^ (timeout // 1000) asString , 'u' ].
	timeout < (cutoff * 1000 * 1000) ifTrue: [ ^ (timeout // 1000000) asString , 'm' ].
	timeout < (cutoff * 1000 * 1000 * 1000) ifTrue: [ ^ (timeout // 1000000000) asString , 'S' ].
	timeout < (cutoff * 1000 * 1000 * 1000 * 60) ifTrue: [ ^ (timeout // 60000000000) asString , 'M' ].
	^ (timeout // 3600000000000) asString , 'H'
]

{ #category : 'accessing' }
OTFakeGRPCRequest >> contentType [

	^ contentType
]

{ #category : 'accessing' }
OTFakeGRPCRequest >> grpcTimeoutHeaderValue [

	timeoutNanos ifNil: [ ^ nil ].
	^ self class timeoutHeaderValueForNanos: timeoutNanos
]

{ #category : 'initialization' }
OTFakeGRPCRequest >> initialize [

	super initialize.
	payload := #[  ].
	metadata := OTFakeGRPCMetadata new.
	acceptedMessageEncodings := #( 'identity' 'gzip' ).
	contentType := 'application/grpc+proto'
]

{ #category : 'accessing' }
OTFakeGRPCRequest >> messageEncoding [

	^ messageEncoding
]

{ #category : 'accessing' }
OTFakeGRPCRequest >> messageEncoding: aStringOrNil [

	messageEncoding := aStringOrNil
]

{ #category : 'accessing' }
OTFakeGRPCRequest >> metadata [

	^ metadata
]

{ #category : 'accessing' }
OTFakeGRPCRequest >> metadata: aMetadata [

	metadata := aMetadata
]

{ #category : 'accessing' }
OTFakeGRPCRequest >> methodName [

	^ methodName
]

{ #category : 'accessing' }
OTFakeGRPCRequest >> methodName: aString [

	methodName := aString
]

{ #category : 'accessing' }
OTFakeGRPCRequest >> payload [

	^ payload
]

{ #category : 'accessing' }
OTFakeGRPCRequest >> payload: aByteArray [

	payload := aByteArray
]

{ #category : 'accessing' }
OTFakeGRPCRequest >> serviceName [

	^ serviceName
]

{ #category : 'accessing' }
OTFakeGRPCRequest >> serviceName: aString [

	serviceName := aString
]

{ #category : 'accessing' }
OTFakeGRPCRequest >> timeoutNanos [

	^ timeoutNanos
]

{ #category : 'accessing' }
OTFakeGRPCRequest >> timeoutNanos: anIntegerOrNil [

	timeoutNanos := anIntegerOrNil
]

{ #category : 'accessing' }
OTFakeGRPCRequest >> userAgent [

	^ userAgent
]

{ #category : 'accessing' }
OTFakeGRPCRequest >> userAgent: aStringOrNil [

	userAgent := aStringOrNil
]
