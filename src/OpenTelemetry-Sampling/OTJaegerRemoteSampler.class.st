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
		'shutdownRequested',
		'stateLock'
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

	| resolver |
	resolver := self grpcDependencyResolver.
	^ #( GRPCChannel GRPCEndpoint GRPCRequest GRPCHTTP2Transport ) allSatisfy: [ :each |
		  (resolver value: each) notNil ]
]

{ #category : 'private - grpc' }
OTJaegerRemoteSampler class >> grpcDependencyResolver [

	^ OTClassStateStore
		  valueAt: #otGrpcDependencyResolver
		  forClass: self
		  ifAbsent: [ [ :symbol | Smalltalk globals at: symbol ifAbsent: [ nil ] ] ]
]

{ #category : 'private - grpc' }
OTJaegerRemoteSampler class >> grpcDependencyResolver: aBlockOrNil [

	aBlockOrNil
		ifNil: [ OTClassStateStore removeValueAt: #otGrpcDependencyResolver forClass: self ifAbsent: [ ] ]
		ifNotNil: [ OTClassStateStore valueAt: #otGrpcDependencyResolver forClass: self put: aBlockOrNil ].
	^ self grpcDependencyResolver
]

{ #category : 'private' }
OTJaegerRemoteSampler class >> normalizedEndpoint: aString [

	| normalizedValue url endpointString |
	normalizedValue := aString asString trimBoth.
	normalizedValue isEmpty ifTrue: [ Error signal: 'Jaeger remote sampler endpoint must not be empty' ].
	url := [ ZnUrl fromString: normalizedValue ]
		       on: Error
		       do: [ Error signal: 'Jaeger remote sampler endpoint must be an absolute http(s) URL' ].
	((#( 'http' 'https' ) includes: url scheme) and: [ url host notNil and: [ url host isNotEmpty ] ]) ifFalse: [
		Error signal: 'Jaeger remote sampler endpoint must be an absolute http(s) URL' ].
	url port ifNil: [ Error signal: 'Jaeger remote sampler endpoint must include an explicit port' ].
	endpointString := url printString.
	^ endpointString
		  ifNotEmpty: [
				  endpointString last = $/
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

	stateLock critical: [ clockBlock := aBlockClosure ]
]

{ #category : 'accessing' }
OTJaegerRemoteSampler >> currentSampler [

	^ stateLock critical: [ currentSampler ]
]

{ #category : 'accessing' }
OTJaegerRemoteSampler >> currentSampler: anOTSampler [

	anOTSampler ifNil: [ Error signal: 'Jaeger remote sampler requires a delegate sampler' ].
	stateLock critical: [ currentSampler := anOTSampler ].
	^ anOTSampler
]

{ #category : 'private' }
OTJaegerRemoteSampler >> currentTimeMillis [

	| block |
	block := stateLock critical: [ clockBlock ].
	^ block value
]

{ #category : 'accessing' }
OTJaegerRemoteSampler >> description [

	^ 'JaegerRemoteSampler{' , self currentSampler description , '}'
]

{ #category : 'private - grpc' }
OTJaegerRemoteSampler >> endpoint [

	^ stateLock critical: [ endpoint ]
]

{ #category : 'private - grpc' }
OTJaegerRemoteSampler >> endpoint: aString [

	| normalizedEndpoint |
	normalizedEndpoint := self class normalizedEndpoint: aString.
	stateLock critical: [
			endpoint := normalizedEndpoint.
			grpcChannel := nil ].
	^ normalizedEndpoint
]

{ #category : 'private - refreshing' }
OTJaegerRemoteSampler >> ensurePollingProcess [

	| process |
	process := stateLock critical: [
			           shutdownRequested
				           ifTrue: [ nil ]
				           ifFalse: [
						           (pollingProcess notNil and: [ pollingProcess isTerminated not ])
							           ifTrue: [ pollingProcess ]
							           ifFalse: [ pollingProcess := [ self runPollingLoop ] forkAt: Processor userBackgroundPriority ] ] ].
	^ process
]

{ #category : 'private - grpc' }
OTJaegerRemoteSampler >> executeRequest: aRequest [

	| executor |
	executor := stateLock critical: [ requestExecutor ].
	^ executor ifNil: [ self grpcChannel executeUnaryRequest: aRequest ] ifNotNil: [ executor value: aRequest ]
]

{ #category : 'private - grpc' }
OTJaegerRemoteSampler >> grpcChannel [

	^ stateLock critical: [
			  grpcTransport ifNil: [ grpcTransport := self grpcTransportClass new ].
			  grpcChannel ifNil: [
				  grpcChannel := self grpcChannelClass endpoint: (self grpcEndpointClass fromString: endpoint) transport: grpcTransport ].
			  grpcChannel ]
]

{ #category : 'private - grpc' }
OTJaegerRemoteSampler >> grpcChannelClass [

	^ self grpcDependencyNamed: #GRPCChannel
]

{ #category : 'private - grpc' }
OTJaegerRemoteSampler >> grpcDependencyNamed: aSymbol [

	| dependency |
	dependency := self class grpcDependencyResolver value: aSymbol.
	^ dependency
		  ifNil: [ Error signal: 'OTJaegerRemoteSampler requires grpc-pharo to be loaded (missing ' , aSymbol asString , ')' ]
		  ifNotNil: [ dependency ]
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

	^ stateLock critical: [ grpcTransport ifNil: [ grpcTransport := self grpcTransportClass new ] ]
]

{ #category : 'private - grpc' }
OTJaegerRemoteSampler >> grpcTransport: aTransport [

	stateLock critical: [
			grpcTransport := aTransport.
			grpcChannel := nil ].
	^ aTransport
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
	stateLock := Semaphore forMutualExclusion.
	lastPollTimeMillis := nil.
	warningSink := OTDiagnosticLogger defaultWarningSink.
	pollingSemaphore := Semaphore new.
	pollingProcess := nil.
	shutdownRequested := false
]

{ #category : 'testing' }
OTJaegerRemoteSampler >> isShutdown [

	^ stateLock critical: [ shutdownRequested = true ]
]

{ #category : 'testing' }
OTJaegerRemoteSampler >> isStarted [

	^ stateLock critical: [ pollingProcess notNil and: [ pollingProcess isTerminated not ] ]
]

{ #category : 'private - logging' }
OTJaegerRemoteSampler >> noteInvalidResponse: anError [

	| message |
	message := 'OpenTelemetry Jaeger remote sampler received an invalid response: ' , anError messageText.
	OTDiagnosticLogger current handleSuppressedError: anError message: message fallback: [ self warningSink value: message ]
]

{ #category : 'private - logging' }
OTJaegerRemoteSampler >> noteMissingPayload [

	self warningSink value: 'OpenTelemetry Jaeger remote sampler received an empty gRPC success response'
]

{ #category : 'private - logging' }
OTJaegerRemoteSampler >> noteRefreshError: anError [

	| message |
	message := 'OpenTelemetry Jaeger remote sampler failed to refresh sampling strategy: ' , anError messageText.
	OTDiagnosticLogger current handleSuppressedError: anError message: message fallback: [ self warningSink value: message ]
]

{ #category : 'private - logging' }
OTJaegerRemoteSampler >> noteStatus: aStatus [

	| message |
	message := 'OpenTelemetry Jaeger remote sampler refresh failed with gRPC status ' , aStatus codeName , ' ('
	           , aStatus code asString , ')'.
	aStatus message ifNotNil: [ message := message , ': ' , aStatus message ].
	self warningSink value: message
]

{ #category : 'private - refreshing' }
OTJaegerRemoteSampler >> pollOnce [

	refreshLock critical: [
			lastPollTimeMillis := self currentTimeMillis.
			self refreshSampler ]
]

{ #category : 'accessing' }
OTJaegerRemoteSampler >> pollingIntervalMillis [

	^ stateLock critical: [ pollingIntervalMillis ]
]

{ #category : 'accessing' }
OTJaegerRemoteSampler >> pollingIntervalMillis: anInteger [

	(anInteger isInteger and: [ anInteger > 0 ]) ifFalse: [
		Error signal: 'Jaeger remote sampler polling interval must be a positive integer number of milliseconds' ].
	stateLock critical: [ pollingIntervalMillis := anInteger ].
	pollingSemaphore signal.
	^ anInteger
]

{ #category : 'private - refreshing' }
OTJaegerRemoteSampler >> refreshIfNeeded [

	| now previous |
	self isShutdown ifTrue: [ ^ self ].
	self isStarted ifTrue: [ ^ self ].
	now := self currentTimeMillis.
	previous := lastPollTimeMillis.
	(previous notNil and: [ now >= previous and: [ now - previous < self pollingIntervalMillis ] ]) ifTrue: [ ^ self ].
	refreshLock critical: [
			previous := lastPollTimeMillis.
			(previous notNil and: [ now >= previous and: [ now - previous < self pollingIntervalMillis ] ]) ifFalse: [
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
	updatedSampler := [ OTJaegerSamplingStrategyDecoder samplerFromResponseBytes: payload ]
		                  on: Error
		                  do: [ :error |
				                  self noteInvalidResponse: error.
				                  ^ self ].
	self currentSampler: updatedSampler
]

{ #category : 'private - grpc' }
OTJaegerRemoteSampler >> requestExecutor: aBlockClosure [

	stateLock critical: [ requestExecutor := aBlockClosure ]
]

{ #category : 'private - refreshing' }
OTJaegerRemoteSampler >> runPollingLoop [

	[ self isShutdown ] whileFalse: [
			[ self pollOnce ]
				on: Error
				do: [ :error | self noteRefreshError: error ].
			self isShutdown ifFalse: [ pollingSemaphore waitTimeoutMilliseconds: self pollingIntervalMillis ] ]
]

{ #category : 'private - grpc' }
OTJaegerRemoteSampler >> samplingRequest [

	| request |
	request := self grpcRequestClass service: self grpcServiceName method: self grpcMethodName payload: self samplingRequestPayload.
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

	^ stateLock critical: [ serviceName ]
]

{ #category : 'accessing' }
OTJaegerRemoteSampler >> serviceName: aString [

	| normalizedServiceName |
	normalizedServiceName := aString ifNil: [ '' ] ifNotNil: [ aString asString ].
	stateLock critical: [ serviceName := normalizedServiceName ].
	^ normalizedServiceName
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

	| shouldShutdown |
	shouldShutdown := stateLock critical: [
			                  shutdownRequested
				                  ifTrue: [ false ]
				                  ifFalse: [
						                  shutdownRequested := true.
						                  grpcChannel := nil.
						                  true ] ].
	shouldShutdown ifFalse: [ ^ false ].
	self stopPollingProcess.
	^ true
]

{ #category : 'lifecycle' }
OTJaegerRemoteSampler >> start [

	self ensurePollingProcess
]

{ #category : 'private - refreshing' }
OTJaegerRemoteSampler >> stopPollingProcess [

	| process |
	process := stateLock critical: [
			           | captured |
			           captured := pollingProcess.
			           pollingProcess := nil.
			           captured ].
	process ifNotNil: [
			pollingSemaphore signal.
			process terminate ]
]

{ #category : 'accessing' }
OTJaegerRemoteSampler >> timeoutMillis [

	^ stateLock critical: [ timeoutMillis ]
]

{ #category : 'accessing' }
OTJaegerRemoteSampler >> timeoutMillis: anInteger [

	(anInteger isInteger and: [ anInteger > 0 ]) ifFalse: [
		Error signal: 'Jaeger remote sampler timeout must be a positive integer number of milliseconds' ].
	stateLock critical: [ timeoutMillis := anInteger ].
	^ anInteger
]

{ #category : 'accessing' }
OTJaegerRemoteSampler >> warningSink [

	^ stateLock critical: [ warningSink ]
]

{ #category : 'accessing' }
OTJaegerRemoteSampler >> warningSink: aBlockClosure [

	stateLock critical: [ warningSink := aBlockClosure ].
	^ aBlockClosure
]
