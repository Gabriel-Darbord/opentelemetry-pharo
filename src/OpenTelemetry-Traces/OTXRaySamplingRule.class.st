"
I represent one AWS X-Ray sampling rule together with its local runtime state.
I match requests, track reservoir usage, and produce sampling decisions.
"
Class {
	#name : 'OTXRaySamplingRule',
	#superclass : 'Object',
	#instVars : [
		'ruleName',
		'priority',
		'fixedRate',
		'reservoirSize',
		'serviceNamePattern',
		'serviceTypePattern',
		'hostPattern',
		'httpMethodPattern',
		'urlPathPattern',
		'resourceArnPattern',
		'attributes',
		'reservoirQuota',
		'reservoirQuotaTtlMillis',
		'requestCount',
		'sampledCount',
		'borrowCount',
		'lastBorrowSecond',
		'probabilisticSampler',
		'stateLock'
	],
	#category : 'OpenTelemetry-Traces',
	#package : 'OpenTelemetry-Traces'
}

{ #category : 'instance creation' }
OTXRaySamplingRule class >> defaultRule [

	^ self new
		  ruleName: 'Default';
		  priority: 10000;
		  fixedRate: 0.05;
		  reservoirSize: 1;
		  yourself
]

{ #category : 'instance creation' }
OTXRaySamplingRule class >> fromDictionary: aDictionary [

	| attributeDictionary rule |
	rule := self new.
	rule
		ruleName: (aDictionary at: 'RuleName' ifAbsent: [ 'Default' ]);
		priority: (aDictionary at: 'Priority' ifAbsent: [ 10000 ]);
		fixedRate: (aDictionary at: 'FixedRate' ifAbsent: [ 0 ]);
		reservoirSize: (aDictionary at: 'ReservoirSize' ifAbsent: [ 0 ]);
		resourceArnPattern: (aDictionary at: 'ResourceARN' ifAbsent: [ '*' ]);
		serviceNamePattern: (aDictionary at: 'ServiceName' ifAbsent: [ '*' ]);
		serviceTypePattern: (aDictionary at: 'ServiceType' ifAbsent: [ '*' ]);
		hostPattern: (aDictionary at: 'Host' ifAbsent: [ '*' ]);
		httpMethodPattern: (aDictionary at: 'HTTPMethod' ifAbsent: [ '*' ]);
		urlPathPattern: (aDictionary at: 'URLPath' ifAbsent: [ '*' ]).
	attributeDictionary := aDictionary at: 'Attributes' ifAbsent: [ OrderedDictionary new ].
	rule attributes: attributeDictionary.
	^ rule
]

{ #category : 'updating' }
OTXRaySamplingRule >> adoptRuntimeStateFrom: anotherRule [

	| runtimeState |
	anotherRule ifNil: [ ^ self ].
	runtimeState := anotherRule runtimeState.
	stateLock critical: [
			reservoirQuota := runtimeState at: 'reservoirQuota'.
			reservoirQuotaTtlMillis := runtimeState at: 'reservoirQuotaTtlMillis'.
			requestCount := runtimeState at: 'requestCount'.
			sampledCount := runtimeState at: 'sampledCount'.
			borrowCount := runtimeState at: 'borrowCount'.
			lastBorrowSecond := runtimeState at: 'lastBorrowSecond' ]
]

{ #category : 'accessing' }
OTXRaySamplingRule >> attributes [

	^ attributes copy
]

{ #category : 'accessing' }
OTXRaySamplingRule >> attributes: aDictionary [

	attributes := aDictionary ifNil: [ OrderedDictionary new ] ifNotNil: [ aDictionary asOrderedDictionary ]
]

{ #category : 'statistics' }
OTXRaySamplingRule >> clearStatistics [

	stateLock critical: [
			requestCount := 0.
			sampledCount := 0.
			borrowCount := 0 ]
]

{ #category : 'accessing' }
OTXRaySamplingRule >> description [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'XRaySamplingRule{';
				  nextPutAll: ruleName;
				  nextPutAll: ', priority=';
				  print: priority;
				  nextPutAll: ', fixedRate=';
				  print: fixedRate;
				  nextPutAll: ', reservoirSize=';
				  print: reservoirSize;
				  nextPut: $} ]
]

{ #category : 'accessing' }
OTXRaySamplingRule >> fixedRate [

	^ fixedRate
]

{ #category : 'accessing' }
OTXRaySamplingRule >> fixedRate: aNumber [

	fixedRate := aNumber asFloat.
	probabilisticSampler := OTSampler probabilityOrAlwaysOff: fixedRate
]

{ #category : 'testing' }
OTXRaySamplingRule >> hasStatistics [

	^ stateLock critical: [ requestCount > 0 ]
]

{ #category : 'private - matching' }
OTXRaySamplingRule >> hostFromAttributes: someAttributes [

	^ {
		  (self stringAttributeNamed: 'http.host' in: someAttributes).
		  (self stringAttributeNamed: 'server.address' in: someAttributes).
		  (self stringAttributeNamed: 'url.domain' in: someAttributes).
		  (self hostFromUrlString: (self stringAttributeNamed: 'http.url' in: someAttributes)).
		  (self hostFromUrlString: (self stringAttributeNamed: 'url.full' in: someAttributes)) }
		  detect: [ :each | each notNil and: [ each asString isNotEmpty ] ]
		  ifNone: [ nil ]
]

{ #category : 'private - matching' }
OTXRaySamplingRule >> hostFromUrlString: aString [

	| hostPort pathStart schemeStart start |
	aString ifNil: [ ^ nil ].
	aString isEmpty ifTrue: [ ^ nil ].
	schemeStart := aString findString: '://'.
	start := schemeStart = 0
		         ifTrue: [ 1 ]
		         ifFalse: [ schemeStart + 3 ].
	pathStart := aString indexOf: $/ startingAt: start.
	hostPort := pathStart = 0
		            ifTrue: [ aString copyFrom: start to: aString size ]
		            ifFalse: [ aString copyFrom: start to: pathStart - 1 ].
	hostPort isEmpty ifTrue: [ ^ nil ].
	^ (hostPort includes: $:)
		  ifTrue: [ hostPort copyUpTo: $: ]
		  ifFalse: [ hostPort ]
]

{ #category : 'accessing' }
OTXRaySamplingRule >> hostPattern: aString [

	hostPattern := aString asString
]

{ #category : 'accessing' }
OTXRaySamplingRule >> httpMethodPattern: aString [

	httpMethodPattern := aString asString
]

{ #category : 'initialization' }
OTXRaySamplingRule >> initialize [

	super initialize.
	stateLock := Semaphore forMutualExclusion.
	ruleName := 'Default'.
	priority := 10000.
	fixedRate := 0.05.
	reservoirSize := 1.
	serviceNamePattern := '*'.
	serviceTypePattern := '*'.
	hostPattern := '*'.
	httpMethodPattern := '*'.
	urlPathPattern := '*'.
	resourceArnPattern := '*'.
	attributes := OrderedDictionary new.
	probabilisticSampler := OTSampler probabilityOrAlwaysOff: fixedRate.
	reservoirQuota := nil.
	reservoirQuotaTtlMillis := nil.
	requestCount := 0.
	sampledCount := 0.
	borrowCount := 0.
	lastBorrowSecond := nil
]

{ #category : 'private - matching' }
OTXRaySamplingRule >> matchesRequestAttributes: someAttributes [

	^ (self matchesValue: (self hostFromAttributes: someAttributes) pattern: hostPattern) and: [
			  (self matchesValue: (self requestMethodFromAttributes: someAttributes) pattern: httpMethodPattern) and: [
					  (self matchesValue: (self pathFromAttributes: someAttributes) pattern: urlPathPattern) and: [
						  (self matchesValue: '' pattern: resourceArnPattern) and: [ self matchesRuleAttributesIn: someAttributes ] ] ] ]
]

{ #category : 'private - matching' }
OTXRaySamplingRule >> matchesRuleAttributesIn: someAttributes [

	^ attributes associations allSatisfy: [ :each |
		  self matchesValue: (self stringAttributeNamed: each key asString in: someAttributes) pattern: each value asString ]
]

{ #category : 'matching' }
OTXRaySamplingRule >> matchesServiceName: aServiceName serviceType: anotherString attributes: someAttributes [

	^ (self matchesValue: aServiceName pattern: serviceNamePattern) and: [
		  (self matchesValue: anotherString pattern: serviceTypePattern) and: [ self matchesRequestAttributes: someAttributes ] ]
]

{ #category : 'private - matching' }
OTXRaySamplingRule >> matchesValue: anObject pattern: aPattern [

	| pattern value |
	pattern := aPattern ifNil: [ '*' ] ifNotNil: [ aPattern asString ].
	pattern = '*' ifTrue: [ ^ true ].
	value := anObject ifNil: [ '' ] ifNotNil: [ anObject asString ].
	^ self
		  wildcardPattern: pattern
		  patternIndex: 1
		  matchesValue: value
		  valueIndex: 1
]

{ #category : 'private - matching' }
OTXRaySamplingRule >> pathFromAttributes: someAttributes [

	^ {
		  (self stringAttributeNamed: 'http.target' in: someAttributes).
		  (self stringAttributeNamed: 'url.path' in: someAttributes).
		  (self pathFromUrlString: (self stringAttributeNamed: 'http.url' in: someAttributes)).
		  (self pathFromUrlString: (self stringAttributeNamed: 'url.full' in: someAttributes)) }
		  detect: [ :each | each notNil and: [ each asString isNotEmpty ] ]
		  ifNone: [ nil ]
]

{ #category : 'private - matching' }
OTXRaySamplingRule >> pathFromUrlString: aString [

	| fragmentIndex path pathStart queryIndex schemeStart start |
	aString ifNil: [ ^ nil ].
	aString isEmpty ifTrue: [ ^ nil ].
	schemeStart := aString findString: '://'.
	start := schemeStart = 0
		         ifTrue: [ 1 ]
		         ifFalse: [ schemeStart + 3 ].
	pathStart := aString indexOf: $/ startingAt: start.
	pathStart = 0 ifTrue: [ ^ '/' ].
	path := aString copyFrom: pathStart to: aString size.
	queryIndex := path indexOf: $?.
	queryIndex > 0 ifTrue: [ path := path copyFrom: 1 to: queryIndex - 1 ].
	fragmentIndex := path indexOf: $#.
	fragmentIndex > 0 ifTrue: [ path := path copyFrom: 1 to: fragmentIndex - 1 ].
	^ path ifEmpty: [ '/' ] ifNotEmpty: [ path ]
]

{ #category : 'accessing' }
OTXRaySamplingRule >> priority [

	^ priority
]

{ #category : 'accessing' }
OTXRaySamplingRule >> priority: anInteger [

	priority := anInteger
]

{ #category : 'private - sampling' }
OTXRaySamplingRule >> quotaActiveAt: nowMillis [

	^ reservoirQuota notNil and: [
		  reservoirQuota > 0 and: [ reservoirQuotaTtlMillis notNil and: [ nowMillis <= reservoirQuotaTtlMillis ] ] ]
]

{ #category : 'private - matching' }
OTXRaySamplingRule >> requestMethodFromAttributes: someAttributes [

	^ {
		  (self stringAttributeNamed: 'http.method' in: someAttributes).
		  (self stringAttributeNamed: 'http.request.method' in: someAttributes) }
		  detect: [ :each | each notNil and: [ each asString isNotEmpty ] ]
		  ifNone: [ nil ]
]

{ #category : 'accessing' }
OTXRaySamplingRule >> reservoirSize [

	^ reservoirSize
]

{ #category : 'accessing' }
OTXRaySamplingRule >> reservoirSize: anInteger [

	reservoirSize := anInteger
]

{ #category : 'accessing' }
OTXRaySamplingRule >> resourceArnPattern: aString [

	resourceArnPattern := aString asString
]

{ #category : 'accessing' }
OTXRaySamplingRule >> ruleName [

	^ ruleName
]

{ #category : 'accessing' }
OTXRaySamplingRule >> ruleName: aString [

	ruleName := aString asString
]

{ #category : 'private - updating' }
OTXRaySamplingRule >> runtimeState [

	^ stateLock critical: [
			  OrderedDictionary new
				  at: 'reservoirQuota' put: reservoirQuota;
				  at: 'reservoirQuotaTtlMillis' put: reservoirQuotaTtlMillis;
				  at: 'requestCount' put: requestCount;
				  at: 'sampledCount' put: sampledCount;
				  at: 'borrowCount' put: borrowCount;
				  at: 'lastBorrowSecond' put: lastBorrowSecond;
				  yourself ]
]

{ #category : 'private - sampling' }
OTXRaySamplingRule >> sampleUsingFixedRateTraceId: aTraceId [

	^ (probabilisticSampler
		   shouldSampleIn: nil
		   traceId: aTraceId
		   name: ruleName
		   kind: OTSpan internal
		   attributes: #(  )
		   links: #(  )) isRecordAndSample
]

{ #category : 'accessing' }
OTXRaySamplingRule >> serviceNamePattern: aString [

	serviceNamePattern := aString asString
]

{ #category : 'accessing' }
OTXRaySamplingRule >> serviceTypePattern: aString [

	serviceTypePattern := aString asString
]

{ #category : 'private - sampling' }
OTXRaySamplingRule >> shouldBorrowAt: nowMillis [

	| second |
	reservoirSize > 0 ifFalse: [ ^ false ].
	second := nowMillis // 1000.
	lastBorrowSecond = second ifTrue: [ ^ false ].
	lastBorrowSecond := second.
	^ true
]

{ #category : 'sampling' }
OTXRaySamplingRule >> shouldSampleTraceId: aTraceId atTimeMillis: nowMillis [

	^ stateLock critical: [
			  | borrowed sampled |
			  requestCount := requestCount + 1.
			  borrowed := false.
			  sampled := (self quotaActiveAt: nowMillis)
				             ifTrue: [
						             reservoirQuota := reservoirQuota - 1.
						             true ]
				             ifFalse: [
						             (self shouldBorrowAt: nowMillis)
							             ifTrue: [
									             borrowed := true.
									             true ]
							             ifFalse: [ self sampleUsingFixedRateTraceId: aTraceId ] ].
			  sampled ifTrue: [ sampledCount := sampledCount + 1 ].
			  borrowed ifTrue: [ borrowCount := borrowCount + 1 ].
			  sampled ]
]

{ #category : 'statistics' }
OTXRaySamplingRule >> statisticsDocumentForClientId: aString timestampSeconds: aNumber [

	^ stateLock critical: [
			  requestCount = 0 ifTrue: [ ^ nil ].
			  OrderedDictionary new
				  at: 'ClientID' put: aString;
				  at: 'RuleName' put: ruleName;
				  at: 'RequestCount' put: requestCount;
				  at: 'SampledCount' put: sampledCount;
				  at: 'BorrowCount' put: borrowCount;
				  at: 'Timestamp' put: aNumber;
				  yourself ]
]

{ #category : 'private - matching' }
OTXRaySamplingRule >> stringAttributeNamed: aString in: someAttributes [

	someAttributes ifNil: [ ^ nil ].
	^ someAttributes at: aString ifAbsent: [ nil ]
]

{ #category : 'updating' }
OTXRaySamplingRule >> updateFromTargetDictionary: aDictionary [

	stateLock critical: [
			aDictionary at: 'FixedRate' ifPresent: [ :value | self fixedRate: value ].
			reservoirQuota := aDictionary at: 'ReservoirQuota' ifAbsent: [ nil ].
			aDictionary
				at: 'ReservoirQuotaTTL'
				ifPresent: [ :value | reservoirQuotaTtlMillis := value asFloat * 1000 ]
				ifAbsent: [ reservoirQuotaTtlMillis := nil ] ]
]

{ #category : 'accessing' }
OTXRaySamplingRule >> urlPathPattern: aString [

	urlPathPattern := aString asString
]

{ #category : 'private - matching' }
OTXRaySamplingRule >> wildcardPattern: aPattern patternIndex: patternIndex matchesValue: aString valueIndex: valueIndex [

	| character nextValueIndex |
	patternIndex > aPattern size ifTrue: [ ^ valueIndex > aString size ].
	character := aPattern at: patternIndex.
	character = $* ifTrue: [
			patternIndex = aPattern size ifTrue: [ ^ true ].
			nextValueIndex := valueIndex.
			[ nextValueIndex <= aString size + 1 ] whileTrue: [
					(self
						 wildcardPattern: aPattern
						 patternIndex: patternIndex + 1
						 matchesValue: aString
						 valueIndex: nextValueIndex) ifTrue: [ ^ true ].
					nextValueIndex := nextValueIndex + 1 ].
			^ false ].
	valueIndex > aString size ifTrue: [ ^ false ].
	(character = $? or: [ character = (aString at: valueIndex) ]) ifFalse: [ ^ false ].
	^ self
		  wildcardPattern: aPattern
		  patternIndex: patternIndex + 1
		  matchesValue: aString
		  valueIndex: valueIndex + 1
]
