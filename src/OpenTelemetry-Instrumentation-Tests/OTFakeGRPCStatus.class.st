Class {
	#name : 'OTFakeGRPCStatus',
	#superclass : 'Object',
	#instVars : [
		'code',
		'message'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'instance creation' }
OTFakeGRPCStatus class >> code: anInteger message: aStringOrNil [

	^ self new
		code: anInteger;
		message: aStringOrNil;
		yourself
]

{ #category : 'instance creation' }
OTFakeGRPCStatus class >> ok [

	^ self code: 0 message: nil
]

{ #category : 'accessing' }
OTFakeGRPCStatus >> code [

	^ code
]

{ #category : 'accessing' }
OTFakeGRPCStatus >> code: anInteger [

	code := anInteger
]

{ #category : 'accessing' }
OTFakeGRPCStatus >> codeName [

	| names |
	names := #(
		'OK'
		'CANCELLED'
		'UNKNOWN'
		'INVALID_ARGUMENT'
		'DEADLINE_EXCEEDED'
		'NOT_FOUND'
		'ALREADY_EXISTS'
		'PERMISSION_DENIED'
		'RESOURCE_EXHAUSTED'
		'FAILED_PRECONDITION'
		'ABORTED'
		'OUT_OF_RANGE'
		'UNIMPLEMENTED'
		'INTERNAL'
		'UNAVAILABLE'
		'DATA_LOSS'
		'UNAUTHENTICATED').
	((self code between: 0 and: names size - 1) not) ifTrue: [ ^ 'UNKNOWN' ].
	^ names at: self code + 1
]

{ #category : 'testing' }
OTFakeGRPCStatus >> isOk [

	^ self code = 0
]

{ #category : 'accessing' }
OTFakeGRPCStatus >> message [

	^ message
]

{ #category : 'accessing' }
OTFakeGRPCStatus >> message: aStringOrNil [

	message := aStringOrNil
]
