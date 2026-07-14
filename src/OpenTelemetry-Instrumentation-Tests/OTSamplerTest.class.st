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
	self assert: (OTSampler traceIdRatioBased: 0.5) class identicalTo: OTTraceIdRatioBasedSampler
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
