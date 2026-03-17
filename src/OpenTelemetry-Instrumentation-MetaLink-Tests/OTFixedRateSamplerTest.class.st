Class {
	#name : 'OTFixedRateSamplerTest',
	#superclass : 'OTAbstractInstrumentationTest',
	#category : 'OpenTelemetry-Instrumentation-MetaLink-Tests',
	#package : 'OpenTelemetry-Instrumentation-MetaLink-Tests'
}

{ #category : 'accessing' }
OTFixedRateSamplerTest >> instrumentation [

	^ OTFixedRateSamplerTestInstrumentation
]

{ #category : 'tests' }
OTFixedRateSamplerTest >> testShouldSample [

	self deny: self instrumentation hasRunOnEnter.
	target answer.
	self deny: self instrumentation hasRunOnEnter.
	target answer.
	self assert: self instrumentation hasRunOnEnter
]
