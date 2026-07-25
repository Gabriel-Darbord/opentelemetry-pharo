Class {
	#name : 'OTFakeGRPCResponse',
	#superclass : 'Object',
	#instVars : [
		'status',
		'payload'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'instance creation' }
OTFakeGRPCResponse class >> status: aStatus payload: aByteArrayOrNil [

	^ self new
		  status: aStatus;
		  payload: aByteArrayOrNil;
		  yourself
]

{ #category : 'accessing' }
OTFakeGRPCResponse >> payload [

	^ payload
]

{ #category : 'accessing' }
OTFakeGRPCResponse >> payload: aByteArrayOrNil [

	payload := aByteArrayOrNil
]

{ #category : 'accessing' }
OTFakeGRPCResponse >> status [

	^ status
]

{ #category : 'accessing' }
OTFakeGRPCResponse >> status: aStatus [

	status := aStatus
]
