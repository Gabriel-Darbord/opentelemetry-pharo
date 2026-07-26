"
I expose collected metrics through a small Prometheus scraping endpoint.
I use OTPrometheusTextEncoder to serve snapshots in Prometheus text formats.
"
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

	^ self bindingAddressForHost: self host
]

{ #category : 'private - http' }
OTPrometheusMetricReader >> bindingAddressForHost: aHostString [

	aHostString ifNil: [ ^ #[ 127 0 0 1 ] ].
	(aHostString sameAs: 'localhost') ifTrue: [ ^ #[ 127 0 0 1 ] ].
	aHostString = '0.0.0.0' ifTrue: [ ^ nil ].
	^ [ NetNameResolver addressForName: aHostString timeout: 5 ]
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

	^ stateLock critical: [ encoder ifNil: [ encoder := OTPrometheusTextEncoder new ] ]
]

{ #category : 'accessing' }
OTPrometheusMetricReader >> encoder: anOTPrometheusTextEncoder [

	stateLock critical: [
		| currentEncoder |
		self ensureOpenLocked.
		currentEncoder := encoder.
		currentEncoder ifNotNil: [
			anOTPrometheusTextEncoder
				resourceConstantLabels: currentEncoder resourceConstantLabels;
				scopeInfoEnabled: currentEncoder scopeInfoEnabled;
				targetInfoEnabled: currentEncoder targetInfoEnabled ].
		encoder := anOTPrometheusTextEncoder ]
]

{ #category : 'private - http' }
OTPrometheusMetricReader >> handleRequest: aZnRequest [

	(aZnRequest method = #GET and: [ aZnRequest uri pathPrintString = self path ]) ifTrue: [
		^ self metricsResponseForFormat: (self responseFormatForAcceptHeader: aZnRequest accept) ].
	^ ZnResponse notFound: aZnRequest uri
]

{ #category : 'accessing' }
OTPrometheusMetricReader >> host [

	^ stateLock critical: [ host ifNil: [ 'localhost' ] ]
]

{ #category : 'accessing' }
OTPrometheusMetricReader >> host: aString [

	stateLock critical: [
		self ensureOpenLocked.
		host := aString ifNil: [ 'localhost' ] ifNotNil: [ aString asString ] ]
]

{ #category : 'initialization' }
OTPrometheusMetricReader >> initialize [

	super initialize.
	host := 'localhost'.
	port := 9464.
	path := '/metrics'.
	encoder := OTPrometheusTextEncoder new
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

	^ stateLock critical: [ path ifNil: [ '/metrics' ] ]
]

{ #category : 'accessing' }
OTPrometheusMetricReader >> path: aString [

	| normalized |
	normalized := aString ifNil: [ '/metrics' ] ifNotNil: [ aString asString ].
	stateLock critical: [
		self ensureOpenLocked.
		path := normalized isEmpty
			        ifTrue: [ '/metrics' ]
			        ifFalse: [
					        normalized first = $/
						        ifTrue: [ normalized ]
						        ifFalse: [ '/' , normalized ] ] ]
]

{ #category : 'accessing' }
OTPrometheusMetricReader >> resourceConstantLabels [

	^ stateLock critical: [ encoder ifNil: [ encoder := OTPrometheusTextEncoder new ]. encoder resourceConstantLabels ]
]

{ #category : 'accessing' }
OTPrometheusMetricReader >> resourceConstantLabels: anOTMetricAttributeFilterOrNil [

	stateLock critical: [
		self ensureOpenLocked.
		(encoder ifNil: [ encoder := OTPrometheusTextEncoder new ])
			resourceConstantLabels: anOTMetricAttributeFilterOrNil ]
]

{ #category : 'accessing' }
OTPrometheusMetricReader >> scopeInfoEnabled [

	^ stateLock critical: [ (encoder ifNil: [ encoder := OTPrometheusTextEncoder new ]) scopeInfoEnabled ]
]

{ #category : 'accessing' }
OTPrometheusMetricReader >> scopeInfoEnabled: aBoolean [

	stateLock critical: [
		self ensureOpenLocked.
		(encoder ifNil: [ encoder := OTPrometheusTextEncoder new ]) scopeInfoEnabled: aBoolean ]
]

{ #category : 'accessing' }
OTPrometheusMetricReader >> port [

	^ stateLock critical: [ port ifNil: [ 9464 ] ]
]

{ #category : 'accessing' }
OTPrometheusMetricReader >> port: anInteger [

	stateLock critical: [
		self ensureOpenLocked.
		port := anInteger ifNil: [ 9464 ] ifNotNil: [ anInteger max: 0 ] ]
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

	^ self scrapeEncoder encodeSnapshot: self collectSnapshot format: aFormatSymbol
]

{ #category : 'private - http' }
OTPrometheusMetricReader >> scrapeEncoder [

	| configuredEncoder template |
	template := self encoder.
	configuredEncoder := OTPrometheusTextEncoder new.
	configuredEncoder
		resourceConstantLabels: template resourceConstantLabels;
		scopeInfoEnabled: template scopeInfoEnabled;
		targetInfoEnabled: template targetInfoEnabled;
		warningSink: template warningSink.
	^ configuredEncoder
]

{ #category : 'accessing' }
OTPrometheusMetricReader >> server [

	^ stateLock critical: [ server ]
]

{ #category : 'accessing' }
OTPrometheusMetricReader >> targetInfoEnabled [

	^ stateLock critical: [ (encoder ifNil: [ encoder := OTPrometheusTextEncoder new ]) targetInfoEnabled ]
]

{ #category : 'accessing' }
OTPrometheusMetricReader >> targetInfoEnabled: aBoolean [

	stateLock critical: [
		self ensureOpenLocked.
		(encoder ifNil: [ encoder := OTPrometheusTextEncoder new ]) targetInfoEnabled: aBoolean ]
]

{ #category : 'lifecycle' }
OTPrometheusMetricReader >> shutdown [

	(self beginShutdown) ifFalse: [ ^ false ].
	self stopServer.
	self finishShutdown.
	^ true
]

{ #category : 'private - http' }
OTPrometheusMetricReader >> startServer [

	| bindingAddress hostValue newServer portValue runningServer snapshot |
	snapshot := stateLock critical: [
		            (shutdownRequested or: [ shutdown ]) ifTrue: [ ^ nil ].
		            server ifNotNil: [ ^ server ].
		            {
			            host ifNil: [ 'localhost' ].
			            port ifNil: [ 9464 ] } ].
	hostValue := snapshot first.
	portValue := snapshot second.
	newServer := ZnServer defaultServerClass on: portValue.
	newServer delegate: self.
	bindingAddress := self bindingAddressForHost: hostValue.
	bindingAddress ifNotNil: [ newServer bindingAddress: bindingAddress ].
	newServer start.
	runningServer := stateLock critical: [
			                 shutdownRequested ifTrue: [ nil ] ifFalse: [
					                 server ifNil: [
							                 server := newServer.
							                 port := newServer port.
							                 server ] ifNotNil: [ server ] ] ].
	runningServer ifNil: [
			newServer stop.
			^ nil ].
	runningServer == newServer ifTrue: [ ^ runningServer ].
	newServer stop.
	^ runningServer
]

{ #category : 'private - http' }
OTPrometheusMetricReader >> stopServer [

	| runningServer |
	runningServer := stateLock critical: [
			                 | previousServer |
			                 previousServer := server.
			                 server := nil.
			                 previousServer ].
	runningServer ifNotNil: [ runningServer stop ].
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
