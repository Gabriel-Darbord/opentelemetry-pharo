Class {
	#name : 'OTSampledInstrumentationTest',
	#superclass : 'OTAbstractInstrumentationTest',
	#category : 'OpenTelemetry-Instrumentation-MetaLink-Tests',
	#package : 'OpenTelemetry-Instrumentation-MetaLink-Tests'
}

{ #category : 'accessing' }
OTSampledInstrumentationTest >> instrumentation [

	^ OTTestSampledInstrumentation
]

{ #category : 'tests' }
OTSampledInstrumentationTest >> testFixedRateSampler [

	self deny: OTTestSampledInstrumentation hasRunOnEnter.
	target answer.
	self deny: OTTestSampledInstrumentation hasRunOnEnter.
	target answer.
	self assert: OTTestSampledInstrumentation hasRunOnEnter
]
