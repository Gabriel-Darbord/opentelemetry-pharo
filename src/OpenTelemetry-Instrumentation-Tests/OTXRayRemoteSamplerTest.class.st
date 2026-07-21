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
