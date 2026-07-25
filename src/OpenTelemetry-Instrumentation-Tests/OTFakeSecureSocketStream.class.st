Class {
	#name : 'OTFakeSecureSocketStream',
	#superclass : 'Object',
	#instVars : [
		'host',
		'port',
		'timeout',
		'sslSession',
		'connected',
		'sslCertFileDuringConnect'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'instance creation' }
OTFakeSecureSocketStream class >> openConnectionToHostNamed: aString port: anInteger [

	^ self new
		  host: aString;
		  port: anInteger;
		  sslSession: OTFakeSSLSession new;
		  yourself
]

{ #category : 'ssl' }
OTFakeSecureSocketStream >> connect [

	connected := true.
	sslCertFileDuringConnect := Smalltalk os environment at: 'SSL_CERT_FILE' ifAbsent: [ nil ]
]

{ #category : 'testing' }
OTFakeSecureSocketStream >> connected [

	^ connected = true
]

{ #category : 'accessing' }
OTFakeSecureSocketStream >> host [

	^ host
]

{ #category : 'accessing' }
OTFakeSecureSocketStream >> host: aString [

	host := aString
]

{ #category : 'accessing' }
OTFakeSecureSocketStream >> port [

	^ port
]

{ #category : 'accessing' }
OTFakeSecureSocketStream >> port: anInteger [

	port := anInteger
]

{ #category : 'accessing' }
OTFakeSecureSocketStream >> sslCertFileDuringConnect [

	^ sslCertFileDuringConnect
]

{ #category : 'accessing' }
OTFakeSecureSocketStream >> sslSession [

	^ sslSession
]

{ #category : 'accessing' }
OTFakeSecureSocketStream >> sslSession: anObject [

	sslSession := anObject
]

{ #category : 'accessing' }
OTFakeSecureSocketStream >> timeout [

	^ timeout
]

{ #category : 'accessing' }
OTFakeSecureSocketStream >> timeout: anInteger [

	timeout := anInteger
]
