Class {
	#name : 'OTSampledInstrumentationTest',
	#superclass : 'OTAbstractInstrumentationTest',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'accessing' }
OTSampledInstrumentationTest >> instrumentationClass [

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
