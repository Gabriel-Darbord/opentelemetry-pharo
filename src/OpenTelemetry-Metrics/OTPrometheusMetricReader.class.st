Class {
	#name : 'OTPrometheusMetricReader',
	#superclass : 'OTMetricReader',
	#instVars : [
		'host',
		'port',
		'path',
		'encoder',
		'server'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'private - http' }
OTPrometheusMetricReader >> bindingAddressForHost [

	host ifNil: [ ^ #[127 0 0 1] ].
	(host sameAs: 'localhost') ifTrue: [ ^ #[127 0 0 1] ].
	host = '0.0.0.0' ifTrue: [ ^ nil ].
	^ NetNameResolver addressForName: host timeout: 5
]

{ #category : 'collecting' }
OTPrometheusMetricReader >> collect [

	^ self collectSnapshot
]

{ #category : 'private - http' }
OTPrometheusMetricReader >> contentTypeString [

	^ 'text/plain; version=0.0.4; charset=utf-8'
]

{ #category : 'callbacks' }
OTPrometheusMetricReader >> didRegisterWithProvider [

	self startServer
]

{ #category : 'accessing' }
OTPrometheusMetricReader >> encoder [

	^ encoder ifNil: [ encoder := OTPrometheusTextEncoder new ]
]

{ #category : 'accessing' }
OTPrometheusMetricReader >> encoder: anOTPrometheusTextEncoder [

	encoder := anOTPrometheusTextEncoder
]

{ #category : 'private - http' }
OTPrometheusMetricReader >> handleRequest: aZnRequest [

	(aZnRequest method = #GET
		and: [ aZnRequest uri pathPrintString = self path ])
		ifTrue: [ ^ self metricsResponse ].
	^ ZnResponse notFound: aZnRequest uri
]

{ #category : 'accessing' }
OTPrometheusMetricReader >> host [

	^ host ifNil: [ 'localhost' ]
]

{ #category : 'accessing' }
OTPrometheusMetricReader >> host: aString [

	host := aString ifNil: [ 'localhost' ] ifNotNil: [ aString asString ]
]

{ #category : 'initialization' }
OTPrometheusMetricReader >> initialize [

	super initialize.
	host := 'localhost'.
	port := 9464.
	path := '/metrics'.
	encoder := OTPrometheusTextEncoder new.
	server := nil
]

{ #category : 'private - http' }
OTPrometheusMetricReader >> metricsResponse [

	| entity |
	entity := ZnEntity text: self scrapeText.
	entity contentType: self contentTypeString.
	^ ZnResponse ok: entity
]

{ #category : 'accessing' }
OTPrometheusMetricReader >> path [

	^ path ifNil: [ '/metrics' ]
]

{ #category : 'accessing' }
OTPrometheusMetricReader >> path: aString [

	| normalized |
	normalized := aString ifNil: [ '/metrics' ] ifNotNil: [ aString asString ].
	path := normalized isEmpty
		ifTrue: [ '/metrics' ]
		ifFalse: [
			normalized first = $/
				ifTrue: [ normalized ]
				ifFalse: [ '/' , normalized ] ]
]

{ #category : 'accessing' }
OTPrometheusMetricReader >> port [

	^ port ifNil: [ 9464 ]
]

{ #category : 'accessing' }
OTPrometheusMetricReader >> port: anInteger [

	port := anInteger ifNil: [ 9464 ] ifNotNil: [ anInteger max: 0 ]
]

{ #category : 'collecting' }
OTPrometheusMetricReader >> scrapeText [

	^ self encoder encodeSnapshot: self collectSnapshot
]

{ #category : 'accessing' }
OTPrometheusMetricReader >> server [

	^ server
]

{ #category : 'lifecycle' }
OTPrometheusMetricReader >> shutdown [

	| result |
	self stopServer.
	result := super shutdown.
	^ result
]

{ #category : 'private - http' }
OTPrometheusMetricReader >> startServer [

	| bindingAddress newServer |
	self isShutdown ifTrue: [ ^ nil ].
	server ifNotNil: [ ^ server ].
	newServer := ZnServer defaultServerClass on: self port.
	newServer delegate: self.
	bindingAddress := self bindingAddressForHost.
	bindingAddress ifNotNil: [ newServer bindingAddress: bindingAddress ].
	newServer start.
	server := newServer.
	port := newServer port.
	^ server
]

{ #category : 'private - http' }
OTPrometheusMetricReader >> stopServer [

	server ifNotNil: [
		server stop.
		server := nil ].
	^ nil
]
