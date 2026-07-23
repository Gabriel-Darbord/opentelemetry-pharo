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

	host ifNil: [ ^ #[ 127 0 0 1 ] ].
	(host sameAs: 'localhost') ifTrue: [ ^ #[ 127 0 0 1 ] ].
	host = '0.0.0.0' ifTrue: [ ^ nil ].
	^ [ NetNameResolver addressForName: host timeout: 5 ]
		  on: NameLookupFailure
		  do: [ #[ 127 0 0 1 ] ]
]

{ #category : 'collecting' }
OTPrometheusMetricReader >> collect [

	^ self collectSnapshot
]

{ #category : 'private - http' }
OTPrometheusMetricReader >> contentTypeString [

	^ self contentTypeStringForFormat: #prometheusText004
]

{ #category : 'private - http' }
OTPrometheusMetricReader >> contentTypeStringForFormat: aFormatSymbol [

	aFormatSymbol = #openMetricsText100 ifTrue: [
		^ 'application/openmetrics-text; version=1.0.0; charset=utf-8; escaping=underscores' ].
	aFormatSymbol = #prometheusText100 ifTrue: [ ^ 'text/plain; version=1.0.0; charset=utf-8; escaping=underscores' ].
	^ 'text/plain; version=0.0.4; charset=utf-8'
]

{ #category : 'private - http' }
OTPrometheusMetricReader >> defaultResponseFormat [

	^ #prometheusText004
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

	(aZnRequest method = #GET and: [ aZnRequest uri pathPrintString = self path ]) ifTrue: [
		^ self metricsResponseForFormat: (self responseFormatForAcceptHeader: aZnRequest accept) ].
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

	^ self metricsResponseForFormat: self defaultResponseFormat
]

{ #category : 'private - http' }
OTPrometheusMetricReader >> metricsResponseForFormat: aFormatSymbol [

	| entity response |
	entity := ZnEntity text: (self scrapeTextForFormat: aFormatSymbol).
	response := ZnResponse ok: entity.
	response setContentType: (self contentTypeStringForFormat: aFormatSymbol).
	^ response
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

{ #category : 'private - http' }
OTPrometheusMetricReader >> responseFormatForAcceptHeader: aString [

	| bestFormat bestOrder bestWeight |
	bestFormat := self defaultResponseFormat.
	bestWeight := -1.
	bestOrder := Float infinity.
	(self supportedResponseFormatsForAcceptHeader: aString) do: [ :each |
			(each third > bestWeight or: [ each third = bestWeight and: [ each second < bestOrder ] ]) ifTrue: [
					bestFormat := each first.
					bestOrder := each second.
					bestWeight := each third ] ].
	^ bestFormat
]

{ #category : 'collecting' }
OTPrometheusMetricReader >> scrapeText [

	^ self scrapeTextForFormat: self defaultResponseFormat
]

{ #category : 'collecting' }
OTPrometheusMetricReader >> scrapeTextForFormat: aFormatSymbol [

	^ self encoder encodeSnapshot: self collectSnapshot format: aFormatSymbol
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

{ #category : 'private - http' }
OTPrometheusMetricReader >> supportedResponseFormatsForAcceptHeader: aString [

	| acceptedFormats formats results |
	acceptedFormats := self supportedResponseFormatsFromHeader: aString.
	formats := OrderedCollection new
		           add: #openMetricsText100 -> ('application/openmetrics-text' -> '1.0.0');
		           add: #prometheusText100 -> ('text/plain' -> '1.0.0');
		           add: #prometheusText004 -> ('text/plain' -> '0.0.4');
		           yourself.
	results := OrderedCollection new.
	acceptedFormats do: [ :eachHeader |
			| headerMime headerOrder headerVersion headerWeight |
			headerMime := eachHeader at: #mime.
			headerVersion := eachHeader at: #version ifAbsent: [ nil ].
			headerWeight := eachHeader at: #q.
			headerOrder := eachHeader at: #order.
			formats do: [ :eachFormat |
					| formatMime formatVersion |
					formatMime := eachFormat value key.
					formatVersion := eachFormat value value.
					(headerMime = '*/*' or: [ headerMime = formatMime and: [ headerVersion = formatVersion ] ]) ifTrue: [
							results add: {
									eachFormat key.
									headerOrder.
									headerWeight } ] ] ].
	^ results
]

{ #category : 'private - http' }
OTPrometheusMetricReader >> supportedResponseFormatsFromHeader: aString [

	| header |
	header := aString ifNil: [ '*/*' ] ifNotNil: [ aString trimBoth ].
	header isEmpty ifTrue: [ header := '*/*' ].
	^ OrderedCollection streamContents: [ :stream |
			  (header substrings: ',') doWithIndex: [ :each :index |
					  | mime parameters |
					  parameters := each substrings: ';'.
					  mime := parameters first trimBoth asLowercase.
					  stream nextPut: (Dictionary new
							   at: #mime put: mime;
							   at: #order put: index;
							   at: #q put: (self weightFromAcceptParameters: parameters);
							   at: #version put: (self valueForAcceptParameterNamed: 'version' in: parameters);
							   yourself) ] ]
]

{ #category : 'private - http' }
OTPrometheusMetricReader >> valueForAcceptParameterNamed: aName in: someParameters [

	someParameters allButFirstDo: [ :each |
			| keyValue |
			keyValue := each substrings: '='.
			(keyValue size = 2 and: [ keyValue first trimBoth asLowercase = aName ]) ifTrue: [ ^ keyValue second trimBoth asLowercase ] ].
	^ nil
]

{ #category : 'private - http' }
OTPrometheusMetricReader >> weightFromAcceptParameters: someParameters [

	| value |
	value := self valueForAcceptParameterNamed: 'q' in: someParameters.
	value ifNil: [ ^ 1.0 ].
	^ [ Number readFrom: value readStream ]
		  on: Error
		  do: [ 0.0 ]
]
