Class {
	#name : 'OTTimeIntervalSamplerTest',
	#superclass : 'OTAbstractInstrumentationTest',
	#category : 'OpenTelemetry-Instrumentation-MetaLink-Tests',
	#package : 'OpenTelemetry-Instrumentation-MetaLink-Tests'
}

{ #category : 'accessing' }
OTTimeIntervalSamplerTest >> instrumentation [

	^ OTTimeIntervalSamplerTestInstrumentation
]

{ #category : 'tests' }
OTTimeIntervalSamplerTest >> testShouldSample [

	self assert: self instrumentation count equals: 0.

	"accepts first sample"
	target answer.
	self assert: self instrumentation count equals: 1.

	"denies if it has been less than the interval (an hour for this test, hopefully more than enough)"
	target answer.
	self assert: self instrumentation count equals: 1
]

{ #category : 'tests' }
OTTimeIntervalSamplerTest >> testShouldSampleAfterRestart [

	self assert: self instrumentation count equals: 0.

	"accepts first sample"
	target answer.
	self assert: self instrumentation count equals: 1.

	"accepts after (simulated) VM restart"
	self instrumentation sampler reset.
	target answer.
	self assert: self instrumentation count equals: 2
]
