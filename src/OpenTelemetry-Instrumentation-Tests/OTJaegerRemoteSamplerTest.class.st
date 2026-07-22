Class {
	#name : 'OTJaegerRemoteSamplerTest',
	#superclass : 'TestCase',
	#instVars : [
		'currentTime',
		'sampler'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'private' }
OTJaegerRemoteSamplerTest >> assertReader: aReader readsField: aFieldNumber wireType: aWireType [

	| tag |
	tag := aReader readTag.
	self assert: tag first equals: aFieldNumber.
	self assert: tag second equals: aWireType
]

{ #category : 'private' }
OTJaegerRemoteSamplerTest >> grpcOkResponseWithPayload: aByteArray [

	^ OTFakeGRPCResponse
		status: OTFakeGRPCStatus ok
		payload: aByteArray
]

{ #category : 'private' }
OTJaegerRemoteSamplerTest >> perOperationResponseBytesDefaultSamplingProbability: aNumber strategies: associations [

	| writer |
	writer := OTProtobufWriter withBytes.
	writer
		writeTag: 4 wireType: 2;
		writeEmbedded: [ :perOperation |
			perOperation
				writeTag: 1 wireType: 1;
				writeDouble: aNumber.
			associations do: [ :each |
				perOperation
					writeTag: 3 wireType: 2;
					writeEmbedded: [ :operation |
						operation
							writeTag: 1 wireType: 2;
							writeString: each key.
						operation
							writeTag: 2 wireType: 2;
							writeEmbedded: [ :probabilistic |
								probabilistic
									writeTag: 1 wireType: 1;
									writeDouble: each value ] ] ] ].
	^ writer contents
]

{ #category : 'private' }
OTJaegerRemoteSamplerTest >> probabilisticResponseBytesWithRate: aNumber [

	| writer |
	writer := OTProtobufWriter withBytes.
	writer
		writeTag: 1 wireType: 0;
		writeVarint: 0;
		writeTag: 2 wireType: 2;
		writeEmbedded: [ :probabilistic |
			probabilistic
				writeTag: 1 wireType: 1;
				writeDouble: aNumber ].
	^ writer contents
]

{ #category : 'private' }
OTJaegerRemoteSamplerTest >> probabilisticResponseBytesWithoutExplicitStrategyTypeWithRate: aNumber [

	| writer |
	writer := OTProtobufWriter withBytes.
	writer
		writeTag: 2 wireType: 2;
		writeEmbedded: [ :probabilistic |
			probabilistic
				writeTag: 1 wireType: 1;
				writeDouble: aNumber ].
	^ writer contents
]

{ #category : 'private' }
OTJaegerRemoteSamplerTest >> rateLimitingResponseBytesWithMaxTracesPerSecond: anInteger [

	| writer |
	writer := OTProtobufWriter withBytes.
	writer
		writeTag: 1 wireType: 0;
		writeVarint: 1;
		writeTag: 3 wireType: 2;
		writeEmbedded: [ :rateLimiting |
			rateLimiting
				writeTag: 1 wireType: 0;
				writeVarint: anInteger ].
	^ writer contents
]

{ #category : 'private' }
OTJaegerRemoteSamplerTest >> samplingResultForOperationNamed: aString [

	^ sampler
		shouldSampleIn: OTContext new
		traceId: '1234567890abcdef1234567890abcdef'
		name: aString
		kind: OTSpan internal
		attributes: #()
		links: #()
]

{ #category : 'running' }
OTJaegerRemoteSamplerTest >> setUp [

	super setUp.
	currentTime := 1000.
	sampler := OTJaegerRemoteSampler serviceName: 'shopping-cart'.
	sampler
		clockBlock: [ currentTime ];
		initialSampler: OTAlwaysOffSampler new;
		pollingIntervalMillis: 5000;
		timeoutMillis: 4321
]

{ #category : 'running' }
OTJaegerRemoteSamplerTest >> tearDown [

	[ sampler ifNotNil: [ sampler shutdown ] ] ensure: [ super tearDown ]
]

{ #category : 'tests' }
OTJaegerRemoteSamplerTest >> testConcurrentDescriptionIsSafeWhileSamplerRefreshSwapsDelegates [

	| descriptionLock descriptions done errors errorsLock gate pollCount pollCountLock refresherDone workerCount |
	pollCount := 0.
	pollCountLock := Semaphore forMutualExclusion.
	sampler requestExecutor: [ :request |
			| rate |
			pollCountLock critical: [
					pollCount := pollCount + 1.
					rate := pollCount odd
						        ifTrue: [ 0 ]
						        ifFalse: [ 1 ] ].
			self grpcOkResponseWithPayload: (self probabilisticResponseBytesWithRate: rate) ].
	sampler pollOnce.
	descriptions := OrderedCollection new.
	descriptionLock := Semaphore forMutualExclusion.
	errors := OrderedCollection new.
	errorsLock := Semaphore forMutualExclusion.
	gate := Semaphore new.
	done := Semaphore new.
	refresherDone := Semaphore new.
	workerCount := 8.
	[
		gate wait.
		[
			50 timesRepeat: [
					sampler pollOnce.
					Processor yield ] ]
			on: Error
			do: [ :error | errorsLock critical: [ errors add: error ] ].
		refresherDone signal ] forkAt: Processor userBackgroundPriority.
	workerCount timesRepeat: [
			[
				gate wait.
				[
					50 timesRepeat: [
							descriptionLock critical: [ descriptions add: sampler description ].
							Processor yield ] ]
					on: Error
					do: [ :error | errorsLock critical: [ errors add: error ] ].
				done signal ] forkAt: Processor userBackgroundPriority ].
	workerCount + 1 timesRepeat: [ gate signal ].
	workerCount timesRepeat: [ self assert: (done waitTimeoutMilliseconds: 2000) not ].
	self assert: (refresherDone waitTimeoutMilliseconds: 2000) not.
	self assert: errors isEmpty.
	self assert: descriptions size equals: workerCount * 50.
	descriptions do: [ :each |
			self assert: (each beginsWith: 'JaegerRemoteSampler{').
			self assert: (each endsWith: '}') ].
	self assert: pollCount equals: 51
]

{ #category : 'tests' }
OTJaegerRemoteSamplerTest >> testConcurrentShouldSampleIsSafeWhileSamplerRefreshSwapsDelegates [

	| decisionLock decisions done errors errorsLock gate pollCount pollCountLock refresherDone workerCount |
	pollCount := 0.
	pollCountLock := Semaphore forMutualExclusion.
	sampler requestExecutor: [ :request |
			| rate |
			pollCountLock critical: [
					pollCount := pollCount + 1.
					rate := pollCount odd
						        ifTrue: [ 0 ]
						        ifFalse: [ 1 ] ].
			self grpcOkResponseWithPayload: (self probabilisticResponseBytesWithRate: rate) ].
	sampler pollOnce.
	decisions := OrderedCollection new.
	decisionLock := Semaphore forMutualExclusion.
	errors := OrderedCollection new.
	errorsLock := Semaphore forMutualExclusion.
	gate := Semaphore new.
	done := Semaphore new.
	refresherDone := Semaphore new.
	workerCount := 8.
	[
		gate wait.
		[
			50 timesRepeat: [
					sampler pollOnce.
					Processor yield ] ]
			on: Error
			do: [ :error | errorsLock critical: [ errors add: error ] ].
		refresherDone signal ] forkAt: Processor userBackgroundPriority.
	workerCount timesRepeat: [
			[
				| result |
				gate wait.
				[
					50 timesRepeat: [
							result := self samplingResultForOperationNamed: 'checkout'.
							decisionLock critical: [ decisions add: result decision ].
							Processor yield ] ]
					on: Error
					do: [ :error | errorsLock critical: [ errors add: error ] ].
				done signal ] forkAt: Processor userBackgroundPriority ].
	workerCount + 1 timesRepeat: [ gate signal ].
	workerCount timesRepeat: [ self assert: (done waitTimeoutMilliseconds: 2000) not ].
	self assert: (refresherDone waitTimeoutMilliseconds: 2000) not.
	self assert: errors isEmpty.
	self assert: decisions size equals: workerCount * 50.
	decisions do: [ :each | self assert: (#( drop recordAndSample ) includes: each) ].
	self assert: pollCount equals: 51
]

{ #category : 'tests' }
OTJaegerRemoteSamplerTest >> testConcurrentShutdownReturnsTrueOnce [

	| done gate lock results workerCount |
	sampler
		pollingIntervalMillis: 1000;
		requestExecutor: [ :request | self grpcOkResponseWithPayload: (self probabilisticResponseBytesWithRate: 0) ].
	sampler start.
	self waitUntil: [ sampler isStarted ] timeoutMillis: 1000 description: 'Jaeger remote sampler start'.
	results := OrderedCollection new.
	lock := Semaphore forMutualExclusion.
	gate := Semaphore new.
	done := Semaphore new.
	workerCount := 8.
	workerCount timesRepeat: [
			[
				gate wait.
				lock critical: [ results add: sampler shutdown ].
				done signal ] forkAt: Processor userBackgroundPriority ].
	workerCount timesRepeat: [ gate signal ].
	workerCount timesRepeat: [ self assert: (done waitTimeoutMilliseconds: 1000) not ].
	self assert: (results count: [ :each | each = true ]) equals: 1.
	self assert: (results count: [ :each | each = false ]) equals: workerCount - 1.
	self assert: sampler isShutdown.
	self deny: sampler isStarted
]

{ #category : 'tests' }
OTJaegerRemoteSamplerTest >> testConcurrentStartReturnsSinglePollingProcess [

	| done gate lock processes workerCount |
	sampler
		pollingIntervalMillis: 1000;
		requestExecutor: [ :request | self grpcOkResponseWithPayload: (self probabilisticResponseBytesWithRate: 0) ].
	processes := OrderedCollection new.
	lock := Semaphore forMutualExclusion.
	gate := Semaphore new.
	done := Semaphore new.
	workerCount := 8.
	workerCount timesRepeat: [
			[
				| process |
				gate wait.
				process := sampler start.
				lock critical: [ processes add: process ].
				done signal ] forkAt: Processor userBackgroundPriority ].
	workerCount timesRepeat: [ gate signal ].
	workerCount timesRepeat: [ self assert: (done waitTimeoutMilliseconds: 1000) not ].
	self assert: processes size equals: workerCount.
	self assert: processes asSet size equals: 1.
	self assert: sampler isStarted
]

{ #category : 'tests' }
OTJaegerRemoteSamplerTest >> testNonOkGrpcStatusKeepsCurrentSamplerAndWarns [

	| result warnings |
	warnings := OrderedCollection new.
	sampler
		warningSink: [ :message | warnings add: message ];
		requestExecutor: [ :request |
			OTFakeGRPCResponse
				status: (OTFakeGRPCStatus code: 14 message: 'busy')
				payload: nil ].
	result := self samplingResultForOperationNamed: 'checkout'.
	self assert: result isDrop.
	self assert: sampler currentSampler class identicalTo: OTAlwaysOffSampler.
	self assert: warnings size equals: 1.
	self assert: (warnings first includesSubstring: 'UNAVAILABLE').
	self assert: (warnings first includesSubstring: 'busy')
]

{ #category : 'tests' }
OTJaegerRemoteSamplerTest >> testProviderManagedSamplerRefreshesInBackground [

	| provider |
	sampler
		pollingIntervalMillis: 20;
		requestExecutor: [ :request |
			self grpcOkResponseWithPayload: (self probabilisticResponseBytesWithRate: 1) ].
	provider := OTTracerProvider new.
	[
	provider sampler: sampler.
	self
		waitUntil: [ sampler currentSampler class == OTProbabilisticSampler ]
		timeoutMillis: 1000
		description: 'Jaeger remote sampler background refresh' ]
		ensure: [ provider shutdown ]
]

{ #category : 'tests' }
OTJaegerRemoteSamplerTest >> testRateLimitingSamplerUsesInjectedClock [

	| directRateSampler first second third |
	directRateSampler := OTRateLimitingSampler new.
	directRateSampler
		clockBlock: [ currentTime ];
		maxTracesPerSecond: 1.
	first := directRateSampler shouldSample.
	second := directRateSampler shouldSample.
	currentTime := currentTime + 1000.
	third := directRateSampler shouldSample.
	self assert: first.
	self deny: second.
	self assert: third
]

{ #category : 'tests' }
OTJaegerRemoteSamplerTest >> testRefreshHonorsPollingInterval [

	| executionCount |
	executionCount := 0.
	sampler requestExecutor: [ :request |
		executionCount := executionCount + 1.
		self grpcOkResponseWithPayload: (self probabilisticResponseBytesWithRate: 0) ].
	self samplingResultForOperationNamed: 'checkout'.
	self samplingResultForOperationNamed: 'checkout'.
	currentTime := currentTime + 4999.
	self samplingResultForOperationNamed: 'checkout'.
	self assert: executionCount equals: 1.
	currentTime := currentTime + 1.
	self samplingResultForOperationNamed: 'checkout'.
	self assert: executionCount equals: 2
]

{ #category : 'tests' }
OTJaegerRemoteSamplerTest >> testRefreshUpdatesToPerOperationSampler [

	| defaultResult importantResult |
	sampler requestExecutor: [ :request |
		self
			grpcOkResponseWithPayload:
				(self
					perOperationResponseBytesDefaultSamplingProbability: 0
					strategies: { 'important' -> 1 }) ].
	importantResult := self samplingResultForOperationNamed: 'important'.
	defaultResult := self samplingResultForOperationNamed: 'ordinary'.
	self assert: sampler currentSampler class identicalTo: OTPerOperationSampler.
	self assert: importantResult isRecordAndSample.
	self assert: defaultResult isDrop
]

{ #category : 'tests' }
OTJaegerRemoteSamplerTest >> testRefreshUpdatesToProbabilisticSampler [

	| result |
	sampler requestExecutor: [ :request |
		self grpcOkResponseWithPayload: (self probabilisticResponseBytesWithRate: 1) ].
	result := self samplingResultForOperationNamed: 'checkout'.
	self assert: sampler currentSampler class identicalTo: OTProbabilisticSampler.
	self assert: result isRecordAndSample
]

{ #category : 'tests' }
OTJaegerRemoteSamplerTest >> testRefreshUpdatesToProbabilisticSamplerWhenStrategyTypeUsesProtoDefault [

	| result |
	sampler requestExecutor: [ :request |
		self
			grpcOkResponseWithPayload:
				(self probabilisticResponseBytesWithoutExplicitStrategyTypeWithRate: 1) ].
	result := self samplingResultForOperationNamed: 'checkout'.
	self assert: sampler currentSampler class identicalTo: OTProbabilisticSampler.
	self assert: result isRecordAndSample
]

{ #category : 'tests' }
OTJaegerRemoteSamplerTest >> testRefreshUpdatesToRateLimitingSampler [

	| first second |
	sampler requestExecutor: [ :request |
		self grpcOkResponseWithPayload: (self rateLimitingResponseBytesWithMaxTracesPerSecond: 1) ].
	first := self samplingResultForOperationNamed: 'checkout'.
	second := self samplingResultForOperationNamed: 'checkout'.
	self assert: sampler currentSampler class identicalTo: OTRateLimitingSampler.
	self assert: first isRecordAndSample.
	self assert: second isDrop
]

{ #category : 'tests' }
OTJaegerRemoteSamplerTest >> testSamplingRequestEncodesServiceNameAndTimeout [

	| capturedRequest reader |
	sampler requestExecutor: [ :request |
		capturedRequest := request.
		self grpcOkResponseWithPayload: (self probabilisticResponseBytesWithRate: 0) ].
	self samplingResultForOperationNamed: 'checkout'.
	self assert: capturedRequest serviceName equals: 'jaeger.api_v2.SamplingManager'.
	self assert: capturedRequest methodName equals: 'GetSamplingStrategy'.
	self assert: capturedRequest timeoutNanos equals: 4321000000.
	reader := OTProtobufReader on: capturedRequest payload.
	self assertReader: reader readsField: 1 wireType: 2.
	self assert: reader readString equals: 'shopping-cart'.
	self assert: reader atEnd
]

{ #category : 'tests' }
OTJaegerRemoteSamplerTest >> testShutdownStopsBackgroundPolling [

	| executionCount shutdownExecutionCount |
	executionCount := 0.
	sampler
		pollingIntervalMillis: 20;
		requestExecutor: [ :request |
			executionCount := executionCount + 1.
			self grpcOkResponseWithPayload: (self probabilisticResponseBytesWithRate: 0) ].
	sampler start.
	self
		waitUntil: [ executionCount >= 2 ]
		timeoutMillis: 1000
		description: 'multiple Jaeger remote sampler background polls'.
	self assert: sampler shutdown.
	shutdownExecutionCount := executionCount.
	(Delay forMilliseconds: 80) wait.
	self assert: executionCount equals: shutdownExecutionCount
]

{ #category : 'private' }
OTJaegerRemoteSamplerTest >> waitUntil: aBlock timeoutMillis: timeoutMillis description: aString [

	| deadline |
	deadline := Time millisecondClockValue + timeoutMillis.
	[
		aBlock value ifTrue: [ ^ self ].
		Time millisecondClockValue >= deadline ifTrue: [
			self fail: 'Timed out waiting for ', aString ].
		(Delay forMilliseconds: 10) wait ] repeat
]
