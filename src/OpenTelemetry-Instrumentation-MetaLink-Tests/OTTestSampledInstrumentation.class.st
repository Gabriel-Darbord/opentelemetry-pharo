Class {
	#name : 'OTTestSampledInstrumentation',
	#superclass : 'OTMetaLinkTestInstrumentation',
	#category : 'OpenTelemetry-Instrumentation-MetaLink-Tests',
	#package : 'OpenTelemetry-Instrumentation-MetaLink-Tests'
}

{ #category : 'configuring' }
OTTestSampledInstrumentation class >> defineSampler [

	sampler := OTSampler withRate: 2
]
