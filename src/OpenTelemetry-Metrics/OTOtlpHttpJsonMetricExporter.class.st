"
An OTLP metrics exporter that sends JSON-encoded ExportMetricsServiceRequest payloads over HTTP.
"
Class {
	#name : 'OTOtlpHttpJsonMetricExporter',
	#superclass : 'OTMetricExporter',
	#instVars : [
		'configuration',
		'encoder',
		'httpClient',
		'maxExportAttempts',
		'warningSink',
		'sleepStrategy',
		'retryJitterBlock'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTOtlpHttpJsonMetricExporter class >> configuration: anOtlpConfiguration [

	^ self new
		  configuration: anOtlpConfiguration;
		  aggregationSelector: self configuredAggregationSelector;
		  temporalitySelector: self configuredTemporalitySelector;
		  yourself
]

{ #category : 'private - configuration' }
OTOtlpHttpJsonMetricExporter class >> configuredAggregationPreference [

	| rawValue |
	rawValue := OTOtlpExporterConfiguration environmentValueAt: 'OTEL_EXPORTER_OTLP_METRICS_DEFAULT_HISTOGRAM_AGGREGATION'.
	rawValue ifNil: [ ^ #explicitBucketHistogram ].
	rawValue := rawValue asLowercase.
	rawValue = 'explicit_bucket_histogram' ifTrue: [ ^ #explicitBucketHistogram ].
	rawValue = 'base2_exponential_bucket_histogram' ifTrue: [ ^ #base2ExponentialBucketHistogram ].
	self noteInvalidHistogramAggregationPreference: rawValue.
	^ #explicitBucketHistogram
]

{ #category : 'private - configuration' }
OTOtlpHttpJsonMetricExporter class >> configuredAggregationSelector [

	| preference |
	preference := self configuredAggregationPreference.
	^ [ :instrument | instrument aggregationForPreference: preference ]
]

{ #category : 'private - configuration' }
OTOtlpHttpJsonMetricExporter class >> configuredTemporalityPreference [

	| rawValue |
	rawValue := OTOtlpExporterConfiguration environmentValueAt: 'OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE'.
	rawValue ifNil: [ ^ #cumulative ].
	rawValue := rawValue asLowercase.
	rawValue = 'cumulative' ifTrue: [ ^ #cumulative ].
	rawValue = 'delta' ifTrue: [ ^ #delta ].
	rawValue = 'lowmemory' ifTrue: [ ^ #lowMemory ].
	self noteInvalidTemporalityPreference: rawValue.
	^ #cumulative
]

{ #category : 'private - configuration' }
OTOtlpHttpJsonMetricExporter class >> configuredTemporalitySelector [

	| preference |
	preference := self configuredTemporalityPreference.
	^ [ :instrument | instrument otlpTemporalityForPreference: preference ]
]

{ #category : 'private - retry' }
OTOtlpHttpJsonMetricExporter class >> defaultRetryBaseDelayMillis [

	^ OTOtlpHttpJsonExportSupport defaultRetryBaseDelayMillis
]

{ #category : 'private - retry' }
OTOtlpHttpJsonMetricExporter class >> defaultRetryMaxDelayMillis [

	^ OTOtlpHttpJsonExportSupport defaultRetryMaxDelayMillis
]

{ #category : 'private - logging' }
OTOtlpHttpJsonMetricExporter class >> defaultWarningSink [

	^ OTOtlpHttpJsonExportSupport defaultWarningSink
]

{ #category : 'private - retry' }
OTOtlpHttpJsonMetricExporter class >> maxExportAttempts [

	^ OTOtlpHttpJsonExportSupport maxExportAttempts
]

{ #category : 'private - logging' }
OTOtlpHttpJsonMetricExporter class >> noteInvalidConfigurationPreference: aString message: aMessage [

	OTMeterProvider configurationWarningSink value: aMessage , aString printString
]

{ #category : 'private - logging' }
OTOtlpHttpJsonMetricExporter class >> noteInvalidHistogramAggregationPreference: aString [

	self
		noteInvalidConfigurationPreference: aString
		message: 'OpenTelemetry OTLP metrics default histogram aggregation was invalid and has been ignored: '
]

{ #category : 'private - logging' }
OTOtlpHttpJsonMetricExporter class >> noteInvalidTemporalityPreference: aString [

	self
		noteInvalidConfigurationPreference: aString
		message: 'OpenTelemetry OTLP metrics temporality preference was invalid and has been ignored: '
]

{ #category : 'private - retry' }
OTOtlpHttpJsonMetricExporter class >> retryableStatusCodes [

	^ OTOtlpHttpJsonExportSupport retryableStatusCodes
]

{ #category : 'accessing' }
OTOtlpHttpJsonMetricExporter class >> supportedProtocol [

	^ OTOtlpHttpJsonExportSupport supportedProtocol
]

{ #category : 'private - logging' }
OTOtlpHttpJsonMetricExporter class >> warningSink [

	^ OTOtlpHttpJsonExportSupport warningSinkFor: self
]

{ #category : 'private - logging' }
OTOtlpHttpJsonMetricExporter class >> warningSink: aBlock [

	^ OTOtlpHttpJsonExportSupport warningSink: aBlock for: self
]

{ #category : 'private - configuration' }
OTOtlpHttpJsonMetricExporter >> applyConfigurationToHttpClient [

	| client timeoutMillis |
	client := self httpClient.
	client
		url: self configuration endpoint;
		method: #POST.
	timeoutMillis := self configuredRequestTimeoutMillisOrNil.
	timeoutMillis ifNotNil: [ client timeout: timeoutMillis ].
	self configuration headers associationsDo: [ :each | client headerAt: each key put: each value ].
	(self hasUserAgentHeaderConfigured: self configuration headers) ifFalse: [
		client headerAt: 'User-Agent' put: self configuration userAgent ].
	client
		headerAt: 'Content-Type' put: 'application/json';
		headerAt: 'Accept-Encoding' put: 'gzip'
]

{ #category : 'accessing' }
OTOtlpHttpJsonMetricExporter >> configuration [

	^ configuration ifNil: [ configuration := OTOtlpExporterConfiguration forSignalNamed: 'METRICS' ]
]

{ #category : 'accessing' }
OTOtlpHttpJsonMetricExporter >> configuration: anOtlpConfiguration [

	configuration := anOtlpConfiguration
]

{ #category : 'private - configuration' }
OTOtlpHttpJsonMetricExporter >> configuredRequestTimeoutMillisOrNil [

	^ self configuration timeoutMillis
]

{ #category : 'private - decoding' }
OTOtlpHttpJsonMetricExporter >> decodedResponseContentsFrom: aResponse [

	^ self httpJsonExportSupport decodedResponseContentsFrom: aResponse
]

{ #category : 'private - encoding' }
OTOtlpHttpJsonMetricExporter >> defaultEncoderClass [

	^ OTOtlpJsonMetricEncoder
]

{ #category : 'private - encoding' }
OTOtlpHttpJsonMetricExporter >> encodedPayloadFrom: anOTMetricSnapshot [

	^ self encoder encodeSnapshot: anOTMetricSnapshot
]

{ #category : 'accessing' }
OTOtlpHttpJsonMetricExporter >> encoder [

	^ encoder ifNil: [ encoder := self defaultEncoderClass new ]
]

{ #category : 'accessing' }
OTOtlpHttpJsonMetricExporter >> encoder: anEncoder [

	encoder := anEncoder
]

{ #category : 'private - encoding' }
OTOtlpHttpJsonMetricExporter >> entityForPayload: aString [

	| entity |
	entity := self configuration usesGzipCompression
		          ifTrue: [ ZnEntity bytes: (self gzipCompressedBytesFor: aString) ]
		          ifFalse: [ ZnEntity with: aString type: ZnMimeType applicationJson ].
	entity contentType: ZnMimeType applicationJson.
	^ entity
]

{ #category : 'private - configuration' }
OTOtlpHttpJsonMetricExporter >> executeHttpRequestForPayloadString: payloadString usingSupport: anOtlpHttpJsonExportSupport [

	anOtlpHttpJsonExportSupport configureHttpClientForPayloadString: payloadString.
	^ self httpClient
		  execute;
		  response
]

{ #category : 'exporting' }
OTOtlpHttpJsonMetricExporter >> export: anOTMetricSnapshot [

	| payloadString |
	^ self withSynchronizedExportDo: [
			  self isStopping ifTrue: [ ^ false ].
			  payloadString := [ self payloadStringFrom: anOTMetricSnapshot ]
				                   on: Error
				                   do: [ ^ false ].
			  self exportAttemptNumber: 1 payloadString: payloadString ]
]

{ #category : 'exporting' }
OTOtlpHttpJsonMetricExporter >> exportAttemptNumber: attemptNumber payloadString: payloadString [

	^ self httpJsonExportSupport exportAttemptNumber: attemptNumber payloadString: payloadString
]

{ #category : 'private - encoding' }
OTOtlpHttpJsonMetricExporter >> gzipCompressedBytesFor: aString [

	^ self httpJsonExportSupport gzipCompressedBytesFor: aString
]

{ #category : 'private - success handling' }
OTOtlpHttpJsonMetricExporter >> handleSuccessResponse: aResponse [

	^ self httpJsonExportSupport handleSuccessResponse: aResponse
]

{ #category : 'testing' }
OTOtlpHttpJsonMetricExporter >> hasUserAgentHeaderConfigured: aDictionary [

	^ self httpJsonExportSupport hasUserAgentHeaderConfigured: aDictionary
]

{ #category : 'accessing' }
OTOtlpHttpJsonMetricExporter >> httpClient [

	^ httpClient ifNil: [ httpClient := ZnClient new ]
]

{ #category : 'accessing' }
OTOtlpHttpJsonMetricExporter >> httpClient: anHttpClient [

	httpClient := anHttpClient
]

{ #category : 'private - support' }
OTOtlpHttpJsonMetricExporter >> httpJsonExportSupport [

	^ OTOtlpHttpJsonExportSupport for: self
]

{ #category : 'private - retry' }
OTOtlpHttpJsonMetricExporter >> isRetryableStatusCode: anInteger [

	^ self class retryableStatusCodes includes: anInteger
]

{ #category : 'private - retry' }
OTOtlpHttpJsonMetricExporter >> maxExportAttempts [

	^ maxExportAttempts ifNil: [ self class maxExportAttempts ]
]

{ #category : 'private - retry' }
OTOtlpHttpJsonMetricExporter >> maxExportAttempts: anInteger [

	maxExportAttempts := anInteger.
	^ self maxExportAttempts
]

{ #category : 'private - logging' }
OTOtlpHttpJsonMetricExporter >> nonNegativeIntegerFrom: anObject default: aDefaultValue [

	^ self httpJsonExportSupport nonNegativeIntegerFrom: anObject default: aDefaultValue
]

{ #category : 'private - encoding' }
OTOtlpHttpJsonMetricExporter >> normalizedPayloadForEncoding: anOTMetricSnapshot [

	^ anOTMetricSnapshot
]

{ #category : 'private - logging' }
OTOtlpHttpJsonMetricExporter >> noteInvalidSuccessResponse: anError [

	^ self httpJsonExportSupport noteInvalidSuccessResponse: anError
]

{ #category : 'private - logging' }
OTOtlpHttpJsonMetricExporter >> notePartialSuccess: aDictionary [

	^ self httpJsonExportSupport notePartialSuccess: aDictionary
]

{ #category : 'private - logging' }
OTOtlpHttpJsonMetricExporter >> noteRetryExhaustedForError: anError [

	^ self httpJsonExportSupport noteRetryExhaustedForError: anError
]

{ #category : 'private - logging' }
OTOtlpHttpJsonMetricExporter >> noteRetryExhaustedForResponse: aResponse [

	^ self httpJsonExportSupport noteRetryExhaustedForResponse: aResponse
]

{ #category : 'private - logging' }
OTOtlpHttpJsonMetricExporter >> otlpSignalName [

	^ 'metric'
]

{ #category : 'private - retry' }
OTOtlpHttpJsonMetricExporter >> parseRetryAfterMillisFrom: aValue [

	^ self httpJsonExportSupport parseRetryAfterMillisFrom: aValue
]

{ #category : 'private - success handling' }
OTOtlpHttpJsonMetricExporter >> partialSuccessFrom: aDictionary [

	| partialSuccess |
	partialSuccess := aDictionary at: 'partialSuccess' ifAbsent: [ aDictionary at: 'partial_success' ifAbsent: [ nil ] ].
	partialSuccess ifNil: [ ^ nil ].
	((self rejectedCountFromPartialSuccess: partialSuccess) <= 0 and: [
		 (partialSuccess at: 'errorMessage' ifAbsent: [ partialSuccess at: 'error_message' ifAbsent: [ '' ] ]) asString trimBoth isEmpty ])
		ifTrue: [ ^ nil ].
	^ partialSuccess
]

{ #category : 'private - encoding' }
OTOtlpHttpJsonMetricExporter >> payloadStringFrom: anObject [

	^ self httpJsonExportSupport payloadStringFrom: anObject
]

{ #category : 'private - success handling' }
OTOtlpHttpJsonMetricExporter >> rejectedCountFromPartialSuccess: aDictionary [

	^ self
		  nonNegativeIntegerFrom:
		  (aDictionary at: 'rejectedDataPoints' ifAbsent: [ aDictionary at: 'rejected_data_points' ifAbsent: [ 0 ] ])
		  default: 0
]

{ #category : 'private - configuration' }
OTOtlpHttpJsonMetricExporter >> removeRequestHeaderNamed: aString [

	self httpClient removeHeaderNamed: aString
]

{ #category : 'private - retry' }
OTOtlpHttpJsonMetricExporter >> responseCodeFrom: aResponse [

	^ self httpJsonExportSupport responseCodeFrom: aResponse
]

{ #category : 'private - decoding' }
OTOtlpHttpJsonMetricExporter >> responseContentsFrom: aResponse [

	^ self httpJsonExportSupport responseContentsFrom: aResponse
]

{ #category : 'private - decoding' }
OTOtlpHttpJsonMetricExporter >> responseHeaderAt: aString in: aResponse ifAbsent: aBlock [

	^ self httpJsonExportSupport responseHeaderAt: aString in: aResponse ifAbsent: aBlock
]

{ #category : 'private - retry' }
OTOtlpHttpJsonMetricExporter >> retryAfterMillisFromResponse: aResponse [

	^ self httpJsonExportSupport retryAfterMillisFromResponse: aResponse
]

{ #category : 'private - retry' }
OTOtlpHttpJsonMetricExporter >> retryDelayMillisForAttempt: attemptNumber response: aResponse [

	^ self httpJsonExportSupport retryDelayMillisForAttempt: attemptNumber response: aResponse
]

{ #category : 'private - retry' }
OTOtlpHttpJsonMetricExporter >> retryJitterBlock [

	^ retryJitterBlock ifNil: [
			  retryJitterBlock := [ :delayMillis |
				                      | multiplier |
				                      multiplier := 0.8 + (Random new next * 0.4).
				                      (delayMillis asFloat * multiplier) rounded max: 1 ] ]
]

{ #category : 'private - retry' }
OTOtlpHttpJsonMetricExporter >> retryJitterBlock: aBlock [

	retryJitterBlock := aBlock.
	^ self retryJitterBlock
]

{ #category : 'private - retry' }
OTOtlpHttpJsonMetricExporter >> sleepForMilliseconds: anInteger [

	self sleepStrategy value: anInteger
]

{ #category : 'private - retry' }
OTOtlpHttpJsonMetricExporter >> sleepStrategy [

	^ sleepStrategy ifNil: [ sleepStrategy := [ :delayMillis | (Delay forMilliseconds: delayMillis) wait ] ]
]

{ #category : 'private - retry' }
OTOtlpHttpJsonMetricExporter >> sleepStrategy: aBlock [

	sleepStrategy := aBlock.
	^ self sleepStrategy
]

{ #category : 'private - logging' }
OTOtlpHttpJsonMetricExporter >> strictPositiveIntegerFrom: aString [

	| stream value |
	stream := aString trimBoth readStream.
	stream atEnd ifTrue: [ ^ nil ].
	value := [ Integer readFrom: stream ]
		         on: Error
		         do: [ ^ nil ].
	stream atEnd ifFalse: [ ^ nil ].
	value > 0 ifFalse: [ ^ nil ].
	^ value
]

{ #category : 'private - success handling' }
OTOtlpHttpJsonMetricExporter >> successfulResponseRepresentationFrom: aResponse [

	| contents text |
	contents := self decodedResponseContentsFrom: aResponse.
	contents ifNil: [ Error signal: 'Missing OTLP success response body' ].
	text := contents asString trimBoth.
	text isEmpty ifTrue: [ Error signal: 'Missing OTLP success response body' ].
	^ STONJSON fromString: text
]

{ #category : 'private - logging' }
OTOtlpHttpJsonMetricExporter >> warningSink [

	^ warningSink ifNil: [ self class warningSink ]
]

{ #category : 'private - logging' }
OTOtlpHttpJsonMetricExporter >> warningSink: aBlock [

	warningSink := aBlock.
	^ self warningSink
]
