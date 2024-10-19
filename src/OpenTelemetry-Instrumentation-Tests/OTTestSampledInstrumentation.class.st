Class {
	#name : 'OTTestSampledInstrumentation',
	#superclass : 'OTMetaLinkTestInstrumentation',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'configuring' }
OTTestSampledInstrumentation class >> defineSampler [

	sampler := OTSampler withRate: 2
]
