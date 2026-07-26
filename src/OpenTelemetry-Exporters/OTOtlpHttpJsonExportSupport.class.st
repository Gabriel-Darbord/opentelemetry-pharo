"
I centralize the OTLP HTTP JSON request, retry, decoding, and warning logic shared by the trace and metric exporters.

Exporters keep signal-specific mapping and transport hooks, while I handle the common HTTP client configuration and retry semantics.
"
Class {
	#name : 'OTOtlpHttpJsonExportSupport',
	#superclass : 'Object',
	#instVars : [
		'exporter'
	],
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'private - retry' }
OTOtlpHttpJsonExportSupport class >> defaultRetryBaseDelayMillis [

	^ 1000
]

{ #category : 'private - retry' }
OTOtlpHttpJsonExportSupport class >> defaultRetryMaxDelayMillis [

	^ 5000
]

{ #category : 'private - logging' }
OTOtlpHttpJsonExportSupport class >> defaultWarningSink [

	^ OTDiagnosticLogger defaultWarningSink
]

{ #category : 'instance creation' }
OTOtlpHttpJsonExportSupport class >> for: anExporter [

	^ self new
		  exporter: anExporter;
		  yourself
]

{ #category : 'private - retry' }
OTOtlpHttpJsonExportSupport class >> maxExportAttempts [

	^ 6
]

{ #category : 'private - retry' }
OTOtlpHttpJsonExportSupport class >> retryableStatusCodes [

	^ #( 429 502 503 504 ) asSet
]

{ #category : 'accessing' }
OTOtlpHttpJsonExportSupport class >> supportedProtocol [

	^ 'http/json'
]

{ #category : 'private - logging' }
OTOtlpHttpJsonExportSupport class >> warningSink: aBlock for: aBehavior [

	OTClassStateStore valueAt: #otWarningSink forClass: aBehavior putOrRemoveIfNil: aBlock.
	^ self warningSinkFor: aBehavior
]

{ #category : 'private - logging' }
OTOtlpHttpJsonExportSupport class >> warningSinkFor: aBehavior [

	^ OTClassStateStore valueAt: #otWarningSink forClass: aBehavior ifAbsent: [ self defaultWarningSink ]
]

{ #category : 'private - configuration' }
OTOtlpHttpJsonExportSupport >> applyConfigurationToHttpClient [

	| client timeoutMillis |
	client := self exporter httpClient.
	client
		url: self exporter configuration endpoint;
		method: #POST.
	timeoutMillis := self exporter configuredRequestTimeoutMillisOrNil.
	timeoutMillis ifNotNil: [ client timeout: timeoutMillis ].
	self exporter configuration headers associationsDo: [ :each | client headerAt: each key put: each value ].
	(self hasUserAgentHeaderConfigured: self exporter configuration headers) ifFalse: [
		client headerAt: 'User-Agent' put: self exporter configuration userAgent ].
	client
		headerAt: 'Content-Type' put: 'application/json';
		headerAt: 'Accept-Encoding' put: 'gzip'
]

{ #category : 'private - configuration' }
OTOtlpHttpJsonExportSupport >> configureHttpClientForPayloadString: payloadString [

	self exporter applyConfigurationToHttpClient.
	self exporter httpClient entity: (self exporter entityForPayload: payloadString).
	self exporter configuration usesGzipCompression
		ifTrue: [ self exporter httpClient headerAt: 'Content-Encoding' put: 'gzip' ]
		ifFalse: [ self exporter removeRequestHeaderNamed: 'Content-Encoding' ]
]

{ #category : 'private - decoding' }
OTOtlpHttpJsonExportSupport >> decodedResponseContentsFrom: aResponse [

	| contents encoding |
	contents := self responseContentsFrom: aResponse.
	contents ifNil: [ ^ nil ].
	encoding := self responseHeaderAt: 'Content-Encoding' in: aResponse ifAbsent: [ 'identity' ].
	(encoding asString sameAs: 'gzip') ifFalse: [ ^ contents ].
	^ (GZipReadStream on: contents readStream) upToEnd
]

{ #category : 'private - encoding' }
OTOtlpHttpJsonExportSupport >> entityForPayload: aString [

	| entity |
	entity := self exporter configuration usesGzipCompression
		          ifTrue: [ ZnEntity bytes: (self gzipCompressedBytesFor: aString) ]
		          ifFalse: [ ZnEntity with: aString type: ZnMimeType applicationJson ].
	entity contentType: ZnMimeType applicationJson.
	^ entity
]

{ #category : 'exporting' }
OTOtlpHttpJsonExportSupport >> exportAttemptNumber: attemptNumber payloadString: payloadString [

	| response responseCode |
	[ response := self exporter executeHttpRequestForPayloadString: payloadString usingSupport: self ]
		on: Error
		do: [ :error |
				attemptNumber >= self exporter maxExportAttempts ifTrue: [
						self noteRetryExhaustedForError: error.
						^ false ].
				self exporter sleepForMilliseconds: (self retryDelayMillisForAttempt: attemptNumber response: nil).
				^ self exportAttemptNumber: attemptNumber + 1 payloadString: payloadString ].
	responseCode := self responseCodeFrom: response.
	responseCode = 200 ifTrue: [ ^ self handleSuccessResponse: response ].
	(self exporter isRetryableStatusCode: responseCode) ifFalse: [ ^ false ].
	attemptNumber >= self exporter maxExportAttempts ifTrue: [
			self noteRetryExhaustedForResponse: response.
			^ false ].
	self exporter sleepForMilliseconds: (self retryDelayMillisForAttempt: attemptNumber response: response).
	^ self exportAttemptNumber: attemptNumber + 1 payloadString: payloadString
]

{ #category : 'accessing' }
OTOtlpHttpJsonExportSupport >> exporter [

	^ exporter
]

{ #category : 'accessing' }
OTOtlpHttpJsonExportSupport >> exporter: anExporter [

	exporter := anExporter
]

{ #category : 'private - encoding' }
OTOtlpHttpJsonExportSupport >> gzipCompressedBytesFor: aString [

	^ ByteArray streamContents: [ :stream |
			  | zipper |
			  zipper := GZipWriteStream on: stream.
			  zipper nextPutAll: aString utf8Encoded.
			  zipper close ]
]

{ #category : 'private - success handling' }
OTOtlpHttpJsonExportSupport >> handleSuccessResponse: aResponse [

	| partialSuccess responseRepresentation |
	responseRepresentation := [ self exporter successfulResponseRepresentationFrom: aResponse ]
		                          on: Error
		                          do: [ :error |
				                          self noteInvalidSuccessResponse: error.
				                          ^ false ].
	partialSuccess := self exporter partialSuccessFrom: responseRepresentation.
	partialSuccess ifNil: [ ^ true ].
	self notePartialSuccess: partialSuccess.
	^ true
]

{ #category : 'testing' }
OTOtlpHttpJsonExportSupport >> hasUserAgentHeaderConfigured: aDictionary [

	^ aDictionary keys anySatisfy: [ :each | each asString sameAs: 'User-Agent' ]
]

{ #category : 'private - logging' }
OTOtlpHttpJsonExportSupport >> nonNegativeIntegerFrom: anObject default: aDefaultValue [

	| parsed |
	anObject ifNil: [ ^ aDefaultValue ].
	(anObject isInteger and: [ anObject >= 0 ]) ifTrue: [ ^ anObject ].
	parsed := self exporter strictPositiveIntegerFrom: anObject asString.
	^ parsed ifNil: [ aDefaultValue ] ifNotNil: [ parsed ]
]

{ #category : 'private - logging' }
OTOtlpHttpJsonExportSupport >> noteInvalidSuccessResponse: anError [

	self exporter warningSink value:
		(OTOtlpExportSupport invalidSuccessResponseMessageForSignal: self exporter otlpSignalName transport: 'HTTP' error: anError)
]

{ #category : 'private - logging' }
OTOtlpHttpJsonExportSupport >> notePartialSuccess: aDictionary [

	self exporter warningSink value:
		(OTOtlpExportSupport partialSuccessMessageForSignal: self exporter otlpSignalName details: aDictionary)
]

{ #category : 'private - logging' }
OTOtlpHttpJsonExportSupport >> noteRetryExhaustedForError: anError [

	self exporter warningSink value:
		(OTOtlpExportSupport retryExhaustedForTransportErrorMessageForSignal: self exporter otlpSignalName error: anError)
]

{ #category : 'private - logging' }
OTOtlpHttpJsonExportSupport >> noteRetryExhaustedForResponse: aResponse [

	self exporter warningSink value: (OTOtlpExportSupport
			 retryExhaustedForHttpStatusMessageForSignal: self exporter otlpSignalName
			 code: (self responseCodeFrom: aResponse))
]

{ #category : 'private - retry' }
OTOtlpHttpJsonExportSupport >> parseRetryAfterMillisFrom: aValue [

	| parsed |
	aValue ifNil: [ ^ nil ].
	parsed := self exporter strictPositiveIntegerFrom: aValue asString.
	^ parsed ifNotNil: [ :millis | millis * 1000 ]
]

{ #category : 'private - encoding' }
OTOtlpHttpJsonExportSupport >> payloadStringFrom: anObject [

	^ ZnUtils defaultJSONWriter toString: (self exporter encodedPayloadFrom: (self exporter normalizedPayloadForEncoding: anObject))
]

{ #category : 'private - retry' }
OTOtlpHttpJsonExportSupport >> responseCodeFrom: aResponse [

	^ aResponse code
]

{ #category : 'private - decoding' }
OTOtlpHttpJsonExportSupport >> responseContentsFrom: aResponse [

	^ aResponse responseContents
]

{ #category : 'private - decoding' }
OTOtlpHttpJsonExportSupport >> responseHeaderAt: aString in: aResponse ifAbsent: aBlock [

	^ aResponse responseHeaderAt: aString ifAbsent: aBlock
]

{ #category : 'private - retry' }
OTOtlpHttpJsonExportSupport >> retryAfterMillisFromResponse: aResponse [

	^ self parseRetryAfterMillisFrom: (self responseHeaderAt: 'Retry-After' in: aResponse ifAbsent: [ nil ])
]

{ #category : 'private - retry' }
OTOtlpHttpJsonExportSupport >> retryDelayMillisForAttempt: attemptNumber response: aResponse [

	| retryAfter baseDelay cappedDelay |
	retryAfter := aResponse ifNotNil: [ self retryAfterMillisFromResponse: aResponse ].
	retryAfter ifNotNil: [ ^ retryAfter ].
	baseDelay := self class defaultRetryBaseDelayMillis * (2 raisedTo: attemptNumber - 1).
	cappedDelay := baseDelay min: self class defaultRetryMaxDelayMillis.
	^ self exporter retryJitterBlock value: cappedDelay
]

{ #category : 'private - success handling' }
OTOtlpHttpJsonExportSupport >> successfulResponseRepresentationFrom: aResponse [

	| contents text |
	contents := self decodedResponseContentsFrom: aResponse.
	contents ifNil: [ Error signal: 'Missing OTLP success response body' ].
	text := contents asString trimBoth.
	text isEmpty ifTrue: [ Error signal: 'Missing OTLP success response body' ].
	^ STONJSON fromString: text
]
