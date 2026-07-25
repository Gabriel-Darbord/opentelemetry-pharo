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
	^ [ :instrument | instrument otlpAggregationForPreference: preference ]
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

	^ 1000
]

{ #category : 'private - retry' }
OTOtlpHttpJsonMetricExporter class >> defaultRetryMaxDelayMillis [

	^ 5000
]

{ #category : 'private - logging' }
OTOtlpHttpJsonMetricExporter class >> defaultWarningSink [

	^ OTDiagnosticLogger defaultWarningSink
]

{ #category : 'private - retry' }
OTOtlpHttpJsonMetricExporter class >> maxExportAttempts [

	^ 6
]

{ #category : 'private - logging' }
OTOtlpHttpJsonMetricExporter class >> noteInvalidHistogramAggregationPreference: aString [

	| meterProviderClass warningSink |
	meterProviderClass := self environment at: #OTMeterProvider ifAbsent: [ nil ].
	warningSink := meterProviderClass
		               ifNil: [ OTDiagnosticLogger defaultWarningSink ]
		               ifNotNil: [ meterProviderClass configurationWarningSink ].
	warningSink value:
		'OpenTelemetry OTLP metrics default histogram aggregation was invalid and has been ignored: ' , aString printString
]

{ #category : 'private - logging' }
OTOtlpHttpJsonMetricExporter class >> noteInvalidTemporalityPreference: aString [

	| meterProviderClass warningSink |
	meterProviderClass := self environment at: #OTMeterProvider ifAbsent: [ nil ].
	warningSink := meterProviderClass
		               ifNil: [ OTDiagnosticLogger defaultWarningSink ]
		               ifNotNil: [ meterProviderClass configurationWarningSink ].
	warningSink value: 'OpenTelemetry OTLP metrics temporality preference was invalid and has been ignored: ' , aString printString
]

{ #category : 'private - retry' }
OTOtlpHttpJsonMetricExporter class >> retryableStatusCodes [

	^ #( 429 502 503 504 ) asSet
]

{ #category : 'accessing' }
OTOtlpHttpJsonMetricExporter class >> supportedProtocol [

	^ 'http/json'
]

{ #category : 'private - logging' }
OTOtlpHttpJsonMetricExporter class >> warningSink [

	^ OTClassStateStore valueAt: #otWarningSink forClass: self ifAbsent: [ self defaultWarningSink ]
]

{ #category : 'private - logging' }
OTOtlpHttpJsonMetricExporter class >> warningSink: aBlock [

	OTClassStateStore
		valueAt: #otWarningSink
		forClass: self
		putOrRemoveIfNil: aBlock.
	^ self warningSink
]

{ #category : 'private - configuration' }
OTOtlpHttpJsonMetricExporter >> applyConfigurationToHttpClient [

	| client |
	client := self httpClient.
	client
		url: self configuration endpoint;
		method: #POST;
		timeout: self configuration timeoutMillis.
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

{ #category : 'private - decoding' }
OTOtlpHttpJsonMetricExporter >> decodedResponseContentsFrom: aResponse [

	| contents encoding |
	contents := self responseContentsFrom: aResponse.
	contents ifNil: [ ^ nil ].
	encoding := self responseHeaderAt: 'Content-Encoding' in: aResponse ifAbsent: [ 'identity' ].
	(encoding asString sameAs: 'gzip') ifFalse: [ ^ contents ].
	^ (GZipReadStream on: contents readStream) upToEnd
]

{ #category : 'private - encoding' }
OTOtlpHttpJsonMetricExporter >> defaultEncoderClass [

	^ OTOtlpJsonMetricEncoder
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

{ #category : 'exporting' }
OTOtlpHttpJsonMetricExporter >> export: anOTMetricSnapshot [

	self isShutdown ifTrue: [ ^ false ].
	^ self exportAttemptNumber: 1 payloadString: (self payloadStringFrom: anOTMetricSnapshot)
]

{ #category : 'exporting' }
OTOtlpHttpJsonMetricExporter >> exportAttemptNumber: attemptNumber payloadString: payloadString [

	| response responseCode |
	[
		self applyConfigurationToHttpClient.
		self httpClient entity: (self entityForPayload: payloadString).
		self configuration usesGzipCompression
			ifTrue: [ self httpClient headerAt: 'Content-Encoding' put: 'gzip' ]
			ifFalse: [ self removeRequestHeaderNamed: 'Content-Encoding' ].
		response := self httpClient
			            execute;
			            response ]
		on: Error
		do: [ :error |
				attemptNumber >= self maxExportAttempts ifTrue: [
						self noteRetryExhaustedForError: error.
						^ false ].
				self sleepForMilliseconds: (self retryDelayMillisForAttempt: attemptNumber response: nil).
				^ self exportAttemptNumber: attemptNumber + 1 payloadString: payloadString ].
	responseCode := self responseCodeFrom: response.
	responseCode = 200 ifTrue: [ ^ self handleSuccessResponse: response ].
	(self isRetryableStatusCode: responseCode) ifFalse: [ ^ false ].
	attemptNumber >= self maxExportAttempts ifTrue: [
			self noteRetryExhaustedForResponse: response.
			^ false ].
	self sleepForMilliseconds: (self retryDelayMillisForAttempt: attemptNumber response: response).
	^ self exportAttemptNumber: attemptNumber + 1 payloadString: payloadString
]

{ #category : 'private - encoding' }
OTOtlpHttpJsonMetricExporter >> gzipCompressedBytesFor: aString [

	^ ByteArray streamContents: [ :stream |
			  | zipper |
			  zipper := GZipWriteStream on: stream.
			  zipper nextPutAll: aString utf8Encoded.
			  zipper close ]
]

{ #category : 'private - success handling' }
OTOtlpHttpJsonMetricExporter >> handleSuccessResponse: aResponse [

	| partialSuccess responseRepresentation |
	responseRepresentation := [ self successfulResponseRepresentationFrom: aResponse ]
		                          on: Error
		                          do: [ :error |
				                          self noteInvalidSuccessResponse: error.
				                          ^ false ].
	partialSuccess := self partialSuccessFrom: responseRepresentation.
	partialSuccess ifNil: [ ^ true ].
	self notePartialSuccess: partialSuccess.
	^ true
]

{ #category : 'testing' }
OTOtlpHttpJsonMetricExporter >> hasUserAgentHeaderConfigured: aDictionary [

	^ aDictionary keys anySatisfy: [ :each | each asString sameAs: 'User-Agent' ]
]

{ #category : 'accessing' }
OTOtlpHttpJsonMetricExporter >> httpClient [

	^ httpClient ifNil: [ httpClient := ZnClient new ]
]

{ #category : 'accessing' }
OTOtlpHttpJsonMetricExporter >> httpClient: anHttpClient [

	httpClient := anHttpClient
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

	| parsed |
	anObject ifNil: [ ^ aDefaultValue ].
	(anObject isInteger and: [ anObject >= 0 ]) ifTrue: [ ^ anObject ].
	parsed := self strictPositiveIntegerFrom: anObject asString.
	^ parsed ifNil: [ aDefaultValue ] ifNotNil: [ parsed ]
]

{ #category : 'private - encoding' }
OTOtlpHttpJsonMetricExporter >> normalizedPayloadForEncoding: anOTMetricSnapshot [

	^ anOTMetricSnapshot
]

{ #category : 'private - logging' }
OTOtlpHttpJsonMetricExporter >> noteInvalidSuccessResponse: anError [

	self warningSink value:
		(OTOtlpExportSupport invalidSuccessResponseMessageForSignal: self otlpSignalName transport: 'HTTP' error: anError)
]

{ #category : 'private - logging' }
OTOtlpHttpJsonMetricExporter >> notePartialSuccess: aDictionary [

	self warningSink value: (OTOtlpExportSupport partialSuccessMessageForSignal: self otlpSignalName details: aDictionary)
]

{ #category : 'private - logging' }
OTOtlpHttpJsonMetricExporter >> noteRetryExhaustedForError: anError [

	self warningSink value: (OTOtlpExportSupport retryExhaustedForTransportErrorMessageForSignal: self otlpSignalName error: anError)
]

{ #category : 'private - logging' }
OTOtlpHttpJsonMetricExporter >> noteRetryExhaustedForResponse: aResponse [

	self warningSink value:
		(OTOtlpExportSupport retryExhaustedForHttpStatusMessageForSignal: self otlpSignalName code: (self responseCodeFrom: aResponse))
]

{ #category : 'private - logging' }
OTOtlpHttpJsonMetricExporter >> otlpSignalName [

	^ 'metric'
]

{ #category : 'private - retry' }
OTOtlpHttpJsonMetricExporter >> parseRetryAfterMillisFrom: aValue [

	| parsed |
	aValue ifNil: [ ^ nil ].
	parsed := self strictPositiveIntegerFrom: aValue asString.
	^ parsed ifNotNil: [ parsed * 1000 ]
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
OTOtlpHttpJsonMetricExporter >> encodedPayloadFrom: anOTMetricSnapshot [

	^ self encoder encodeSnapshot: anOTMetricSnapshot
]

{ #category : 'private - encoding' }
OTOtlpHttpJsonMetricExporter >> payloadStringFrom: anOTMetricSnapshot [

	^ ZnUtils defaultJSONWriter toString: (self encodedPayloadFrom: (self normalizedPayloadForEncoding: anOTMetricSnapshot))
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

	^ aResponse code
]

{ #category : 'private - decoding' }
OTOtlpHttpJsonMetricExporter >> responseContentsFrom: aResponse [

	^ aResponse responseContents
]

{ #category : 'private - decoding' }
OTOtlpHttpJsonMetricExporter >> responseHeaderAt: aString in: aResponse ifAbsent: aBlock [

	^ aResponse responseHeaderAt: aString ifAbsent: aBlock
]

{ #category : 'private - retry' }
OTOtlpHttpJsonMetricExporter >> retryAfterMillisFromResponse: aResponse [

	^ self parseRetryAfterMillisFrom: (self responseHeaderAt: 'Retry-After' in: aResponse ifAbsent: [ nil ])
]

{ #category : 'private - retry' }
OTOtlpHttpJsonMetricExporter >> retryDelayMillisForAttempt: attemptNumber response: aResponse [

	| retryAfter baseDelay cappedDelay |
	retryAfter := aResponse ifNil: [ nil ] ifNotNil: [ self retryAfterMillisFromResponse: aResponse ].
	retryAfter ifNotNil: [ ^ retryAfter ].
	baseDelay := self class defaultRetryBaseDelayMillis * (2 raisedTo: attemptNumber - 1).
	cappedDelay := baseDelay min: self class defaultRetryMaxDelayMillis.
	^ self retryJitterBlock value: cappedDelay
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
