Class {
	#name : 'OTXRayRemoteSampler',
	#superclass : 'OTSampler',
	#instVars : [
		'serviceName',
		'serviceType',
		'endpoint',
		'pollingIntervalMillis',
		'timeoutMillis',
		'rules',
		'requestExecutor',
		'clockBlock',
		'lastPollTimeMillis',
		'refreshLock',
		'warningSink',
		'pollingProcess',
		'pollingSemaphore',
		'shutdownRequested',
		'stateLock',
		'clientId'
	],
	#category : 'OpenTelemetry-Traces',
	#package : 'OpenTelemetry-Traces'
}

{ #category : 'defaults' }
OTXRayRemoteSampler class >> defaultEndpoint [

	^ 'http://localhost:2000'
]

{ #category : 'defaults' }
OTXRayRemoteSampler class >> defaultPollingIntervalMillis [

	^ 300000
]

{ #category : 'defaults' }
OTXRayRemoteSampler class >> defaultTimeoutMillis [

	^ 10000
]

{ #category : 'private' }
OTXRayRemoteSampler class >> normalizedEndpoint: aString [

	| endpointString normalizedValue url |
	normalizedValue := aString asString trimBoth.
	normalizedValue isEmpty ifTrue: [ Error signal: 'X-Ray remote sampler endpoint must not be empty' ].
	url := [ ZnUrl fromString: normalizedValue ]
		       on: Error
		       do: [ Error signal: 'X-Ray remote sampler endpoint must be an absolute http(s) URL' ].
	((#( 'http' 'https' ) includes: url scheme) and: [ url host notNil and: [ url host isNotEmpty ] ]) ifFalse: [
		Error signal: 'X-Ray remote sampler endpoint must be an absolute http(s) URL' ].
	url port ifNil: [ Error signal: 'X-Ray remote sampler endpoint must include an explicit port' ].
	endpointString := url printString.
	^ endpointString ifEmpty: [ endpointString ] ifNotEmpty: [
			  endpointString last = $/
				  ifTrue: [ endpointString allButLast ]
				  ifFalse: [ endpointString ] ]
]

{ #category : 'instance creation' }
OTXRayRemoteSampler class >> serviceName: aString serviceType: anotherString [

	^ self new
		  serviceName: aString;
		  serviceType: anotherString;
		  yourself
]

{ #category : 'private - refreshing' }
OTXRayRemoteSampler >> clearRuleStatistics [

	self rules do: [ :each | each clearStatistics ]
]

{ #category : 'accessing' }
OTXRayRemoteSampler >> clockBlock: aBlockClosure [

	stateLock critical: [ clockBlock := aBlockClosure ]
]

{ #category : 'private' }
OTXRayRemoteSampler >> currentTimeMillis [

	^ stateLock critical: [ clockBlock value ]
]

{ #category : 'accessing' }
OTXRayRemoteSampler >> description [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'XRayRemoteSampler{serviceName=';
				  nextPutAll: self serviceName;
				  nextPutAll: ', endpoint=';
				  nextPutAll: self endpoint;
				  nextPutAll: '}' ]
]

{ #category : 'accessing' }
OTXRayRemoteSampler >> endpoint [

	^ stateLock critical: [ endpoint ]
]

{ #category : 'accessing' }
OTXRayRemoteSampler >> endpoint: aString [

	stateLock critical: [ endpoint := self class normalizedEndpoint: aString ]
]

{ #category : 'private - refreshing' }
OTXRayRemoteSampler >> ensurePollingProcess [

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

{ #category : 'private - transport' }
OTXRayRemoteSampler >> executeHttpRequestPath: aString payload: aDictionary [

	| client response text |
	client := ZnClient new.
	client
		url: self endpoint , aString;
		method: #POST;
		timeout: self timeoutMillis.
	client headerAt: 'Content-Type' put: 'application/json'.
	client entity: (ZnEntity with: (ZnUtils defaultJSONWriter toString: aDictionary) type: ZnMimeType applicationJson).
	response := client
		            execute;
		            response.
	response code = 200 ifFalse: [ Error signal: 'X-Ray remote sampler request failed with HTTP status ' , response code asString ].
	text := response contents ifNil: [ '' ] ifNotNil: [ response contents asString trimBoth ].
	text isEmpty ifTrue: [ ^ OrderedDictionary new ].
	^ STONJSON fromString: text
]

{ #category : 'private - transport' }
OTXRayRemoteSampler >> executeRequestPath: aString payload: aDictionary [

	| executor |
	executor := stateLock critical: [ requestExecutor ].
	^ executor
		  ifNil: [ self executeHttpRequestPath: aString payload: aDictionary ]
		  ifNotNil: [ executor value: aString value: aDictionary ]
]

{ #category : 'private - refreshing' }
OTXRayRemoteSampler >> fetchRules [

	| collected nextToken payload response ruleDictionary ruleRecords |
	collected := OrderedCollection new.
	nextToken := nil.
	[
		payload := OrderedDictionary new.
		nextToken ifNotNil: [ payload at: 'NextToken' put: nextToken ].
		response := self executeRequestPath: '/GetSamplingRules' payload: payload.
		ruleRecords := response at: 'SamplingRuleRecords' ifAbsent: [ #(  ) ].
		ruleRecords do: [ :each |
				ruleDictionary := each at: 'SamplingRule' ifAbsent: [ each ].
				collected add: (OTXRaySamplingRule fromDictionary: ruleDictionary) ].
		nextToken := response at: 'NextToken' ifAbsent: [ nil ].
		nextToken ifNotNil: [ nextToken := nextToken asString trimBoth ].
		nextToken isNil or: [ nextToken isEmpty ] ] whileFalse.
	^ collected isEmpty
		  ifTrue: [ { OTXRaySamplingRule defaultRule } ]
		  ifFalse: [ collected asArray ]
]

{ #category : 'initialization' }
OTXRayRemoteSampler >> initialize [

	super initialize.
	serviceName := ''.
	serviceType := ''.
	endpoint := self class defaultEndpoint.
	pollingIntervalMillis := self class defaultPollingIntervalMillis.
	timeoutMillis := self class defaultTimeoutMillis.
	rules := { OTXRaySamplingRule defaultRule }.
	clockBlock := [ DateAndTime now asUnixTime * 1000 ].
	refreshLock := Semaphore forMutualExclusion.
	stateLock := Semaphore forMutualExclusion.
	lastPollTimeMillis := nil.
	warningSink := OTDiagnosticLogger defaultWarningSink.
	pollingSemaphore := Semaphore new.
	pollingProcess := nil.
	shutdownRequested := false.
	clientId := UUID new asString
]

{ #category : 'testing' }
OTXRayRemoteSampler >> isShutdown [

	^ stateLock critical: [ shutdownRequested ]
]

{ #category : 'testing' }
OTXRayRemoteSampler >> isStarted [

	^ stateLock critical: [ pollingProcess notNil and: [ pollingProcess isTerminated not ] ]
]

{ #category : 'private' }
OTXRayRemoteSampler >> matchingRuleForAttributes: someAttributes [

	^ self rules
		  detect: [ :each | each matchesServiceName: self serviceName serviceType: self serviceType attributes: someAttributes ]
		  ifNone: [ OTXRaySamplingRule defaultRule ]
]

{ #category : 'private - refreshing' }
OTXRayRemoteSampler >> mergeRuntimeStateInto: someRules [

	| existingByName |
	existingByName := OrderedDictionary new.
	self rules do: [ :each | existingByName at: each ruleName put: each ].
	someRules do: [ :each | each adoptRuntimeStateFrom: (existingByName at: each ruleName ifAbsent: [ nil ]) ]
]

{ #category : 'private - logging' }
OTXRayRemoteSampler >> noteRefreshError: anError [

	| sink |
	sink := stateLock critical: [ warningSink ].
	sink value: 'OpenTelemetry X-Ray remote sampler refresh failed: ' , anError description
]

{ #category : 'private' }
OTXRayRemoteSampler >> parentTraceStateFrom: aContext [

	| parentSpan parentSpanContext |
	parentSpan := aContext ifNotNil: [ aContext span ].
	parentSpanContext := parentSpan ifNotNil: [ parentSpan spanContext ].
	^ parentSpanContext ifNotNil: [ parentSpanContext traceState ]
]

{ #category : 'private - refreshing' }
OTXRayRemoteSampler >> pollOnce [

	refreshLock critical: [
			lastPollTimeMillis := self currentTimeMillis.
			self refreshSampler ]
]

{ #category : 'accessing' }
OTXRayRemoteSampler >> pollingIntervalMillis [

	^ stateLock critical: [ pollingIntervalMillis ]
]

{ #category : 'accessing' }
OTXRayRemoteSampler >> pollingIntervalMillis: anInteger [

	(anInteger isInteger and: [ anInteger > 0 ]) ifFalse: [
		Error signal: 'X-Ray remote sampler polling interval must be a positive integer number of milliseconds' ].
	stateLock critical: [ pollingIntervalMillis := anInteger ]
]

{ #category : 'private - refreshing' }
OTXRayRemoteSampler >> refreshIfNeeded [

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
OTXRayRemoteSampler >> refreshSampler [

	| refreshedRules statisticsDocuments targetResponse |
	refreshedRules := self fetchRules.
	self mergeRuntimeStateInto: refreshedRules.
	self rules: refreshedRules.
	statisticsDocuments := self statisticsDocumentsAtTimeMillis: self currentTimeMillis.
	statisticsDocuments isEmpty ifTrue: [ ^ self ].
	targetResponse := self executeRequestPath: '/SamplingTargets' payload: (OrderedDictionary new
			                   at: 'SamplingStatisticsDocuments' put: statisticsDocuments;
			                   yourself).
	self updateRulesFromTargetResponse: targetResponse.
	self clearRuleStatistics
]

{ #category : 'private - transport' }
OTXRayRemoteSampler >> requestExecutor: aBlockClosure [

	stateLock critical: [ requestExecutor := aBlockClosure ]
]

{ #category : 'accessing' }
OTXRayRemoteSampler >> rules [

	^ stateLock critical: [ rules copy ]
]

{ #category : 'private' }
OTXRayRemoteSampler >> rules: aCollection [

	| sortedRules |
	sortedRules := aCollection asArray.
	sortedRules sort: [ :left :right | left priority <= right priority ].
	stateLock critical: [
			rules := sortedRules isEmpty
				         ifTrue: [ { OTXRaySamplingRule defaultRule } ]
				         ifFalse: [ sortedRules ] ]
]

{ #category : 'private - refreshing' }
OTXRayRemoteSampler >> runPollingLoop [

	[ self isShutdown ] whileFalse: [
			[ self pollOnce ]
				on: Error
				do: [ :error | self noteRefreshError: error ].
			self isShutdown ifFalse: [ pollingSemaphore waitTimeoutMilliseconds: self pollingIntervalMillis ] ]
]

{ #category : 'accessing' }
OTXRayRemoteSampler >> serviceName [

	^ stateLock critical: [ serviceName ]
]

{ #category : 'accessing' }
OTXRayRemoteSampler >> serviceName: aString [

	stateLock critical: [ serviceName := aString ifNil: [ '' ] ifNotNil: [ aString asString ] ]
]

{ #category : 'accessing' }
OTXRayRemoteSampler >> serviceType [

	^ stateLock critical: [ serviceType ]
]

{ #category : 'accessing' }
OTXRayRemoteSampler >> serviceType: aString [

	stateLock critical: [ serviceType := aString ifNil: [ '' ] ifNotNil: [ aString asString ] ]
]

{ #category : 'sampling' }
OTXRayRemoteSampler >> shouldSampleIn: aContext traceId: aTraceId name: aString kind: aSpanKind attributes: someAttributes links: someLinks [

	| rule sampled traceState |
	self refreshIfNeeded.
	rule := self matchingRuleForAttributes: someAttributes.
	sampled := rule shouldSampleTraceId: aTraceId atTimeMillis: self currentTimeMillis.
	traceState := self parentTraceStateFrom: aContext.
	^ OTSamplingResult
		  decision: (sampled
				   ifTrue: [ #recordAndSample ]
				   ifFalse: [ #drop ])
		  attributes: #(  )
		  traceState: traceState
]

{ #category : 'lifecycle' }
OTXRayRemoteSampler >> shutdown [

	| didShutdown process |
	didShutdown := false.
	process := stateLock critical: [
			           shutdownRequested ifTrue: [ ^ false ].
			           shutdownRequested := true.
			           didShutdown := true.
			           pollingProcess ].
	pollingSemaphore signal.
	process ifNotNil: [ process terminate ].
	^ didShutdown
]

{ #category : 'lifecycle' }
OTXRayRemoteSampler >> start [

	^ self ensurePollingProcess
]

{ #category : 'private - refreshing' }
OTXRayRemoteSampler >> statisticsDocumentsAtTimeMillis: nowMillis [

	| documents timestampSeconds |
	documents := OrderedCollection new.
	timestampSeconds := nowMillis asFloat / 1000.0.
	self rules do: [ :each |
		(each statisticsDocumentForClientId: clientId timestampSeconds: timestampSeconds) ifNotNil: [ :document |
			documents add: document ] ].
	^ documents asArray
]

{ #category : 'accessing' }
OTXRayRemoteSampler >> timeoutMillis [

	^ stateLock critical: [ timeoutMillis ]
]

{ #category : 'accessing' }
OTXRayRemoteSampler >> timeoutMillis: anInteger [

	(anInteger isInteger and: [ anInteger > 0 ]) ifFalse: [
		Error signal: 'X-Ray remote sampler timeout must be a positive integer number of milliseconds' ].
	stateLock critical: [ timeoutMillis := anInteger ]
]

{ #category : 'private - refreshing' }
OTXRayRemoteSampler >> updateRulesFromTargetResponse: aDictionary [

	| currentRules targetDocuments |
	currentRules := self rules.
	targetDocuments := aDictionary at: 'SamplingTargetDocuments' ifAbsent: [ #(  ) ].
	targetDocuments do: [ :each |
			currentRules
				detect: [ :rule | rule ruleName = (each at: 'RuleName' ifAbsent: [ '' ]) ]
				ifFound: [ :rule | rule updateFromTargetDictionary: each ]
				ifNone: [ ] ]
]

{ #category : 'accessing' }
OTXRayRemoteSampler >> warningSink: aBlockClosure [

	stateLock critical: [ warningSink := aBlockClosure ]
]
