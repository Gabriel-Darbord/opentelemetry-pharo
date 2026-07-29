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

{ #category : 'private - configuration' }
OTPrometheusMetricReader class >> aggregationPreferenceNamed: aString ifAbsent: aBlock [

	| normalized |
	normalized := aString ifNil: [ '' ] ifNotNil: [ aString asString trimBoth asLowercase ].
	normalized = 'explicit_bucket_histogram' ifTrue: [ ^ #explicitBucketHistogram ].
	normalized = 'base2_exponential_bucket_histogram' ifTrue: [ ^ #base2ExponentialBucketHistogram ].
	^ aBlock value
]

{ #category : 'private - configuration' }
OTPrometheusMetricReader class >> aggregationSelectorForPreference: aSymbol [

	^ [ :instrument | instrument aggregationForPreference: aSymbol ]
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
OTPrometheusMetricReader >> contentTypeStringForResponseFormat: aDictionary [

	| escaping format |
	format := aDictionary at: #format.
	escaping := aDictionary at: #escaping ifAbsent: [ #underscores ].
	format = #openMetricsText100 ifTrue: [
		^ 'application/openmetrics-text; version=1.0.0; charset=utf-8; escaping=' , (self prometheusEscapingHeaderValueFor: escaping) ].
	format = #prometheusText100 ifTrue: [
		^ 'text/plain; version=1.0.0; charset=utf-8; escaping=' , (self prometheusEscapingHeaderValueFor: escaping) ].
	^ 'text/plain; version=0.0.4; charset=utf-8'
]

{ #category : 'private - http' }
OTPrometheusMetricReader >> defaultEscapingModeForFormat: aFormatSymbol [

	aFormatSymbol = #prometheusText004 ifTrue: [ ^ #underscores ].
	^ #underscores
]

{ #category : 'private - http' }
OTPrometheusMetricReader >> defaultResponseFormat [

	^ #prometheusText004
]

{ #category : 'private - http' }
OTPrometheusMetricReader >> defaultResponseFormatDescriptor [

	^ self responseFormatDescriptorFor: self defaultResponseFormat
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
						targetInfoEnabled: currentEncoder targetInfoEnabled;
						translationStrategy: currentEncoder translationStrategy ].
			encoder := anOTPrometheusTextEncoder ]
]

{ #category : 'private - http' }
OTPrometheusMetricReader >> escapingModeFromAcceptParameters: someParameters [

	| value |
	value := self valueForAcceptParameterNamed: 'escaping' in: someParameters.
	value = 'allow-utf-8' ifTrue: [ ^ #allowUtf8 ].
	value = 'underscores' ifTrue: [ ^ #underscores ].
	^ nil
]

{ #category : 'private - http' }
OTPrometheusMetricReader >> handleRequest: aZnRequest [

	(aZnRequest method = #GET and: [ aZnRequest uri pathPrintString = self path ]) ifTrue: [
		^ self metricsResponseForResponseFormat: (self responseFormatDescriptorForAcceptHeader: aZnRequest accept) ].
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
OTPrometheusMetricReader >> metricsResponseForResponseFormat: aDictionary [

	| entity response |
	entity := ZnEntity text: (self scrapeTextForResponseFormat: aDictionary).
	response := ZnResponse ok: entity.
	response setContentType: (self contentTypeStringForResponseFormat: aDictionary).
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
OTPrometheusMetricReader >> prometheusEscapingHeaderValueFor: aSymbol [

	aSymbol = #allowUtf8 ifTrue: [ ^ 'allow-utf-8' ].
	^ 'underscores'
]

{ #category : 'accessing' }
OTPrometheusMetricReader >> resourceConstantLabels [

	^ stateLock critical: [
			  encoder ifNil: [ encoder := OTPrometheusTextEncoder new ].
			  encoder resourceConstantLabels ]
]

{ #category : 'accessing' }
OTPrometheusMetricReader >> resourceConstantLabels: anOTMetricAttributeFilterOrNil [

	stateLock critical: [
			self ensureOpenLocked.
			(encoder ifNil: [ encoder := OTPrometheusTextEncoder new ]) resourceConstantLabels: anOTMetricAttributeFilterOrNil ]
]

{ #category : 'private - http' }
OTPrometheusMetricReader >> responseFormatDescriptorFor: aFormatSymbol [

	^ Dictionary new
		  at: #format put: aFormatSymbol;
		  at: #escaping put: (self defaultEscapingModeForFormat: aFormatSymbol);
		  yourself
]

{ #category : 'private - http' }
OTPrometheusMetricReader >> responseFormatDescriptorFor: aFormatSymbol escaping: aSymbol [

	^ Dictionary new
		  at: #format put: aFormatSymbol;
		  at: #escaping put: aSymbol;
		  yourself
]

{ #category : 'private - http' }
OTPrometheusMetricReader >> responseFormatDescriptorForAcceptHeader: aString [

	| bestFormat bestOrder bestWeight |
	bestFormat := self defaultResponseFormatDescriptor.
	bestWeight := -1.
	bestOrder := Float infinity.
	(self supportedResponseFormatsForAcceptHeader: aString) do: [ :each |
			(each third > bestWeight or: [ each third = bestWeight and: [ each second < bestOrder ] ]) ifTrue: [
					bestFormat := each first.
					bestOrder := each second.
					bestWeight := each third ] ].
	^ bestFormat
]

{ #category : 'private - http' }
OTPrometheusMetricReader >> responseFormatForAcceptHeader: aString [

	^ (self responseFormatDescriptorForAcceptHeader: aString) at: #format
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

{ #category : 'private - http' }
OTPrometheusMetricReader >> scrapeEncoder [

	| configuredEncoder template |
	template := self encoder.
	configuredEncoder := OTPrometheusTextEncoder new.
	configuredEncoder
		resourceConstantLabels: template resourceConstantLabels;
		scopeInfoEnabled: template scopeInfoEnabled;
		targetInfoEnabled: template targetInfoEnabled;
		translationStrategy: template translationStrategy;
		warningSink: template warningSink.
	^ configuredEncoder
]

{ #category : 'collecting' }
OTPrometheusMetricReader >> scrapeTextForResponseFormat: aDictionary [

	| configuredEncoder |
	configuredEncoder := self scrapeEncoder.
	configuredEncoder escapingMode: (aDictionary at: #escaping ifAbsent: [ nil ]).
	^ configuredEncoder encodeSnapshot: self collectSnapshot format: (aDictionary at: #format)
]

{ #category : 'accessing' }
OTPrometheusMetricReader >> server [

	^ stateLock critical: [ server ]
]

{ #category : 'lifecycle' }
OTPrometheusMetricReader >> shutdown [

	self beginShutdown ifFalse: [ ^ false ].
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
				            (host ifNil: [ 'localhost' ]).
				            (port ifNil: [ 9464 ]) } ].
	hostValue := snapshot first.
	portValue := snapshot second.
	newServer := ZnServer defaultServerClass on: portValue.
	newServer delegate: self.
	bindingAddress := self bindingAddressForHost: hostValue.
	bindingAddress ifNotNil: [ newServer bindingAddress: bindingAddress ].
	newServer start.
	runningServer := stateLock critical: [
			                 shutdownRequested
				                 ifTrue: [ nil ]
				                 ifFalse: [
						                 server
							                 ifNil: [
									                 server := newServer.
									                 port := newServer port.
									                 server ]
							                 ifNotNil: [ server ] ] ].
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
		           add: #openMetricsText100 -> ('application/openmetrics-text' -> '1.0.0') -> #( #underscores #allowUtf8 );
		           add: #prometheusText100 -> ('text/plain' -> '1.0.0') -> #( #underscores #allowUtf8 );
		           add: #prometheusText004 -> ('text/plain' -> '0.0.4') -> #( #underscores );
		           yourself.
	results := OrderedCollection new.
	acceptedFormats do: [ :eachHeader |
			| headerEscaping headerMime headerOrder headerVersion headerWeight |
			headerMime := eachHeader at: #mime.
			headerVersion := eachHeader at: #version ifAbsent: [ nil ].
			headerEscaping := eachHeader at: #escaping ifAbsent: [ nil ].
			headerWeight := eachHeader at: #q.
			headerOrder := eachHeader at: #order.
			formats do: [ :eachFormat |
					| descriptor formatEscapings formatMime formatVersion |
					descriptor := eachFormat key.
					formatEscapings := eachFormat value.
					formatMime := descriptor value key.
					formatVersion := descriptor value value.
					(headerMime = '*/*' or: [ headerMime = formatMime and: [ headerVersion = formatVersion ] ]) ifTrue: [
							(headerEscaping isNil or: [ formatEscapings includes: headerEscaping ]) ifTrue: [
									results add: {
											(self
												 responseFormatDescriptorFor: descriptor key
												 escaping: (headerEscaping ifNil: [ self defaultEscapingModeForFormat: descriptor key ])).
											headerOrder.
											headerWeight } ] ] ] ].
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
							   at: #escaping put: (self escapingModeFromAcceptParameters: parameters);
							   at: #version put: (self valueForAcceptParameterNamed: 'version' in: parameters);
							   yourself) ] ]
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

{ #category : 'accessing' }
OTPrometheusMetricReader >> translationStrategy [

	^ stateLock critical: [ (encoder ifNil: [ encoder := OTPrometheusTextEncoder new ]) translationStrategy ]
]

{ #category : 'accessing' }
OTPrometheusMetricReader >> translationStrategy: aSymbol [

	stateLock critical: [
			self ensureOpenLocked.
			(encoder ifNil: [ encoder := OTPrometheusTextEncoder new ]) translationStrategy: aSymbol ]
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
