Class {
	#name : 'OTSamplerTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'tests' }
OTSamplerTest >> testFactoryMethodsReturnSamplerInstances [

	self assert: (OTSampler withInterval: 1000) class identicalTo: OTTimeIntervalSampler.
	self assert: (OTSampler withRate: 2) class identicalTo: OTFixedRateSampler.
	self assert: (OTSampler probability: 0.5) class identicalTo: OTProbabilisticSampler.
	self assert: (OTSampler withProbability: 0.5) class identicalTo: OTProbabilisticSampler.
	self assert: (OTSampler traceIdRatioBased: 0.5) class identicalTo: OTTraceIdRatioBasedSampler.
	self assert: OTSampler parentBased class identicalTo: OTParentBasedSampler.
	self assert: (OTSampler parentBased: OTAlwaysOffSampler new) class identicalTo: OTParentBasedSampler
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
