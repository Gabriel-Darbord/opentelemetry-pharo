"
I poll a Jaeger remote sampling endpoint over gRPC and delegate sampling decisions
to the latest strategy received from the backend.

When started by the SDK lifecycle I refresh in a background worker; when used
standalone I can still fall back to lazy refresh on demand until explicitly
started.
"
Class {
	#name : 'OTJaegerRemoteSampler',
	#superclass : 'OTSampler',
	#instVars : [
		'serviceName',
		'endpoint',
		'pollingIntervalMillis',
		'timeoutMillis',
		'currentSampler',
		'grpcChannel',
		'grpcTransport',
		'requestExecutor',
		'clockBlock',
		'lastPollTimeMillis',
		'refreshLock',
		'warningSink',
		'pollingProcess',
		'pollingSemaphore',
		'shutdownRequested'
	],
	#category : 'OpenTelemetry-Sampling',
	#package : 'OpenTelemetry-Sampling'
}

{ #category : 'defaults' }
OTJaegerRemoteSampler class >> defaultEndpoint [

	^ 'http://localhost:14250'
]

{ #category : 'defaults' }
OTJaegerRemoteSampler class >> defaultInitialSampler [

	^ OTSampler probabilityOrAlwaysOff: self defaultInitialSamplingProbability
]

{ #category : 'defaults' }
OTJaegerRemoteSampler class >> defaultInitialSamplingProbability [

	^ 0.001
]

{ #category : 'defaults' }
OTJaegerRemoteSampler class >> defaultPollingIntervalMillis [

	^ 60000
]

{ #category : 'defaults' }
OTJaegerRemoteSampler class >> defaultTimeoutMillis [

	^ 10000
]

{ #category : 'testing' }
OTJaegerRemoteSampler class >> grpcDependenciesAvailable [

	^ #( GRPCChannel GRPCEndpoint GRPCRequest GRPCHTTP2Transport ) allSatisfy: [
		:each | Smalltalk globals includesKey: each ]
]

{ #category : 'private' }
OTJaegerRemoteSampler class >> normalizedEndpoint: aString [

	| normalizedValue url endpointString |
	normalizedValue := aString asString trimBoth.
	normalizedValue isEmpty ifTrue: [
		Error signal: 'Jaeger remote sampler endpoint must not be empty' ].
	url := [ ZnUrl fromString: normalizedValue ]
		on: Error
		do: [ Error signal: 'Jaeger remote sampler endpoint must be an absolute http(s) URL' ].
	((#( 'http' 'https' ) includes: url scheme)
		and: [ url host notNil and: [ url host isNotEmpty ] ]) ifFalse: [
			Error signal: 'Jaeger remote sampler endpoint must be an absolute http(s) URL' ].
	url port ifNil: [
		Error signal: 'Jaeger remote sampler endpoint must include an explicit port' ].
	endpointString := url printString.
	^ endpointString
		ifNotEmpty: [
			(endpointString last = $/)
				ifTrue: [ endpointString allButLast ]
				ifFalse: [ endpointString ] ]
		ifEmpty: [ endpointString ]
]

{ #category : 'instance creation' }
OTJaegerRemoteSampler class >> serviceName: aString [

	^ self new
		serviceName: aString;
		yourself
]

{ #category : 'accessing' }
OTJaegerRemoteSampler >> clockBlock: aBlockClosure [

	clockBlock := aBlockClosure
]

{ #category : 'private' }
OTJaegerRemoteSampler >> currentTimeMillis [

	^ clockBlock value
]

{ #category : 'private - refreshing' }
OTJaegerRemoteSampler >> ensurePollingProcess [

	self isShutdown ifTrue: [ ^ nil ].
	(self isStarted and: [ pollingProcess notNil ]) ifTrue: [ ^ pollingProcess ].
	pollingProcess := [ self runPollingLoop ] forkAt: Processor userBackgroundPriority.
	^ pollingProcess
]

{ #category : 'accessing' }
OTJaegerRemoteSampler >> currentSampler [

	^ currentSampler
]

{ #category : 'accessing' }
OTJaegerRemoteSampler >> currentSampler: anOTSampler [

	anOTSampler ifNil: [
		Error signal: 'Jaeger remote sampler requires a delegate sampler' ].
	currentSampler := anOTSampler
]

{ #category : 'accessing' }
OTJaegerRemoteSampler >> description [

	^ 'JaegerRemoteSampler{', self currentSampler description, '}'
]

{ #category : 'private - grpc' }
OTJaegerRemoteSampler >> endpoint [

	^ endpoint
]

{ #category : 'private - grpc' }
OTJaegerRemoteSampler >> endpoint: aString [

	endpoint := self class normalizedEndpoint: aString.
	grpcChannel := nil.
	^ endpoint
]

{ #category : 'private - grpc' }
OTJaegerRemoteSampler >> executeRequest: aRequest [

	^ requestExecutor
		ifNil: [ self grpcChannel executeUnaryRequest: aRequest ]
		ifNotNil: [ requestExecutor value: aRequest ]
]

{ #category : 'private - grpc' }
OTJaegerRemoteSampler >> grpcChannel [

	^ grpcChannel ifNil: [
		grpcChannel := self grpcChannelClass
			endpoint: (self grpcEndpointClass fromString: self endpoint)
			transport: self grpcTransport ]
]

{ #category : 'private - grpc' }
OTJaegerRemoteSampler >> grpcChannelClass [

	^ self grpcDependencyNamed: #GRPCChannel
]

{ #category : 'private - grpc' }
OTJaegerRemoteSampler >> grpcDependencyNamed: aSymbol [

	^ Smalltalk globals
		at: aSymbol
		ifAbsent: [
			Error signal:
				'OTJaegerRemoteSampler requires grpc-pharo to be loaded (missing '
					, aSymbol asString
					, ')' ]
]

{ #category : 'private - grpc' }
OTJaegerRemoteSampler >> grpcEndpointClass [

	^ self grpcDependencyNamed: #GRPCEndpoint
]

{ #category : 'private - grpc' }
OTJaegerRemoteSampler >> grpcMethodName [

	^ 'GetSamplingStrategy'
]

{ #category : 'private - grpc' }
OTJaegerRemoteSampler >> grpcRequestClass [

	^ self grpcDependencyNamed: #GRPCRequest
]

{ #category : 'private - grpc' }
OTJaegerRemoteSampler >> grpcServiceName [

	^ 'jaeger.api_v2.SamplingManager'
]

{ #category : 'private - grpc' }
OTJaegerRemoteSampler >> grpcTransport [

	^ grpcTransport ifNil: [ grpcTransport := self grpcTransportClass new ]
]

{ #category : 'private - grpc' }
OTJaegerRemoteSampler >> grpcTransport: aTransport [

	grpcTransport := aTransport.
	grpcChannel := nil
]

{ #category : 'private - grpc' }
OTJaegerRemoteSampler >> grpcTransportClass [

	^ self grpcDependencyNamed: #GRPCHTTP2Transport
]

{ #category : 'accessing' }
OTJaegerRemoteSampler >> initialSampler: anOTSampler [

	^ self currentSampler: anOTSampler
]

{ #category : 'initialization' }
OTJaegerRemoteSampler >> initialize [

	super initialize.
	serviceName := ''.
	endpoint := self class defaultEndpoint.
	pollingIntervalMillis := self class defaultPollingIntervalMillis.
	timeoutMillis := self class defaultTimeoutMillis.
	currentSampler := self class defaultInitialSampler.
	clockBlock := [ Time millisecondClockValue ].
	refreshLock := Semaphore forMutualExclusion.
	lastPollTimeMillis := nil.
	warningSink := OTDiagnosticLogger defaultWarningSink.
	pollingSemaphore := Semaphore new.
	pollingProcess := nil.
	shutdownRequested := false
]

{ #category : 'testing' }
OTJaegerRemoteSampler >> isShutdown [

	^ shutdownRequested = true
]

{ #category : 'testing' }
OTJaegerRemoteSampler >> isStarted [

	^ pollingProcess notNil and: [ pollingProcess isTerminated not ]
]

{ #category : 'private - logging' }
OTJaegerRemoteSampler >> noteInvalidResponse: anError [

	| message |
	message := 'OpenTelemetry Jaeger remote sampler received an invalid response: '
		, anError messageText.
	OTDiagnosticLogger current
		handleSuppressedError: anError
		message: message
		fallback: [ self warningSink value: message ]
]

{ #category : 'private - logging' }
OTJaegerRemoteSampler >> noteMissingPayload [

	self warningSink value:
		'OpenTelemetry Jaeger remote sampler received an empty gRPC success response'
]

{ #category : 'private - logging' }
OTJaegerRemoteSampler >> noteRefreshError: anError [

	| message |
	message := 'OpenTelemetry Jaeger remote sampler failed to refresh sampling strategy: '
		, anError messageText.
	OTDiagnosticLogger current
		handleSuppressedError: anError
		message: message
		fallback: [ self warningSink value: message ]
]

{ #category : 'private - logging' }
OTJaegerRemoteSampler >> noteStatus: aStatus [

	| message |
	message := 'OpenTelemetry Jaeger remote sampler refresh failed with gRPC status '
		, aStatus codeName
		, ' ('
		, aStatus code asString
		, ')'.
	aStatus message ifNotNil: [
		message := message , ': ' , aStatus message ].
	self warningSink value: message
]

{ #category : 'accessing' }
OTJaegerRemoteSampler >> pollingIntervalMillis [

	^ pollingIntervalMillis
]

{ #category : 'accessing' }
OTJaegerRemoteSampler >> pollingIntervalMillis: anInteger [

	(anInteger isInteger and: [ anInteger > 0 ]) ifFalse: [
		Error signal:
			'Jaeger remote sampler polling interval must be a positive integer number of milliseconds' ].
	pollingIntervalMillis := anInteger.
	pollingSemaphore signal.
	^ pollingIntervalMillis
]

{ #category : 'private - refreshing' }
OTJaegerRemoteSampler >> pollOnce [

	refreshLock critical: [
		lastPollTimeMillis := self currentTimeMillis.
		self refreshSampler ]
]

{ #category : 'private - refreshing' }
OTJaegerRemoteSampler >> refreshIfNeeded [

	| now previous |
	self isShutdown ifTrue: [ ^ self ].
	self isStarted ifTrue: [ ^ self ].
	now := self currentTimeMillis.
	previous := lastPollTimeMillis.
	(previous notNil and: [ now >= previous and: [ now - previous < self pollingIntervalMillis ] ])
		ifTrue: [ ^ self ].
	refreshLock critical: [
		previous := lastPollTimeMillis.
		(previous notNil and: [ now >= previous and: [ now - previous < self pollingIntervalMillis ] ])
			ifFalse: [
				lastPollTimeMillis := now.
				self refreshSampler ] ]
]

{ #category : 'private - refreshing' }
OTJaegerRemoteSampler >> refreshSampler [

	| payload response status updatedSampler |
	[ response := self executeRequest: self samplingRequest ]
		on: Error
		do: [ :error |
			self noteRefreshError: error.
			^ self ].
	status := response status.
	status isOk ifFalse: [
		self noteStatus: status.
		^ self ].
	payload := response payload.
	payload ifNil: [
		self noteMissingPayload.
		^ self ].
	updatedSampler := [
		OTJaegerSamplingStrategyDecoder samplerFromResponseBytes: payload ]
		on: Error
		do: [ :error |
			self noteInvalidResponse: error.
			^ self ].
	self currentSampler: updatedSampler
]

{ #category : 'private - grpc' }
OTJaegerRemoteSampler >> requestExecutor: aBlockClosure [

	requestExecutor := aBlockClosure
]

{ #category : 'private - refreshing' }
OTJaegerRemoteSampler >> runPollingLoop [

	[ self isShutdown ] whileFalse: [
		[ self pollOnce ]
			on: Error
			do: [ :error | self noteRefreshError: error ].
		self isShutdown ifFalse: [
			pollingSemaphore waitTimeoutMilliseconds: self pollingIntervalMillis ] ]
]

{ #category : 'private - grpc' }
OTJaegerRemoteSampler >> samplingRequest [

	| request |
	request := self grpcRequestClass
		service: self grpcServiceName
		method: self grpcMethodName
		payload: self samplingRequestPayload.
	request timeoutNanos: self timeoutMillis * 1000000.
	^ request
]

{ #category : 'private - grpc' }
OTJaegerRemoteSampler >> samplingRequestPayload [

	| writer |
	writer := OTProtobufWriter withBytes.
	writer
		writeTag: 1 wireType: 2;
		writeString: self serviceName.
	^ writer contents
]

{ #category : 'accessing' }
OTJaegerRemoteSampler >> serviceName [

	^ serviceName
]

{ #category : 'accessing' }
OTJaegerRemoteSampler >> serviceName: aString [

	serviceName := aString
		ifNil: [ '' ]
		ifNotNil: [ aString asString ].
	^ serviceName
]

{ #category : 'sampling' }
OTJaegerRemoteSampler >> shouldSampleIn: aContext traceId: aTraceId name: aString kind: aSpanKind attributes: someAttributes links: someLinks [

	self refreshIfNeeded.
	^ self currentSampler
		shouldSampleIn: aContext
		traceId: aTraceId
		name: aString
		kind: aSpanKind
		attributes: someAttributes
		links: someLinks
]

{ #category : 'lifecycle' }
OTJaegerRemoteSampler >> shutdown [

	self isShutdown ifTrue: [ ^ false ].
	shutdownRequested := true.
	self stopPollingProcess.
	grpcChannel := nil.
	^ true
]

{ #category : 'lifecycle' }
OTJaegerRemoteSampler >> start [

	self ensurePollingProcess
]

{ #category : 'private - refreshing' }
OTJaegerRemoteSampler >> stopPollingProcess [

	pollingProcess ifNotNil: [
		pollingSemaphore signal.
		pollingProcess terminate.
		pollingProcess := nil ]
]

{ #category : 'accessing' }
OTJaegerRemoteSampler >> timeoutMillis [

	^ timeoutMillis
]

{ #category : 'accessing' }
OTJaegerRemoteSampler >> timeoutMillis: anInteger [

	(anInteger isInteger and: [ anInteger > 0 ]) ifFalse: [
		Error signal:
			'Jaeger remote sampler timeout must be a positive integer number of milliseconds' ].
	timeoutMillis := anInteger.
	^ timeoutMillis
]

{ #category : 'accessing' }
OTJaegerRemoteSampler >> warningSink [

	^ warningSink
]

{ #category : 'accessing' }
OTJaegerRemoteSampler >> warningSink: aBlockClosure [

	warningSink := aBlockClosure.
	^ self warningSink
]
