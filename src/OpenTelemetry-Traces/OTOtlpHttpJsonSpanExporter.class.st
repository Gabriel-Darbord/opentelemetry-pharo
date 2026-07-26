"
An OTLP traces exporter that sends JSON-encoded ExportTraceServiceRequest payloads over HTTP.
"
Class {
	#name : 'OTOtlpHttpJsonSpanExporter',
	#superclass : 'OTSpanExporter',
	#instVars : [
		'configuration',
		'encoder',
		'httpClient',
		'maxExportAttempts',
		'warningSink',
		'sleepStrategy',
		'retryJitterBlock'
	],
	#category : 'OpenTelemetry-Traces',
	#package : 'OpenTelemetry-Traces'
}

{ #category : 'instance creation' }
OTOtlpHttpJsonSpanExporter class >> configuration: anOtlpConfiguration [

	^ self new
		  configuration: anOtlpConfiguration;
		  yourself
]

{ #category : 'private - retry' }
OTOtlpHttpJsonSpanExporter class >> defaultRetryBaseDelayMillis [

	^ OTOtlpHttpJsonExportSupport defaultRetryBaseDelayMillis
]

{ #category : 'private - retry' }
OTOtlpHttpJsonSpanExporter class >> defaultRetryMaxDelayMillis [

	^ OTOtlpHttpJsonExportSupport defaultRetryMaxDelayMillis
]

{ #category : 'private - logging' }
OTOtlpHttpJsonSpanExporter class >> defaultWarningSink [

	^ OTOtlpHttpJsonExportSupport defaultWarningSink
]

{ #category : 'private - retry' }
OTOtlpHttpJsonSpanExporter class >> maxExportAttempts [

	^ OTOtlpHttpJsonExportSupport maxExportAttempts
]

{ #category : 'private - retry' }
OTOtlpHttpJsonSpanExporter class >> retryableStatusCodes [

	^ OTOtlpHttpJsonExportSupport retryableStatusCodes
]

{ #category : 'accessing' }
OTOtlpHttpJsonSpanExporter class >> supportedProtocol [

	^ OTOtlpHttpJsonExportSupport supportedProtocol
]

{ #category : 'private - tls' }
OTOtlpHttpJsonSpanExporter class >> tlsEnvironmentLock [

	^ OTClassStateStore valueAt: #otTlsEnvironmentLock forClass: self ifAbsentPut: [ Semaphore forMutualExclusion ]
]

{ #category : 'private - logging' }
OTOtlpHttpJsonSpanExporter class >> warningSink [

	^ OTClassStateStore valueAt: #otWarningSink forClass: self ifAbsent: [ self defaultWarningSink ]
]

{ #category : 'private - configuration' }
OTOtlpHttpJsonSpanExporter >> applyConfigurationToHttpClient [

	^ self httpJsonExportSupport applyConfigurationToHttpClient
]

{ #category : 'private - configuration' }
OTOtlpHttpJsonSpanExporter >> applyTlsCertificateName: aStringOrNil toHttpClient: aClient [

	aClient certificate: aStringOrNil
]

{ #category : 'accessing' }
OTOtlpHttpJsonSpanExporter >> configuration [

	^ configuration ifNil: [ configuration := OTOtlpExporterConfiguration forSignalNamed: 'TRACES' ]
]

{ #category : 'accessing' }
OTOtlpHttpJsonSpanExporter >> configuration: anOtlpConfiguration [

	configuration := anOtlpConfiguration
]

{ #category : 'private - configuration' }
OTOtlpHttpJsonSpanExporter >> configuredRequestTimeoutMillisOrNil [

	^ self configuration timeoutMillisOrNil
]

{ #category : 'private - decoding' }
OTOtlpHttpJsonSpanExporter >> decodedResponseContentsFrom: aResponse [

	^ self httpJsonExportSupport decodedResponseContentsFrom: aResponse
]

{ #category : 'private - encoding' }
OTOtlpHttpJsonSpanExporter >> defaultEncoderClass [

	^ OTOtlpJsonTraceEncoder
]

{ #category : 'private - encoding' }
OTOtlpHttpJsonSpanExporter >> encodedPayloadFrom: spans [

	^ self encoder encodeSpans: spans
]

{ #category : 'accessing' }
OTOtlpHttpJsonSpanExporter >> encoder [

	^ encoder ifNil: [ encoder := self defaultEncoderClass new ]
]

{ #category : 'accessing' }
OTOtlpHttpJsonSpanExporter >> encoder: anEncoder [

	encoder := anEncoder
]

{ #category : 'private - encoding' }
OTOtlpHttpJsonSpanExporter >> entityForPayload: aString [

	^ self httpJsonExportSupport entityForPayload: aString
]

{ #category : 'private - configuration' }
OTOtlpHttpJsonSpanExporter >> executeHttpRequestForPayloadString: payloadString usingSupport: anOtlpHttpJsonExportSupport [

	^ self withConfiguredTlsDuring: [ :certificateName |
			  anOtlpHttpJsonExportSupport configureHttpClientForPayloadString: payloadString.
			  self applyTlsCertificateName: certificateName toHttpClient: self httpClient.
			  self performConfiguredHttpRequest ]
]

{ #category : 'exporting' }
OTOtlpHttpJsonSpanExporter >> export: spans [

	^ self withExportLockDo: [
			  self isShutdown ifTrue: [ ^ false ].
			  self exportAttemptNumber: 1 payloadString: (self payloadStringFrom: spans) ]
]

{ #category : 'exporting' }
OTOtlpHttpJsonSpanExporter >> exportAttemptNumber: attemptNumber payloadString: payloadString [

	^ self httpJsonExportSupport exportAttemptNumber: attemptNumber payloadString: payloadString
]

{ #category : 'private - encoding' }
OTOtlpHttpJsonSpanExporter >> gzipCompressedBytesFor: aString [

	^ self httpJsonExportSupport gzipCompressedBytesFor: aString
]

{ #category : 'private - success handling' }
OTOtlpHttpJsonSpanExporter >> handleSuccessResponse: aResponse [

	^ self httpJsonExportSupport handleSuccessResponse: aResponse
]

{ #category : 'testing' }
OTOtlpHttpJsonSpanExporter >> hasUserAgentHeaderConfigured: aDictionary [

	^ self httpJsonExportSupport hasUserAgentHeaderConfigured: aDictionary
]

{ #category : 'accessing' }
OTOtlpHttpJsonSpanExporter >> httpClient [

	^ httpClient ifNil: [ httpClient := ZnClient new ]
]

{ #category : 'accessing' }
OTOtlpHttpJsonSpanExporter >> httpClient: anHttpClient [

	httpClient := anHttpClient
]

{ #category : 'private - support' }
OTOtlpHttpJsonSpanExporter >> httpJsonExportSupport [

	^ OTOtlpHttpJsonExportSupport for: self
]

{ #category : 'private - retry' }
OTOtlpHttpJsonSpanExporter >> isRetryableStatusCode: anInteger [

	^ self class retryableStatusCodes includes: anInteger
]

{ #category : 'private - retry' }
OTOtlpHttpJsonSpanExporter >> maxExportAttempts [

	^ maxExportAttempts ifNil: [ self class maxExportAttempts ]
]

{ #category : 'private - retry' }
OTOtlpHttpJsonSpanExporter >> maxExportAttempts: anInteger [

	maxExportAttempts := anInteger.
	^ self maxExportAttempts
]

{ #category : 'private - logging' }
OTOtlpHttpJsonSpanExporter >> nonNegativeIntegerFrom: anObject default: aDefaultValue [

	^ self httpJsonExportSupport nonNegativeIntegerFrom: anObject default: aDefaultValue
]

{ #category : 'private - encoding' }
OTOtlpHttpJsonSpanExporter >> normalizedPayloadForEncoding: anObject [

	^ anObject asArray
]

{ #category : 'private - logging' }
OTOtlpHttpJsonSpanExporter >> noteInvalidSuccessResponse: anError [

	^ self httpJsonExportSupport noteInvalidSuccessResponse: anError
]

{ #category : 'private - logging' }
OTOtlpHttpJsonSpanExporter >> notePartialSuccess: aDictionary [

	^ self httpJsonExportSupport notePartialSuccess: aDictionary
]

{ #category : 'private - logging' }
OTOtlpHttpJsonSpanExporter >> noteRetryExhaustedForError: anError [

	^ self httpJsonExportSupport noteRetryExhaustedForError: anError
]

{ #category : 'private - logging' }
OTOtlpHttpJsonSpanExporter >> noteRetryExhaustedForResponse: aResponse [

	^ self httpJsonExportSupport noteRetryExhaustedForResponse: aResponse
]

{ #category : 'private - tls' }
OTOtlpHttpJsonSpanExporter >> operatingSystemName [

	^ Smalltalk vm operatingSystemName
]

{ #category : 'private - logging' }
OTOtlpHttpJsonSpanExporter >> otlpSignalName [

	^ 'trace'
]

{ #category : 'private - retry' }
OTOtlpHttpJsonSpanExporter >> parseRetryAfterMillisFrom: aValue [

	^ self httpJsonExportSupport parseRetryAfterMillisFrom: aValue
]

{ #category : 'private - success handling' }
OTOtlpHttpJsonSpanExporter >> partialSuccessFrom: aDictionary [

	| partialSuccess |
	partialSuccess := aDictionary at: 'partialSuccess' ifAbsent: [ aDictionary at: 'partial_success' ifAbsent: [ nil ] ].
	partialSuccess ifNil: [ ^ nil ].
	((self rejectedCountFromPartialSuccess: partialSuccess) <= 0 and: [
		 (partialSuccess at: 'errorMessage' ifAbsent: [ partialSuccess at: 'error_message' ifAbsent: [ '' ] ]) asString trimBoth isEmpty ])
		ifTrue: [ ^ nil ].
	^ partialSuccess
]

{ #category : 'private - encoding' }
OTOtlpHttpJsonSpanExporter >> payloadStringFrom: anObject [

	^ self httpJsonExportSupport payloadStringFrom: anObject
]

{ #category : 'private - configuration' }
OTOtlpHttpJsonSpanExporter >> performConfiguredHttpRequest [

	^ self httpClient
		  execute;
		  response
]

{ #category : 'private - tls' }
OTOtlpHttpJsonSpanExporter >> platformSupportsPemFileBasedTlsOverrides [

	| normalizedName |
	normalizedName := self operatingSystemName asLowercase.
	^ (normalizedName includesSubstring: 'linux') or: [
		  (normalizedName includesSubstring: 'unix') or: [ normalizedName includesSubstring: 'bsd' ] ]
]

{ #category : 'private - success handling' }
OTOtlpHttpJsonSpanExporter >> rejectedCountFromPartialSuccess: aDictionary [

	^ self
		  nonNegativeIntegerFrom: (aDictionary at: 'rejectedSpans' ifAbsent: [ aDictionary at: 'rejected_spans' ifAbsent: [ 0 ] ])
		  default: 0
]

{ #category : 'private - configuration' }
OTOtlpHttpJsonSpanExporter >> removeRequestHeaderNamed: aString [

	self httpClient removeHeaderNamed: aString
]

{ #category : 'private - retry' }
OTOtlpHttpJsonSpanExporter >> responseCodeFrom: aResponse [

	^ self httpJsonExportSupport responseCodeFrom: aResponse
]

{ #category : 'private - decoding' }
OTOtlpHttpJsonSpanExporter >> responseContentsFrom: aResponse [

	^ self httpJsonExportSupport responseContentsFrom: aResponse
]

{ #category : 'private - decoding' }
OTOtlpHttpJsonSpanExporter >> responseHeaderAt: aString in: aResponse ifAbsent: aBlock [

	^ self httpJsonExportSupport responseHeaderAt: aString in: aResponse ifAbsent: aBlock
]

{ #category : 'private - retry' }
OTOtlpHttpJsonSpanExporter >> retryAfterMillisFromResponse: aResponse [

	^ self httpJsonExportSupport retryAfterMillisFromResponse: aResponse
]

{ #category : 'private - retry' }
OTOtlpHttpJsonSpanExporter >> retryDelayMillisForAttempt: attemptNumber response: aResponse [

	^ self httpJsonExportSupport retryDelayMillisForAttempt: attemptNumber response: aResponse
]

{ #category : 'private - retry' }
OTOtlpHttpJsonSpanExporter >> retryJitterBlock [

	^ retryJitterBlock ifNil: [
			  retryJitterBlock := [ :delayMillis |
				                      | multiplier |
				                      multiplier := 0.8 + (Random new next * 0.4).
				                      (delayMillis asFloat * multiplier) rounded max: 1 ] ]
]

{ #category : 'private - retry' }
OTOtlpHttpJsonSpanExporter >> retryJitterBlock: aBlock [

	retryJitterBlock := aBlock.
	^ self retryJitterBlock
]

{ #category : 'private - retry' }
OTOtlpHttpJsonSpanExporter >> sleepForMilliseconds: anInteger [

	self sleepStrategy value: anInteger
]

{ #category : 'private - retry' }
OTOtlpHttpJsonSpanExporter >> sleepStrategy [

	^ sleepStrategy ifNil: [ sleepStrategy := [ :delayMillis | (Delay forMilliseconds: delayMillis) wait ] ]
]

{ #category : 'private - retry' }
OTOtlpHttpJsonSpanExporter >> sleepStrategy: aBlock [

	sleepStrategy := aBlock.
	^ self sleepStrategy
]

{ #category : 'private - logging' }
OTOtlpHttpJsonSpanExporter >> strictPositiveIntegerFrom: aString [

	^ OTSpanExporter strictPositiveIntegerFrom: aString
]

{ #category : 'private - success handling' }
OTOtlpHttpJsonSpanExporter >> successfulResponseRepresentationFrom: aResponse [

	^ self httpJsonExportSupport successfulResponseRepresentationFrom: aResponse
]

{ #category : 'private - tls' }
OTOtlpHttpJsonSpanExporter >> textContentsAtPath: aString [

	^ aString asFileReference contents
]

{ #category : 'private - tls' }
OTOtlpHttpJsonSpanExporter >> validateConfiguredTlsOverrides [

	self configuration hasTlsFileOverrides ifFalse: [ ^ self ].
	self configuration usesSecureConnection ifFalse: [ Error signal: 'OTLP TLS file options require a secure https endpoint' ].
	self platformSupportsPemFileBasedTlsOverrides ifFalse: [
		Error signal: 'OTLP TLS file options are not supported on ' , self operatingSystemName ].
	(self configuration clientKeyFile isNil xor: self configuration clientCertificateFile isNil) ifTrue: [
		Error signal: 'OTLP client key and client certificate file options must be configured together' ]
]

{ #category : 'private - logging' }
OTOtlpHttpJsonSpanExporter >> warningSink [

	^ warningSink ifNil: [ self class warningSink ]
]

{ #category : 'private - logging' }
OTOtlpHttpJsonSpanExporter >> warningSink: aBlock [

	warningSink := aBlock.
	^ self warningSink
]

{ #category : 'private - tls' }
OTOtlpHttpJsonSpanExporter >> withConfiguredTlsClientCertificateNameDo: aBlock [

	| combinedFile |
	self configuration hasClientCertificateConfiguration ifFalse: [ ^ aBlock value: nil ].
	combinedFile := self
		                writeCombinedClientCertificateFileFrom: self configuration clientCertificateFile
		                andKeyFrom: self configuration clientKeyFile.
	[ ^ aBlock value: combinedFile pathString ] ensure: [ combinedFile ensureDelete ]
]

{ #category : 'private - tls' }
OTOtlpHttpJsonSpanExporter >> withConfiguredTlsDuring: aBlock [

	self validateConfiguredTlsOverrides.
	^ self withConfiguredTlsEnvironmentDuring: [
		  self withConfiguredTlsClientCertificateNameDo: [ :certificateName | aBlock value: certificateName ] ]
]

{ #category : 'private - tls' }
OTOtlpHttpJsonSpanExporter >> withConfiguredTlsEnvironmentDuring: aBlock [

	| environment originalValue absent |
	self configuration certificateFile ifNil: [ ^ aBlock value ].
	environment := Smalltalk os environment.
	absent := Object new.
	^ self class tlsEnvironmentLock critical: [
			  originalValue := environment at: 'SSL_CERT_FILE' ifAbsent: [ absent ].
			  environment at: 'SSL_CERT_FILE' put: self configuration certificateFile.
			  [ ^ aBlock value ] ensure: [
					  originalValue == absent
						  ifTrue: [ (environment includesKey: 'SSL_CERT_FILE') ifTrue: [ environment removeKey: 'SSL_CERT_FILE' ] ]
						  ifFalse: [ environment at: 'SSL_CERT_FILE' put: originalValue ] ] ]
]

{ #category : 'private - tls' }
OTOtlpHttpJsonSpanExporter >> writeCombinedClientCertificateFileFrom: certificatePath andKeyFrom: keyPath [

	| certificateContents combinedFile keyContents |
	certificateContents := self textContentsAtPath: certificatePath.
	keyContents := self textContentsAtPath: keyPath.
	combinedFile := FileReference newTempFilePrefix: 'otel-client-cert-' suffix: '.pem'.
	combinedFile writeStreamDo: [ :stream |
			stream nextPutAll: certificateContents.
			(certificateContents endsWith: String lf asString) ifFalse: [ stream lf ].
			stream nextPutAll: keyContents.
			(keyContents endsWith: String lf asString) ifFalse: [ stream lf ] ].
	^ combinedFile
]
