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

	^ 1000
]

{ #category : 'private - retry' }
OTOtlpHttpJsonSpanExporter class >> defaultRetryMaxDelayMillis [

	^ 5000
]

{ #category : 'private - logging' }
OTOtlpHttpJsonSpanExporter class >> defaultWarningSink [

	^ OTDiagnosticLogger defaultWarningSink
]

{ #category : 'private - retry' }
OTOtlpHttpJsonSpanExporter class >> maxExportAttempts [

	^ 6
]

{ #category : 'private - retry' }
OTOtlpHttpJsonSpanExporter class >> retryableStatusCodes [

	^ #( 429 502 503 504 ) asSet
]

{ #category : 'accessing' }
OTOtlpHttpJsonSpanExporter class >> supportedProtocol [

	^ 'http/json'
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

	| client timeoutMillis |
	client := self httpClient.
	client
		url: self configuration endpoint;
		method: #POST.
	timeoutMillis := self configuration timeoutMillisOrNil.
	timeoutMillis ifNotNil: [ client timeout: timeoutMillis ].
	self configuration headers associationsDo: [ :each | client headerAt: each key put: each value ].
	(self hasUserAgentHeaderConfigured: self configuration headers) ifFalse: [
		client headerAt: 'User-Agent' put: self configuration userAgent ].
	client
		headerAt: 'Content-Type' put: 'application/json';
		headerAt: 'Accept-Encoding' put: 'gzip'
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

{ #category : 'private - decoding' }
OTOtlpHttpJsonSpanExporter >> decodedResponseContentsFrom: aResponse [

	| contents encoding |
	contents := self responseContentsFrom: aResponse.
	contents ifNil: [ ^ nil ].
	encoding := self responseHeaderAt: 'Content-Encoding' in: aResponse ifAbsent: [ 'identity' ].
	(encoding asString sameAs: 'gzip') ifFalse: [ ^ contents ].
	^ (GZipReadStream on: contents readStream) upToEnd
]

{ #category : 'private - encoding' }
OTOtlpHttpJsonSpanExporter >> defaultEncoderClass [

	^ OTOtlpJsonTraceEncoder
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

	| entity |
	entity := self configuration usesGzipCompression
		          ifTrue: [ ZnEntity bytes: (self gzipCompressedBytesFor: aString) ]
		          ifFalse: [ ZnEntity with: aString type: ZnMimeType applicationJson ].
	entity contentType: ZnMimeType applicationJson.
	^ entity
]

{ #category : 'exporting' }
OTOtlpHttpJsonSpanExporter >> export: spans [

	^ self withExportLockDo: [
			  self isShutdown ifTrue: [ ^ false ].
			  self exportAttemptNumber: 1 payloadString: (self payloadStringFrom: spans) ]
]

{ #category : 'exporting' }
OTOtlpHttpJsonSpanExporter >> exportAttemptNumber: attemptNumber payloadString: payloadString [

	| response responseCode |
	[
		self withConfiguredTlsDuring: [ :certificateName |
				self applyConfigurationToHttpClient.
				self applyTlsCertificateName: certificateName toHttpClient: self httpClient.
				self httpClient entity: (self entityForPayload: payloadString).
				self configuration usesGzipCompression
					ifTrue: [ self httpClient headerAt: 'Content-Encoding' put: 'gzip' ]
					ifFalse: [ self removeRequestHeaderNamed: 'Content-Encoding' ].
				response := self httpClient
					            execute;
					            response ] ]
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
OTOtlpHttpJsonSpanExporter >> gzipCompressedBytesFor: aString [

	^ ByteArray streamContents: [ :stream |
			  | zipper |
			  zipper := GZipWriteStream on: stream.
			  zipper nextPutAll: aString utf8Encoded.
			  zipper close ]
]

{ #category : 'private - success handling' }
OTOtlpHttpJsonSpanExporter >> handleSuccessResponse: aResponse [

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
OTOtlpHttpJsonSpanExporter >> hasUserAgentHeaderConfigured: aDictionary [

	^ aDictionary keys anySatisfy: [ :each | each asString sameAs: 'User-Agent' ]
]

{ #category : 'accessing' }
OTOtlpHttpJsonSpanExporter >> httpClient [

	^ httpClient ifNil: [ httpClient := ZnClient new ]
]

{ #category : 'accessing' }
OTOtlpHttpJsonSpanExporter >> httpClient: anHttpClient [

	httpClient := anHttpClient
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

{ #category : 'private - success handling' }
OTOtlpHttpJsonSpanExporter >> nonNegativeIntegerFrom: anObject default: aDefaultValue [

	| parsed |
	anObject ifNil: [ ^ aDefaultValue ].
	(anObject isInteger and: [ anObject >= 0 ]) ifTrue: [ ^ anObject ].
	parsed := OTSpanExporter strictPositiveIntegerFrom: anObject asString.
	^ parsed ifNil: [ aDefaultValue ] ifNotNil: [ parsed ]
]

{ #category : 'private - encoding' }
OTOtlpHttpJsonSpanExporter >> normalizedPayloadForEncoding: anObject [

	^ anObject asArray
]

{ #category : 'private - logging' }
OTOtlpHttpJsonSpanExporter >> noteInvalidSuccessResponse: anError [

	self warningSink value:
		(OTOtlpExportSupport invalidSuccessResponseMessageForSignal: self otlpSignalName transport: 'HTTP' error: anError)
]

{ #category : 'private - logging' }
OTOtlpHttpJsonSpanExporter >> notePartialSuccess: aDictionary [

	self warningSink value: (OTOtlpExportSupport partialSuccessMessageForSignal: self otlpSignalName details: aDictionary)
]

{ #category : 'private - logging' }
OTOtlpHttpJsonSpanExporter >> noteRetryExhaustedForError: anError [

	self warningSink value: (OTOtlpExportSupport retryExhaustedForTransportErrorMessageForSignal: self otlpSignalName error: anError)
]

{ #category : 'private - logging' }
OTOtlpHttpJsonSpanExporter >> noteRetryExhaustedForResponse: aResponse [

	self warningSink value:
		(OTOtlpExportSupport retryExhaustedForHttpStatusMessageForSignal: self otlpSignalName code: (self responseCodeFrom: aResponse))
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

	| parsed |
	aValue ifNil: [ ^ nil ].
	parsed := OTSpanExporter strictPositiveIntegerFrom: aValue asString.
	^ parsed ifNil: [ nil ] ifNotNil: [ parsed * 1000 ]
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
OTOtlpHttpJsonSpanExporter >> payloadEncodingSelector [

	^ #encodeSpans:
]

{ #category : 'private - encoding' }
OTOtlpHttpJsonSpanExporter >> payloadStringFrom: spans [

	^ ZnUtils defaultJSONWriter toString:
		  (self encoder perform: self payloadEncodingSelector with: (self normalizedPayloadForEncoding: spans))
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

	self httpClient headers removeKey: aString ifAbsent: [ ]
]

{ #category : 'private - retry' }
OTOtlpHttpJsonSpanExporter >> responseCodeFrom: aResponse [

	^ aResponse code
]

{ #category : 'private - decoding' }
OTOtlpHttpJsonSpanExporter >> responseContentsFrom: aResponse [

	^ aResponse responseContents
]

{ #category : 'private - decoding' }
OTOtlpHttpJsonSpanExporter >> responseHeaderAt: aString in: aResponse ifAbsent: aBlock [

	^ aResponse responseHeaderAt: aString ifAbsent: aBlock
]

{ #category : 'private - retry' }
OTOtlpHttpJsonSpanExporter >> retryAfterMillisFromResponse: aResponse [

	^ self parseRetryAfterMillisFrom: (self responseHeaderAt: 'Retry-After' in: aResponse ifAbsent: [ nil ])
]

{ #category : 'private - retry' }
OTOtlpHttpJsonSpanExporter >> retryDelayMillisForAttempt: attemptNumber response: aResponse [

	| retryAfter baseDelay cappedDelay |
	retryAfter := aResponse ifNil: [ nil ] ifNotNil: [ self retryAfterMillisFromResponse: aResponse ].
	retryAfter ifNotNil: [ ^ retryAfter ].
	baseDelay := self class defaultRetryBaseDelayMillis * (2 raisedTo: attemptNumber - 1).
	cappedDelay := baseDelay min: self class defaultRetryMaxDelayMillis.
	^ self retryJitterBlock value: cappedDelay
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

{ #category : 'private - success handling' }
OTOtlpHttpJsonSpanExporter >> successfulResponseRepresentationFrom: aResponse [

	| contents text |
	contents := self decodedResponseContentsFrom: aResponse.
	contents ifNil: [ Error signal: 'Missing OTLP success response body' ].
	text := contents asString trimBoth.
	text isEmpty ifTrue: [ Error signal: 'Missing OTLP success response body' ].
	^ STONJSON fromString: text
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
