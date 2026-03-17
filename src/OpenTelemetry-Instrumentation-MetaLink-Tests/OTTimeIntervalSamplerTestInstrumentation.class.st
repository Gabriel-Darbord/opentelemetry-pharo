Class {
	#name : 'OTTimeIntervalSamplerTestInstrumentation',
	#superclass : 'OTMetaLinkTestInstrumentation',
	#classInstVars : [
		'count'
	],
	#category : 'OpenTelemetry-Instrumentation-MetaLink-Tests',
	#package : 'OpenTelemetry-Instrumentation-MetaLink-Tests'
}

{ #category : 'accessing' }
OTTimeIntervalSamplerTestInstrumentation class >> count [

	^ count
]

{ #category : 'configuring' }
OTTimeIntervalSamplerTestInstrumentation class >> defineSampler [

	sampler := OTSampler withInterval: 1 hour asMilliSeconds
]

{ #category : 'evaluating' }
OTTimeIntervalSamplerTestInstrumentation class >> onMethodExit: arguments withValue: value [

	count := count + 1
]

{ #category : 'class initialization' }
OTTimeIntervalSamplerTestInstrumentation class >> reset [

	super reset.
	count := 0
]

{ #category : 'accessing' }
OTTimeIntervalSamplerTestInstrumentation class >> sampler [

	^ sampler
]
