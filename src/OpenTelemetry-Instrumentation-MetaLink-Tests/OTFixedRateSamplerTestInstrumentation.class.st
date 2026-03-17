Class {
	#name : 'OTFixedRateSamplerTestInstrumentation',
	#superclass : 'OTMetaLinkTestInstrumentation',
	#category : 'OpenTelemetry-Instrumentation-MetaLink-Tests',
	#package : 'OpenTelemetry-Instrumentation-MetaLink-Tests'
}

{ #category : 'configuring' }
OTFixedRateSamplerTestInstrumentation class >> defineSampler [

	sampler := OTSampler withRate: 2
]
