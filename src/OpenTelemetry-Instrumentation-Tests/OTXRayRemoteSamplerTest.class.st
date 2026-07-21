Class {
	#name : 'OTXRayRemoteSamplerTest',
	#superclass : 'TestCase',
	#instVars : [
		'currentTime',
		'sampler'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'private' }
OTXRayRemoteSamplerTest >> rulesResponseWithRules: someRules [

	^ OrderedDictionary new
		  at: 'SamplingRuleRecords' put: (someRules collect: [ :each |
						   OrderedDictionary new
							   at: 'SamplingRule' put: each;
							   yourself ]);
		  yourself
]

{ #category : 'private' }
OTXRayRemoteSamplerTest >> samplingResultForAttributes: someAttributes [

	^ self samplingResultForAttributes: someAttributes traceId: '1234567890abcdef1234567890abcdef'
]

{ #category : 'private' }
OTXRayRemoteSamplerTest >> samplingResultForAttributes: someAttributes traceId: aTraceId [

	^ sampler
		  shouldSampleIn: OTContext new
		  traceId: aTraceId
		  name: 'checkout'
		  kind: OTSpan internal
		  attributes: someAttributes
		  links: #(  )
]

{ #category : 'private' }
OTXRayRemoteSamplerTest >> samplingRuleNamed: aString priority: anInteger fixedRate: aNumber reservoirSize: reservoir serviceName: serviceNamePattern serviceType: serviceTypePattern host: hostPattern httpMethod: httpMethodPattern urlPath: urlPathPattern attributes: attributeDictionary [

	^ OrderedDictionary new
		  at: 'RuleName' put: aString;
		  at: 'Priority' put: anInteger;
		  at: 'FixedRate' put: aNumber;
		  at: 'ReservoirSize' put: reservoir;
		  at: 'ServiceName' put: serviceNamePattern;
		  at: 'ServiceType' put: serviceTypePattern;
		  at: 'Host' put: hostPattern;
		  at: 'HTTPMethod' put: httpMethodPattern;
		  at: 'URLPath' put: urlPathPattern;
		  at: 'Attributes' put: attributeDictionary;
		  yourself
]

{ #category : 'running' }
OTXRayRemoteSamplerTest >> setUp [

	super setUp.
	currentTime := 1000.
	sampler := OTXRayRemoteSampler serviceName: 'checkout-service' serviceType: 'aws_ec2'.
	sampler
		clockBlock: [ currentTime ];
		pollingIntervalMillis: 5000;
		timeoutMillis: 4321
]

{ #category : 'private' }
OTXRayRemoteSamplerTest >> targetsResponseWithDocuments: someDocuments [

	^ OrderedDictionary new
		  at: 'SamplingTargetDocuments' put: someDocuments;
		  yourself
]

{ #category : 'tests' }
OTXRayRemoteSamplerTest >> testConcurrentShutdownReturnsTrueOnce [

	| done gate lock results workerCount |
	sampler
		pollingIntervalMillis: 1000;
		requestExecutor: [ :path :payload |
				self rulesResponseWithRules: { (self
							 samplingRuleNamed: 'background-rule'
							 priority: 1
							 fixedRate: 0
							 reservoirSize: 0
							 serviceName: '*'
							 serviceType: '*'
							 host: '*'
							 httpMethod: '*'
							 urlPath: '*'
							 attributes: OrderedDictionary new) } ].
	sampler start.
	self waitUntil: [ sampler isStarted ] timeoutMillis: 1000 description: 'X-Ray remote sampler start'.
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
OTXRayRemoteSamplerTest >> testConcurrentStartReturnsSinglePollingProcess [

	| done gate lock processes workerCount |
	sampler
		pollingIntervalMillis: 1000;
		requestExecutor: [ :path :payload |
				self rulesResponseWithRules: { (self
							 samplingRuleNamed: 'background-rule'
							 priority: 1
							 fixedRate: 0
							 reservoirSize: 0
							 serviceName: '*'
							 serviceType: '*'
							 host: '*'
							 httpMethod: '*'
							 urlPath: '*'
							 attributes: OrderedDictionary new) } ].
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
OTXRayRemoteSamplerTest >> testProviderManagedSamplerRefreshesInBackground [

	| provider |
	sampler
		pollingIntervalMillis: 20;
		requestExecutor: [ :path :payload |
				self rulesResponseWithRules: { (self
							 samplingRuleNamed: 'background-rule'
							 priority: 1
							 fixedRate: 1
							 reservoirSize: 0
							 serviceName: 'checkout-service'
							 serviceType: 'aws_ec2'
							 host: '*'
							 httpMethod: '*'
							 urlPath: '*'
							 attributes: OrderedDictionary new) } ].
	provider := OTTracerProvider new.
	[
		provider sampler: sampler.
		self
			waitUntil: [ (self samplingResultForAttributes: OrderedDictionary new) isRecordAndSample ]
			timeoutMillis: 1000
			description: 'X-Ray remote sampler background refresh' ] ensure: [ provider shutdown ]
]

{ #category : 'tests' }
OTXRayRemoteSamplerTest >> testRefreshLoadsRulesAndMatchesByServiceAndHttpAttributes [

	| matchingAttributes nonMatchingAttributes rulesResponse |
	rulesResponse := self rulesResponseWithRules: {
			                 (self
				                  samplingRuleNamed: 'checkout-rule'
				                  priority: 1
				                  fixedRate: 1
				                  reservoirSize: 0
				                  serviceName: 'checkout-*'
				                  serviceType: 'aws_*'
				                  host: 'api.example.com'
				                  httpMethod: 'GET'
				                  urlPath: '/checkout/*'
				                  attributes: (OrderedDictionary new
						                   at: 'tenant' put: 'gold';
						                   yourself)).
			                 (self
				                  samplingRuleNamed: 'Default'
				                  priority: 10000
				                  fixedRate: 0
				                  reservoirSize: 0
				                  serviceName: '*'
				                  serviceType: '*'
				                  host: '*'
				                  httpMethod: '*'
				                  urlPath: '*'
				                  attributes: OrderedDictionary new) }.
	sampler requestExecutor: [ :path :payload |
			self assert: path equals: '/GetSamplingRules'.
			self assert: payload isEmpty.
			rulesResponse ].
	matchingAttributes := OrderedDictionary new
		                      at: 'http.method' put: 'GET';
		                      at: 'http.target' put: '/checkout/42';
		                      at: 'http.host' put: 'api.example.com';
		                      at: 'tenant' put: 'gold';
		                      yourself.
	nonMatchingAttributes := OrderedDictionary new
		                         at: 'http.method' put: 'POST';
		                         at: 'http.target' put: '/orders/42';
		                         at: 'http.host' put: 'api.example.com';
		                         at: 'tenant' put: 'silver';
		                         yourself.
	self assert: (self samplingResultForAttributes: matchingAttributes) isRecordAndSample.
	currentTime := currentTime + 1.
	self assert: (self samplingResultForAttributes: nonMatchingAttributes) isDrop
]

{ #category : 'tests' }
OTXRayRemoteSamplerTest >> testRefreshReportsStatisticsAndAppliesReturnedQuota [

	| capturedPayload matchingAttributes |
	sampler requestExecutor: [ :path :payload |
			path = '/GetSamplingRules' ifTrue: [
					^ self rulesResponseWithRules: { (self
							   samplingRuleNamed: 'checkout-rule'
							   priority: 1
							   fixedRate: 0
							   reservoirSize: 0
							   serviceName: 'checkout-service'
							   serviceType: 'aws_ec2'
							   host: '*'
							   httpMethod: 'GET'
							   urlPath: '/checkout/*'
							   attributes: OrderedDictionary new) } ].
			path = '/SamplingTargets' ifTrue: [
					capturedPayload := payload.
					^ self targetsResponseWithDocuments: { (OrderedDictionary new
							   at: 'RuleName' put: 'checkout-rule';
							   at: 'FixedRate' put: 0;
							   at: 'ReservoirQuota' put: 1;
							   at: 'ReservoirQuotaTTL' put: (currentTime + 60000) asFloat / 1000.0;
							   yourself) } ].
			self fail: 'Unexpected path: ' , path ].
	matchingAttributes := OrderedDictionary new
		                      at: 'http.method' put: 'GET';
		                      at: 'http.target' put: '/checkout/42';
		                      yourself.
	self assert: (self samplingResultForAttributes: matchingAttributes) isDrop.
	currentTime := currentTime + 1.
	self assert: (self samplingResultForAttributes: matchingAttributes) isDrop.
	currentTime := currentTime + 5000.
	self assert: (self samplingResultForAttributes: matchingAttributes) isRecordAndSample.
	self assert: ((capturedPayload at: 'SamplingStatisticsDocuments') first at: 'RuleName') equals: 'checkout-rule'.
	self assert: ((capturedPayload at: 'SamplingStatisticsDocuments') first at: 'RequestCount') equals: 2.
	self assert: ((capturedPayload at: 'SamplingStatisticsDocuments') first at: 'SampledCount') equals: 0.
	self assert: (self samplingResultForAttributes: matchingAttributes) isDrop
]

{ #category : 'tests' }
OTXRayRemoteSamplerTest >> testRuleBorrowsOncePerSecondBeforeQuotaAssignment [

	sampler requestExecutor: [ :path :payload |
			self rulesResponseWithRules: { (self
					 samplingRuleNamed: 'Default'
					 priority: 10000
					 fixedRate: 0
					 reservoirSize: 1
					 serviceName: '*'
					 serviceType: '*'
					 host: '*'
					 httpMethod: '*'
					 urlPath: '*'
					 attributes: OrderedDictionary new) } ].
	self assert: (self samplingResultForAttributes: OrderedDictionary new) isRecordAndSample.
	self assert: (self samplingResultForAttributes: OrderedDictionary new) isDrop.
	currentTime := currentTime + 1000.
	self assert: (self samplingResultForAttributes: OrderedDictionary new) isRecordAndSample
]

{ #category : 'tests' }
OTXRayRemoteSamplerTest >> testShutdownStopsBackgroundPolling [

	| executionCount shutdownExecutionCount |
	executionCount := 0.
	sampler
		pollingIntervalMillis: 20;
		requestExecutor: [ :path :payload |
				executionCount := executionCount + 1.
				self rulesResponseWithRules: { (self
							 samplingRuleNamed: 'background-rule'
							 priority: 1
							 fixedRate: 0
							 reservoirSize: 0
							 serviceName: '*'
							 serviceType: '*'
							 host: '*'
							 httpMethod: '*'
							 urlPath: '*'
							 attributes: OrderedDictionary new) } ].
	sampler start.
	self waitUntil: [ executionCount >= 2 ] timeoutMillis: 1000 description: 'multiple X-Ray remote sampler background polls'.
	self assert: sampler shutdown.
	shutdownExecutionCount := executionCount.
	(Delay forMilliseconds: 80) wait.
	self assert: executionCount equals: shutdownExecutionCount
]

{ #category : 'private' }
OTXRayRemoteSamplerTest >> waitUntil: aBlock timeoutMillis: timeoutMillis description: aString [

	| deadline |
	deadline := Time millisecondClockValue + timeoutMillis.
	[
		aBlock value ifTrue: [ ^ self ].
		Time millisecondClockValue >= deadline ifTrue: [ self fail: 'Timed out waiting for ' , aString ].
		(Delay forMilliseconds: 10) wait ] repeat
]
