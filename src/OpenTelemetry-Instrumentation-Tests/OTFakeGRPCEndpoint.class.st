Class {
	#name : 'OTFakeGRPCEndpoint',
	#superclass : 'Object',
	#instVars : [
		'scheme',
		'host',
		'port'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'instance creation' }
OTFakeGRPCEndpoint class >> fromString: aString [

	^ self fromZnUrl: (ZnUrl fromString: aString)
]

{ #category : 'instance creation' }
OTFakeGRPCEndpoint class >> fromZnUrl: aZnUrl [

	^ self
		  scheme: aZnUrl scheme
		  host: aZnUrl host
		  port: aZnUrl port
]

{ #category : 'instance creation' }
OTFakeGRPCEndpoint class >> scheme: aSchemeString host: aHostString port: anIntegerOrNil [

	^ self new
		  scheme: aSchemeString;
		  host: aHostString;
		  port: anIntegerOrNil;
		  yourself
]

{ #category : 'accessing' }
OTFakeGRPCEndpoint >> authority [

	(self port isNil or: [ self port = self defaultPort ]) ifTrue: [ ^ self host ].
	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: self host;
			  nextPut: $:;
			  print: self port ]
]

{ #category : 'private' }
OTFakeGRPCEndpoint >> defaultPort [

	self scheme = 'http' ifTrue: [ ^ 80 ].
	self scheme = 'https' ifTrue: [ ^ 443 ].
	^ nil
]

{ #category : 'accessing' }
OTFakeGRPCEndpoint >> host [

	^ host
]

{ #category : 'accessing' }
OTFakeGRPCEndpoint >> host: aString [

	host := aString
]

{ #category : 'testing' }
OTFakeGRPCEndpoint >> isSecure [

	^ self scheme = 'https'
]

{ #category : 'accessing' }
OTFakeGRPCEndpoint >> port [

	^ port
]

{ #category : 'accessing' }
OTFakeGRPCEndpoint >> port: anIntegerOrNil [

	port := anIntegerOrNil
]

{ #category : 'accessing' }
OTFakeGRPCEndpoint >> scheme [

	^ scheme
]

{ #category : 'accessing' }
OTFakeGRPCEndpoint >> scheme: aString [

	scheme := aString ifNil: [ 'http' ]
]
