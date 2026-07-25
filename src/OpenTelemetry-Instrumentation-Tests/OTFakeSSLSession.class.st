Class {
	#name : 'OTFakeSSLSession',
	#superclass : 'Object',
	#instVars : [
		'certificateName',
		'serverName'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'accessing' }
OTFakeSSLSession >> certificateName [

	^ certificateName
]

{ #category : 'accessing' }
OTFakeSSLSession >> certificateName: aStringOrNil [

	certificateName := aStringOrNil
]

{ #category : 'accessing' }
OTFakeSSLSession >> serverName [

	^ serverName
]

{ #category : 'accessing' }
OTFakeSSLSession >> serverName: aStringOrNil [

	serverName := aStringOrNil
]
