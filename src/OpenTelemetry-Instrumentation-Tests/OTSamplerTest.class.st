Class {
	#name : 'OTSamplerTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'private' }
OTSamplerTest >> concurrentRecordedSampleCountFor: aSampler workerCount: workerCount [

	| acceptedCount acceptedLock |
	acceptedCount := 0.
	acceptedLock := Semaphore forMutualExclusion.
	self
		concurrentlyRun: [
				(aSampler
					 shouldSampleIn: OTContext new
					 traceId: '00112233445566778899aabbccddeeff'
					 name: 'operation'
					 kind: OTSpan internal
					 attributes: #(  )
					 links: #(  )) isRecordAndSample ifTrue: [ acceptedLock critical: [ acceptedCount := acceptedCount + 1 ] ] ]
		workerCount: workerCount.
	^ acceptedCount
]

{ #category : 'private' }
OTSamplerTest >> concurrentlyRun: aBlock workerCount: workerCount [

	| done gate |
	done := Semaphore new.
	gate := Semaphore new.
	workerCount timesRepeat: [
			[
				gate wait.
				aBlock value.
				done signal ] forkAt: Processor userBackgroundPriority ].
	workerCount timesRepeat: [ gate signal ].
	workerCount timesRepeat: [ self assert: (done waitTimeoutMilliseconds: 1000) not ]
]

{ #category : 'private' }
OTSamplerTest >> contextWithTraceFlags: aTraceFlags traceState: aTraceState [

	^ OTContext new
		withSpan: ((OTSpanContext
			traceId: '00112233445566778899aabbccddeeff'
			spanId: '1122334455667788'
			traceFlags: aTraceFlags
			traceState: aTraceState
			remote: false) asNonRecordingSpan)
]

{ #category : 'private' }
OTSamplerTest >> samplingResultFrom: aSampler parentTraceFlags: aTraceFlags traceState: aTraceState remote: aBoolean [

	| context |
	context := OTContext new
		withSpan: ((OTSpanContext
			traceId: '00112233445566778899aabbccddeeff'
			spanId: '1122334455667788'
			traceFlags: aTraceFlags
			traceState: aTraceState
			remote: aBoolean) asNonRecordingSpan).
	^ aSampler
		shouldSampleIn: context
		traceId: '1234567890abcdef1234567890abcdef'
		name: 'child'
		kind: OTSpan internal
		attributes: #()
		links: #()
]

{ #category : 'running' }
OTSamplerTest >> tearDown [

	OTProbabilisticSampler resetCompatibilityWarningState.
	OTTraceIdRatioBasedSampler resetCompatibilityWarningState.
	OTDiagnosticLogger reset.
	super tearDown
]

{ #category : 'tests' }
OTSamplerTest >> testAlwaysRecordSamplerConvertsDropToRecordOnlyAndPreservesMetadata [

	| result rootSampler sampler |
	rootSampler := OTSamplingResultSampler result:
		               (OTSamplingResult decision: #drop attributes: { ('sampler.answer' -> 42) } traceState: 'vendor=value').
	sampler := OTSampler alwaysRecord: rootSampler.
	result := sampler
		          shouldSampleIn: OTContext new
		          traceId: '1234567890abcdef1234567890abcdef'
		          name: 'operation'
		          kind: OTSpan internal
		          attributes: #(  )
		          links: #(  ).
	self assert: result isRecordOnly.
	self deny: result isRecordAndSample.
	self assert: result attributes asArray equals: { ('sampler.answer' -> 42) }.
	self assert: result traceState equals: 'vendor=value'
]

{ #category : 'tests' }
OTSamplerTest >> testAlwaysRecordSamplerPreservesRecordingAndSampledDecisions [

	| recordOnlyResult recordSampler recordOnlySampler sampledResult sampledSampler |
	recordOnlySampler := OTSamplingResultSampler result: OTSamplingResult recordOnly.
	recordSampler := OTSamplingResultSampler result: OTSamplingResult recordAndSample.
	sampledSampler := OTSampler alwaysRecord: recordSampler.
	recordOnlyResult := (OTSampler alwaysRecord: recordOnlySampler)
		                    shouldSampleIn: OTContext new
		                    traceId: '1234567890abcdef1234567890abcdef'
		                    name: 'operation'
		                    kind: OTSpan internal
		                    attributes: #(  )
		                    links: #(  ).
	sampledResult := sampledSampler
		                 shouldSampleIn: OTContext new
		                 traceId: '1234567890abcdef1234567890abcdef'
		                 name: 'operation'
		                 kind: OTSpan internal
		                 attributes: #(  )
		                 links: #(  ).
	self assert: recordOnlyResult isRecordOnly.
	self assert: sampledResult isRecordAndSample
]

{ #category : 'tests' }
OTSamplerTest >> testBuiltInSamplerDescriptionsFollowSpecification [

	self assert: OTAlwaysOnSampler new description equals: 'AlwaysOnSampler'.
	self assert: OTAlwaysOffSampler new description equals: 'AlwaysOffSampler'.
	self assert: (OTSampler traceIdRatioBased: 0.0001) description equals: 'TraceIdRatioBased{0.0001}'
]

{ #category : 'tests' }
OTSamplerTest >> testDefaultParentBasedSamplerUsesAlwaysOnRootAndParentDefaults [

	| sampler |
	sampler := OTSampler parentBased.
	self assert: sampler rootSampler class identicalTo: OTAlwaysOnSampler.
	self assert: sampler remoteParentSampledSampler class identicalTo: OTAlwaysOnSampler.
	self assert: sampler remoteParentNotSampledSampler class identicalTo: OTAlwaysOffSampler.
	self assert: sampler localParentSampledSampler class identicalTo: OTAlwaysOnSampler.
	self assert: sampler localParentNotSampledSampler class identicalTo: OTAlwaysOffSampler
]

{ #category : 'tests' }
OTSamplerTest >> testFactoryMethodsReturnSamplerInstances [

	self assert: (OTSampler withInterval: 1000) class identicalTo: OTTimeIntervalSampler.
	self assert: (OTSampler withRate: 2) class identicalTo: OTFixedRateSampler.
	self assert: (OTSampler probability: 0.5) class identicalTo: OTProbabilisticSampler.
	self assert: (OTSampler probabilityOrAlwaysOff: 0) class identicalTo: OTAlwaysOffSampler.
	self assert: (OTSampler probabilityOrAlwaysOff: 0.5) class identicalTo: OTProbabilisticSampler.
	self assert: (OTSampler withProbability: 0.5) class identicalTo: OTProbabilisticSampler.
	self assert: (OTSampler traceIdRatioBased: 0.5) class identicalTo: OTTraceIdRatioBasedSampler.
	self assert: OTSampler parentBased class identicalTo: OTParentBasedSampler.
	self assert: (OTSampler parentBased: OTAlwaysOffSampler new) class identicalTo: OTParentBasedSampler
]

{ #category : 'tests' }
OTSamplerTest >> testFixedRateSamplerAllowsExpectedConcurrentSampleCount [

	| sampler workerCount |
	sampler := OTSampler withRate: 3.
	workerCount := 9.
	10 timesRepeat: [ self assert: (self concurrentRecordedSampleCountFor: sampler workerCount: workerCount) equals: 3 ]
]

{ #category : 'tests' }
OTSamplerTest >> testParentBasedFactoryUsesConfiguredRootSampler [

	| sampler |
	sampler := OTSampler parentBased: OTAlwaysOffSampler new.
	self assert: sampler rootSampler class identicalTo: OTAlwaysOffSampler
]

{ #category : 'tests' }
OTSamplerTest >> testParentBasedSamplerDelegatesByParentSamplingStateAndOrigin [

	| localNotSampled localSampled remoteNotSampled remoteSampled root sampler sampledResult |
	root := OTSamplingResultSampler result: (OTSamplingResult
		decision: #recordAndSample
		attributes: #()
		traceState: 'root=value').
	remoteSampled := OTSamplingResultSampler result: (OTSamplingResult
		decision: #recordAndSample
		attributes: #()
		traceState: 'remoteSampled=value').
	remoteNotSampled := OTSamplingResultSampler result: (OTSamplingResult
		decision: #drop
		attributes: #()
		traceState: 'remoteNotSampled=value').
	localSampled := OTSamplingResultSampler result: (OTSamplingResult
		decision: #recordOnly
		attributes: #()
		traceState: 'localSampled=value').
	localNotSampled := OTSamplingResultSampler result: (OTSamplingResult
		decision: #drop
		attributes: #()
		traceState: 'localNotSampled=value').
	sampler := OTParentBasedSampler
		root: root
		remoteParentSampled: remoteSampled
		remoteParentNotSampled: remoteNotSampled
		localParentSampled: localSampled
		localParentNotSampled: localNotSampled.
	sampledResult := sampler
		shouldSampleIn: OTContext new
		traceId: '1234567890abcdef1234567890abcdef'
		name: 'root'
		kind: OTSpan internal
		attributes: #()
		links: #().
	self assert: sampledResult traceState equals: 'root=value'.
	self
		assert: ((self
			samplingResultFrom: sampler
			parentTraceFlags: '03'
			traceState: 'parent=value'
			remote: true) traceState)
		equals: 'remoteSampled=value'.
	self
		assert: ((self
			samplingResultFrom: sampler
			parentTraceFlags: '02'
			traceState: 'parent=value'
			remote: true) traceState)
		equals: 'remoteNotSampled=value'.
	self
		assert: ((self
			samplingResultFrom: sampler
			parentTraceFlags: '03'
			traceState: 'parent=value'
			remote: false) traceState)
		equals: 'localSampled=value'.
	self
		assert: ((self
			samplingResultFrom: sampler
			parentTraceFlags: '02'
			traceState: 'parent=value'
			remote: false) traceState)
		equals: 'localNotSampled=value'
]

{ #category : 'tests' }
OTSamplerTest >> testProbabilitySamplerAcceptsSpecificationMinimumRatio [

	| minimum sampler |
	minimum := OTProbabilisticSampler minimumProbability.
	sampler := OTSampler probability: minimum.
	self assert: sampler probability equals: minimum
]

{ #category : 'tests' }
OTSamplerTest >> testProbabilitySamplerAddsThresholdToOpenTelemetryTraceStateWhenSampled [

	| result sampler |
	sampler := OTSampler probability: 0.5.
	result := sampler
		shouldSampleIn: (self
				contextWithTraceFlags: '00'
				traceState: 'ot=rv:80000000000000')
		traceId: '00112233445566778899aabbccddeeff'
		name: 'operation'
		kind: OTSpan internal
		attributes: #()
		links: #().
	self assert: result isRecordAndSample.
	self assert: (result traceState otelValueAt: 'rv') equals: '80000000000000'.
	self assert: (result traceState otelValueAt: 'th') equals: '8'
]

{ #category : 'tests' }
OTSamplerTest >> testProbabilitySamplerDoesNotWarnWhenExplicitRandomnessIsPresent [

	| sampler warnings |
	warnings := OrderedCollection new.
	OTProbabilisticSampler compatibilityWarningSink: [ :message |
		warnings add: message ].
	sampler := OTSampler probability: 0.5.
	sampler
		shouldSampleIn: (self
				contextWithTraceFlags: '00'
				traceState: 'ot=rv:80000000000000')
		traceId: '00112233445566778899aabbccddeeff'
		name: 'operation'
		kind: OTSpan internal
		attributes: #()
		links: #().
	self assert: warnings isEmpty
]

{ #category : 'tests' }
OTSamplerTest >> testProbabilitySamplerIgnoresParentSampledFlag [

	| sampledParentResult sampler unsampledParentResult |
	sampler := OTSampler probability: 0.5.
	sampledParentResult := sampler
		                       shouldSampleIn: (self contextWithTraceFlags: '01' traceState: 'ot=rv:80000000000000')
		                       traceId: '00112233445566778899aabbccddeeff'
		                       name: 'operation'
		                       kind: OTSpan internal
		                       attributes: #(  )
		                       links: #(  ).
	unsampledParentResult := sampler
		                         shouldSampleIn: (self contextWithTraceFlags: '00' traceState: 'ot=rv:80000000000000')
		                         traceId: '00112233445566778899aabbccddeeff'
		                         name: 'operation'
		                         kind: OTSpan internal
		                         attributes: #(  )
		                         links: #(  ).
	self assert: sampledParentResult decision equals: unsampledParentResult decision.
	self assert: sampledParentResult traceState equals: unsampledParentResult traceState
]

{ #category : 'tests' }
OTSamplerTest >> testProbabilitySamplerMatchesPublishedQuarterSamplingExample [

	| droppedResult sampledResult sampler |
	sampler := OTSampler probability: 0.25.
	sampledResult := sampler
		                 shouldSampleIn: (self contextWithTraceFlags: '00' traceState: 'ot=rv:c0000000000000')
		                 traceId: '00112233445566778899aabbccddeeff'
		                 name: 'operation'
		                 kind: OTSpan internal
		                 attributes: #(  )
		                 links: #(  ).
	self assert: sampledResult isRecordAndSample.
	self assert: (sampledResult traceState otelValueAt: 'rv') equals: 'c0000000000000'.
	self assert: (sampledResult traceState otelValueAt: 'th') equals: 'c'.
	droppedResult := sampler
		                 shouldSampleIn: (self contextWithTraceFlags: '00' traceState: 'ot=rv:bfffffffffffff')
		                 traceId: '00112233445566778899aabbccddeeff'
		                 name: 'operation'
		                 kind: OTSpan internal
		                 attributes: #(  )
		                 links: #(  ).
	self assert: droppedResult isDrop.
	self assert: (droppedResult traceState otelValueAt: 'rv') equals: 'bfffffffffffff'.
	self assert: (droppedResult traceState otelValueAt: 'th') equals: nil
]

{ #category : 'tests' }
OTSamplerTest >> testProbabilitySamplerMatchesPublishedThresholdTableExamples [

	| examples |
	examples := {
		            (0.5 -> '8').
		            (0.25 -> 'c').
		            (1.0 / 3.0 -> 'aaab').
		            (0.1 -> 'e666').
		            (0.01 -> 'fd70a') }.
	examples do: [ :each |
			| threshold droppedResult droppedRv sampledResult sampledRv sampler |
			threshold := OTConsistentProbability thresholdFromString: each value.
			sampledRv := String streamContents: [ :stream | OTConsistentProbability writeThreshold: threshold on: stream ].
			droppedRv := String streamContents: [ :stream | OTConsistentProbability writeThreshold: threshold - 1 on: stream ].
			sampler := OTSampler probability: each key.
			sampledResult := sampler
				                 shouldSampleIn: (self contextWithTraceFlags: '00' traceState: 'ot=rv:' , sampledRv)
				                 traceId: '00112233445566778899aabbccddeeff'
				                 name: 'operation'
				                 kind: OTSpan internal
				                 attributes: #(  )
				                 links: #(  ).
			self assert: sampledResult isRecordAndSample.
			self assert: (sampledResult traceState otelValueAt: 'rv') equals: sampledRv.
			self assert: (sampledResult traceState otelValueAt: 'th') equals: each value.
			droppedResult := sampler
				                 shouldSampleIn: (self contextWithTraceFlags: '00' traceState: 'ot=rv:' , droppedRv)
				                 traceId: '00112233445566778899aabbccddeeff'
				                 name: 'operation'
				                 kind: OTSpan internal
				                 attributes: #(  )
				                 links: #(  ).
			self assert: droppedResult isDrop.
			self assert: (droppedResult traceState otelValueAt: 'rv') equals: droppedRv.
			self assert: (droppedResult traceState otelValueAt: 'th') equals: nil ]
]

{ #category : 'tests' }
OTSamplerTest >> testProbabilitySamplerPreservesTraceStateWhenDropped [

	| result sampler |
	sampler := OTSampler probability: 0.5.
	result := sampler
		shouldSampleIn: (self
				contextWithTraceFlags: '00'
				traceState: 'ot=rv:7fffffffffffff')
		traceId: '00112233445566778899aabbccddeeff'
		name: 'operation'
		kind: OTSpan internal
		attributes: #()
		links: #().
	self assert: result isDrop.
	self assert: (result traceState otelValueAt: 'rv') equals: '7fffffffffffff'.
	self assert: (result traceState otelValueAt: 'th') equals: nil
]

{ #category : 'tests' }
OTSamplerTest >> testProbabilitySamplerRejectsRatiosBelowSpecificationMinimum [

	self
		should: [ OTSampler probability: OTProbabilisticSampler minimumProbability / 2 ]
		raise: Error.
	self
		should: [ OTSampler probability: 0 ]
		raise: Error
]

{ #category : 'tests' }
OTSamplerTest >> testProbabilitySamplerUsesRecommendedDefaultThresholdPrecisionExamples [

	| examples |
	examples := {
		            (0.1 -> 'e666').
		            (0.01 -> 'fd70a').
		            (1.0 / 3.0 -> 'aaab') }.
	examples do: [ :each |
			| result sampler |
			sampler := OTSampler probability: each key.
			result := sampler
				          shouldSampleIn: (self contextWithTraceFlags: '00' traceState: 'ot=rv:ffffffffffffff')
				          traceId: '00112233445566778899aabbccddeeff'
				          name: 'operation'
				          kind: OTSpan internal
				          attributes: #(  )
				          links: #(  ).
			self assert: (result traceState otelValueAt: 'th') equals: each value ]
]

{ #category : 'tests' }
OTSamplerTest >> testProbabilitySamplerWarnsOnceUnderConcurrentSampling [

	| sampler warnings warningsLock workerCount |
	workerCount := 12.
	warnings := OrderedCollection new.
	warningsLock := Semaphore forMutualExclusion.
	10 timesRepeat: [
			OTProbabilisticSampler resetCompatibilityWarningState.
			OTProbabilisticSampler compatibilityWarningSink: [ :message | warningsLock critical: [ warnings add: message ] ].
			sampler := OTSampler probability: 0.5.
			warnings removeAll.
			self
				concurrentlyRun: [
						sampler
							shouldSampleIn: (self contextWithTraceFlags: '01' traceState: nil)
							traceId: '00112233445566778899aabbccddeeff'
							name: 'operation'
							kind: OTSpan internal
							attributes: #(  )
							links: #(  ) ]
				workerCount: workerCount.
			self assert: warnings asArray equals: { sampler compatibilityWarningMessage } ]
]

{ #category : 'tests' }
OTSamplerTest >> testProbabilitySamplerWarnsOnceWhenParentTraceIsNotMarkedRandom [

	| sampler warnings |
	warnings := OrderedCollection new.
	OTProbabilisticSampler compatibilityWarningSink: [ :message |
		warnings add: message ].
	sampler := OTSampler probability: 0.5.
	2 timesRepeat: [
		sampler
			shouldSampleIn: (self
					contextWithTraceFlags: '01'
					traceState: nil)
			traceId: '00112233445566778899aabbccddeeff'
			name: 'operation'
			kind: OTSpan internal
			attributes: #()
			links: #() ].
	self
		assert: warnings asArray
		equals: {
				'WARNING: The ProbabilitySampler sampler is presuming TraceIDs are random and expects the Trace random flag to be set in confirmation.  Please upgrade your caller(s) to use W3C Trace Context Level 2.' }
]

{ #category : 'tests' }
OTSamplerTest >> testRateLimitingSamplerAllowsOneConcurrentSampleWhenBalanceIsOne [

	| sampler workerCount |
	sampler := OTRateLimitingSampler new.
	sampler
		clockBlock: [ 1000 ];
		maxTracesPerSecond: 1.
	workerCount := 8.
	10 timesRepeat: [
			sampler maxTracesPerSecond: 1.
			self assert: (self concurrentRecordedSampleCountFor: sampler workerCount: workerCount) equals: 1 ]
]

{ #category : 'tests' }
OTSamplerTest >> testSamplerDescriptionsAreStableUnderConcurrentCalls [

	| expectedDescriptions lock observedDescriptions samplers |
	samplers := {
		            OTAlwaysOnSampler new.
		            OTAlwaysOffSampler new.
		            (OTSampler traceIdRatioBased: 0.5).
		            (OTSampler probability: 0.5).
		            OTSampler parentBased.
		            (OTSampler alwaysRecord: OTAlwaysOffSampler new).
		            (OTSampler composite: OTComposableSampler alwaysOn) }.
	expectedDescriptions := samplers collect: [ :each | each description ].
	lock := Semaphore forMutualExclusion.
	observedDescriptions := OrderedCollection new.
	self
		concurrentlyRun: [
		samplers withIndexDo: [ :each :index | lock critical: [ observedDescriptions add: index -> each description ] ] ]
		workerCount: 16.
	observedDescriptions do: [ :each | self assert: each value equals: (expectedDescriptions at: each key) ]
]

{ #category : 'tests' }
OTSamplerTest >> testTimeIntervalSamplerAllowsOnlyOneConcurrentSamplePerInterval [

	| sampler workerCount |
	sampler := OTSampler withInterval: 3600000.
	workerCount := 8.
	10 timesRepeat: [
			| acceptedCount acceptedLock done gate |
			sampler reset.
			acceptedCount := 0.
			acceptedLock := Semaphore forMutualExclusion.
			done := Semaphore new.
			gate := Semaphore new.
			workerCount timesRepeat: [
					[
						gate wait.
						(sampler
							 shouldSampleIn: OTContext new
							 traceId: '00112233445566778899aabbccddeeff'
							 name: 'operation'
							 kind: OTSpan internal
							 attributes: #(  )
							 links: #(  )) isRecordAndSample ifTrue: [ acceptedLock critical: [ acceptedCount := acceptedCount + 1 ] ].
						done signal ] forkAt: Processor userBackgroundPriority ].
			workerCount timesRepeat: [ gate signal ].
			workerCount timesRepeat: [ self assert: (done waitTimeoutMilliseconds: 1000) not ].
			self assert: acceptedCount equals: 1 ]
]

{ #category : 'tests' }
OTSamplerTest >> testTraceIdRatioBasedSamplerHigherProbabilitySamplesSupersetOfLowerProbability [

	| higherProbabilitySampler lowerProbabilitySampler traceIds |
	lowerProbabilitySampler := OTSampler traceIdRatioBased: 0.25.
	higherProbabilitySampler := OTSampler traceIdRatioBased: 0.75.
	traceIds := #( '00000000000000000000000000000000' '11111111111111111111111111111111' '22222222222222222222222222222222'
	               '33333333333333333333333333333333' '44444444444444444444444444444444' '55555555555555555555555555555555'
	               '66666666666666666666666666666666' '77777777777777777777777777777777' '88888888888888888888888888888888'
	               '99999999999999999999999999999999' 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
	               'cccccccccccccccccccccccccccccccc' 'dddddddddddddddddddddddddddddddd' 'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee'
	               'ffffffffffffffffffffffffffffffff' ).
	traceIds do: [ :traceId |
			| higherDecision lowerDecision |
			lowerDecision := (lowerProbabilitySampler
				                  shouldSampleIn: OTContext new
				                  traceId: traceId
				                  name: 'operation'
				                  kind: OTSpan internal
				                  attributes: #(  )
				                  links: #(  )) isRecordAndSample.
			higherDecision := (higherProbabilitySampler
				                   shouldSampleIn: OTContext new
				                   traceId: traceId
				                   name: 'operation'
				                   kind: OTSpan internal
				                   attributes: #(  )
				                   links: #(  )) isRecordAndSample.
			self deny: (lowerDecision and: [ higherDecision not ]) ]
]

{ #category : 'tests' }
OTSamplerTest >> testTraceIdRatioBasedSamplerIsDeterministicForSameTraceId [

	| sampler traceId first second |
	sampler := OTSampler traceIdRatioBased: 0.5.
	traceId := '1234567890abcdef1234567890abcdef'.
	first := sampler
		shouldSampleIn: OTContext new
		traceId: traceId
		name: 'operation'
		kind: OTSpan internal
		attributes: #()
		links: #().
	second := sampler
		shouldSampleIn: OTContext new
		traceId: traceId
		name: 'operation'
		kind: OTSpan internal
		attributes: #()
		links: #().
	self assert: first decision equals: second decision
]

{ #category : 'tests' }
OTSamplerTest >> testTraceIdRatioBasedSamplerRespectsProbabilityBounds [

	| sampled dropped traceId |
	traceId := '1234567890abcdef1234567890abcdef'.
	sampled := (OTSampler traceIdRatioBased: 1)
		shouldSampleIn: OTContext new
		traceId: traceId
		name: 'operation'
		kind: OTSpan internal
		attributes: #()
		links: #().
	dropped := (OTSampler traceIdRatioBased: 0)
		shouldSampleIn: OTContext new
		traceId: traceId
		name: 'operation'
		kind: OTSpan internal
		attributes: #()
		links: #().
	self assert: sampled isRecordAndSample.
	self assert: dropped isDrop
]

{ #category : 'tests' }
OTSamplerTest >> testTraceIdRatioBasedSamplerWarnsOnceUnderConcurrentSampling [

	| sampler warnings warningsLock workerCount |
	workerCount := 12.
	warnings := OrderedCollection new.
	warningsLock := Semaphore forMutualExclusion.
	10 timesRepeat: [
			OTTraceIdRatioBasedSampler resetCompatibilityWarningState.
			OTTraceIdRatioBasedSampler compatibilityWarningSink: [ :message | warningsLock critical: [ warnings add: message ] ].
			sampler := OTSampler traceIdRatioBased: 0.5.
			warnings removeAll.
			self
				concurrentlyRun: [
						sampler
							shouldSampleIn: (self contextWithTraceFlags: '01' traceState: nil)
							traceId: '00112233445566778899aabbccddeeff'
							name: 'operation'
							kind: OTSpan internal
							attributes: #(  )
							links: #(  ) ]
				workerCount: workerCount.
			self assert: warnings asArray equals: { sampler childSamplerCompatibilityWarningMessage } ]
]

{ #category : 'tests' }
OTSamplerTest >> testTraceIdRatioBasedSamplerWarnsOnceWhenParentUsesProbabilitySampler [

	| sampler warnings |
	warnings := OrderedCollection new.
	OTTraceIdRatioBasedSampler compatibilityWarningSink: [ :message |
		warnings add: message ].
	sampler := OTSampler traceIdRatioBased: 0.5.
	2 timesRepeat: [
		sampler
			shouldSampleIn: (self
					contextWithTraceFlags: '01'
					traceState: 'ot=th:8')
			traceId: '00112233445566778899aabbccddeeff'
			name: 'operation'
			kind: OTSpan internal
			attributes: #()
			links: #() ].
	self
		assert: warnings asArray
		equals: {
				'WARNING: The TraceIdRatioBased sampler is operating as a child sampler and a parent is using ProbabilitySampler. Please upgrade this SDK configuration to use ProbabilitySampler.' }
]

{ #category : 'tests' }
OTSamplerTest >> testTraceIdRatioBasedSamplerWarnsWhenUsedAsChildSampler [

	| sampler warnings |
	warnings := OrderedCollection new.
	OTTraceIdRatioBasedSampler compatibilityWarningSink: [ :message |
		warnings add: message ].
	sampler := OTSampler traceIdRatioBased: 0.5.
	sampler
		shouldSampleIn: (self
				contextWithTraceFlags: '01'
				traceState: nil)
		traceId: '00112233445566778899aabbccddeeff'
		name: 'operation'
		kind: OTSpan internal
		attributes: #()
		links: #().
	self
		assert: warnings asArray
		equals: {
				'WARNING: The TraceIdRatioBased sampler is operating as a child sampler; the behavior is subject to change. Please upgrade this SDK configuration to use ProbabilitySampler.' }
]
