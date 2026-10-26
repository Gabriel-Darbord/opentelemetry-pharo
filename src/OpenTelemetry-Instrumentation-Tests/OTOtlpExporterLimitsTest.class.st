Class {
	#name : 'OTOtlpExporterLimitsTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'private' }
OTOtlpExporterLimitsTest >> exporterClasses [

	^ {
		  OTOtlpHttpJsonSpanExporter.
		  OTOtlpHttpProtobufSpanExporter.
		  OTOtlpGrpcSpanExporter.
		  OTOtlpHttpJsonLogRecordExporter.
		  OTOtlpHttpProtobufLogRecordExporter.
		  OTOtlpGrpcLogRecordExporter.
		  OTOtlpHttpJsonMetricExporter.
		  OTOtlpHttpProtobufMetricExporter.
		  OTOtlpGrpcMetricExporter }
]

{ #category : 'running' }
OTOtlpExporterLimitsTest >> setUp [

	super setUp.
	OTGrpcTestSupport installFakeGrpcResolvers
]

{ #category : 'running' }
OTOtlpExporterLimitsTest >> tearDown [

	OTGrpcTestSupport removeFakeGrpcResolvers.
	super tearDown
]

{ #category : 'tests' }
OTOtlpExporterLimitsTest >> testEarlierCallerDeadlineTakesPrecedence [

	self withRetryingExporter: OTOtlpHttpJsonSpanExporter do: [ :exporter :payload :warnings |
			| result |
			exporter configuration timeoutMillis: 1000.
			result := [ exporter export: payload ] valueWithinMilliseconds: 50 onTimeout: [ #callerTimeout ].
			self assert: result equals: #callerTimeout.
			self assert: warnings isEmpty.
			exporter httpClient responseCode: 200.
			self assert: (exporter export: payload) ]
]

{ #category : 'tests' }
OTOtlpExporterLimitsTest >> testExportTimeoutIncludesRetryWaitForEverySignalAndTransport [

	self exporterClasses do: [ :exporterClass |
			self withRetryingExporter: exporterClass do: [ :exporter :payload :warnings |
					| elapsed |
					elapsed := [ self deny: (exporter export: payload) ] timeToRun asMilliSeconds.
					self assert: elapsed < 180 description: exporterClass name.
					self assert: (warnings anySatisfy: [ :each | each includesSubstring: 'timed out' ]) description: exporterClass name ] ]
]

{ #category : 'tests' }
OTOtlpExporterLimitsTest >> testMalformedCompressedFailureResponseDoesNotEscape [

	self withRetryingExporter: OTOtlpHttpJsonSpanExporter do: [ :exporter :payload :warnings |
			exporter httpClient
				responseCode: 503;
				responseContents: #[ 1 2 3 ];
				responseHeaders: (Dictionary new
						 at: 'Content-Encoding' put: 'gzip';
						 yourself).
			self deny: (exporter export: payload).
			self assert: exporter httpClient executionCount equals: 1.
			self assert: warnings size equals: 1 ]
]

{ #category : 'tests' }
OTOtlpExporterLimitsTest >> testNativeHttpTimeoutCancelsAfterAPreviousSuccessfulRequest [

	| calls exporter result server |
	calls := 0.
	server := ZnServer defaultServerClass on: 0.
	server bindingAddress: #[ 127 0 0 1 ].
	server delegate: (ZnValueDelegate with: [ :request |
				 calls := calls + 1.
				 calls > 1 ifTrue: [ (Delay forMilliseconds: 200) wait ].
				 ZnResponse ok: (ZnEntity json: '{}') ]).
	server start.
	exporter := OTOtlpHttpJsonSpanExporter new.
	exporter configuration
		endpoint: 'http://127.0.0.1:' , server port asString , '/v1/traces';
		timeoutMillis: 1000.
	OTOtlpHttpJsonSpanExporter warningSink: [ :message |  ].
	[
		self assert: (exporter export: #(  )).
		exporter configuration timeoutMillis: 50.
		result := [ exporter export: #(  ) ] valueWithinMilliseconds: 300 onTimeout: [ #callerTimeout ].
		self assert: result equals: false.
		self assert: calls equals: 2 ] ensure: [
			exporter httpClient close.
			server stop.
			OTOtlpHttpJsonSpanExporter warningSink: nil ]
]

{ #category : 'tests' }
OTOtlpExporterLimitsTest >> testNativeSizeErrorsAreNotRetried [

	self withRetryingExporter: OTOtlpHttpJsonSpanExporter do: [ :exporter :payload :warnings |
			exporter httpClient plannedExecutions add: [ :client | ZnEntityTooLarge signal ].
			self deny: (exporter export: payload).
			self assert: exporter httpClient executionCount equals: 1.
			self assert: warnings size equals: 1 ].
	self withRetryingExporter: OTOtlpGrpcSpanExporter do: [ :exporter :payload :warnings |
			| calls |
			calls := 0.
			exporter requestExecutor: [ :request |
					calls := calls + 1.
					GRPCMessageTooLarge signal ].
			self deny: (exporter export: payload).
			self assert: calls equals: 1.
			self assert: warnings size equals: 1 ]
]

{ #category : 'tests' }
OTOtlpExporterLimitsTest >> testOversizedResponsesAreNotRetriedForEverySignalAndTransport [

	self exporterClasses do: [ :exporterClass |
			self withRetryingExporter: exporterClass do: [ :exporter :payload :warnings |
					| calls |
					calls := 0.
					exporter configuration maxResponseSize: 1.
					exporter sleepStrategy: [ :millis | self fail: 'An oversized response must not be retried' ].
					(exporter isKindOf: OTOtlpGrpcSpanExporter)
						ifTrue: [
								exporter requestExecutor: [ :request |
										calls := calls + 1.
										self assert: request maxResponseSize equals: 1.
										OTFakeGRPCResponse status: (OTFakeGRPCStatus code: 14 message: 'unavailable') payload: #[ 1 2 ] ] ]
						ifFalse: [
								exporter httpClient
									responseCode: 503;
									responseContents: 'xx' ].
					self deny: (exporter export: payload) description: exporterClass name.
					(exporter isKindOf: OTOtlpGrpcSpanExporter) ifFalse: [
							calls := exporter httpClient executionCount.
							self assert: exporter httpClient maximumEntitySize equals: 1 ].
					self assert: calls equals: 1.
					self assert: warnings size equals: 1.
					self assert: (warnings first includesSubstring: 'maximum response size') ] ]
]

{ #category : 'tests' }
OTOtlpExporterLimitsTest >> testRequestLimitsRejectBeforeCompressionAndTransport [

	self exporterClasses do: [ :exporterClass |
			self withRetryingExporter: exporterClass do: [ :exporter :payload :warnings |
					| calls result |
					calls := 0.
					exporter configuration
						maxRequestSize: 1;
						compression: 'gzip'.
					(exporter isKindOf: OTOtlpGrpcSpanExporter)
						ifTrue: [
								exporter requestExecutor: [ :request | calls := calls + 1 ].
								result := exporter exportAttemptNumber: 1 payloadBytes: #[ 1 2 ] ]
						ifFalse: [
								result := exporter exportAttemptNumber: 1 payloadString: 'é'.
								calls := exporter httpClient executionCount ].
					self deny: result description: exporterClass name.
					self assert: calls equals: 0.
					self assert: warnings size equals: 1.
					self assert: (warnings first includesSubstring: 'maximum request size') ] ]
]

{ #category : 'tests' }
OTOtlpExporterLimitsTest >> testResponseDecompressionIsBounded [

	self withRetryingExporter: OTOtlpHttpJsonSpanExporter do: [ :exporter :payload :warnings |
			exporter configuration maxResponseSize: 64.
			exporter httpClient
				responseCode: 200;
				responseContents: (exporter gzipCompressedBytesFor: (String new: 1000 withAll: $x));
				responseHeaders: (Dictionary new
						 at: 'Content-Encoding' put: 'gzip';
						 yourself).
			self deny: (exporter export: payload).
			self assert: exporter httpClient executionCount equals: 1.
			self assert: warnings size equals: 1 ]
]

{ #category : 'tests' }
OTOtlpExporterLimitsTest >> testUnlimitedExportBudgetPreservesNativeIoTimeout [

	self withRetryingExporter: OTOtlpHttpJsonSpanExporter do: [ :exporter :payload :warnings |
			exporter configuration timeoutMillis: OTOtlpExporterConfiguration noTimeoutMillis.
			exporter httpClient timeout: 7.
			exporter sleepStrategy: [ :delay |
					(Delay forMilliseconds: 70) wait.
					exporter httpClient responseCode: 200 ].
			self assert: (exporter export: payload).
			self assert: exporter httpClient timeout equals: 7.
			self assert: warnings isEmpty ]
]

{ #category : 'tests' }
OTOtlpExporterLimitsTest >> testZincEnforcesDecompressedSizeWhileReading [

	self should: [ self zincResponseFromGzipped: (String new: 1000 withAll: $x) limit: 64 ] raise: ZnEntityTooLarge.
	self withRetryingExporter: OTOtlpHttpJsonSpanExporter do: [ :exporter :payload :warnings |
			| response |
			response := self zincResponseFromGzipped: '{}' limit: 64.
			self assert: (exporter handleSuccessResponse: response).
			self assert: warnings isEmpty ]
]

{ #category : 'private' }
OTOtlpExporterLimitsTest >> withRetryingExporter: exporterClass do: aBlock [

	| client exporter isGrpc payload warnings |
	exporter := exporterClass new.
	isGrpc := exporter isKindOf: OTOtlpGrpcSpanExporter.
	payload := (#( OTOtlpHttpJsonMetricExporter OTOtlpHttpProtobufMetricExporter OTOtlpGrpcMetricExporter ) includes:
		            exporterClass name)
		           ifTrue: [ OTMetricSnapshot empty ]
		           ifFalse: [ #(  ) ].
	exporter configuration timeoutMillis: 50.
	warnings := OrderedCollection new.
	exporterClass warningSink: [ :message | warnings add: message ].
	isGrpc
		ifTrue: [
				exporter requestExecutor: [ :request |
					OTFakeGRPCResponse status: (OTFakeGRPCStatus code: 14 message: 'unavailable') payload: #[  ] ] ]
		ifFalse: [
				client := OTRecordingHttpClient new.
				client responseCode: 503.
				exporter httpClient: client ].
	exporter sleepStrategy: [ :millis | (Delay forMilliseconds: 200) wait ].
	[ aBlock value: exporter value: payload value: warnings ] ensure: [ exporterClass warningSink: nil ]
]

{ #category : 'private' }
OTOtlpExporterLimitsTest >> zincResponseFromGzipped: aString limit: limit [

	| bytes options wire |
	bytes := ByteArray streamContents: [ :output |
			         | zipper |
			         zipper := GZipWriteStream on: output.
			         zipper
				         nextPutAll: aString utf8Encoded;
				         close ].
	wire := ByteArray streamContents: [ :output |
			        output
				        nextPutAll:
					        ('HTTP/1.1 200 OK' , String crlf , 'Content-Type: application/json' , String crlf , 'Content-Encoding: gzip'
					         , String crlf , 'Content-Length: ' , bytes size asString , String crlf , String crlf) utf8Encoded;
				        nextPutAll: bytes ].
	options := ZnOptions globalDefault copy
		           at: #maximumEntitySize put: limit;
		           yourself.
	^ ZnCurrentOptions value: options during: [ ZnResponse readFrom: wire readStream ]
]
