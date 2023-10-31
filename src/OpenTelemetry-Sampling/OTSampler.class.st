"
I am a component responsible for making decisions about whether or not to sample a trace.
This allows to control the amount of data that is recorded and sent to backends.

My subclasses implement specific sampling strategies.
"
Class {
	#name : 'OTSampler',
	#superclass : 'Object',
	#category : 'OpenTelemetry-Sampling',
	#package : 'OpenTelemetry-Sampling'
}

{ #category : 'accessing' }
OTSampler class >> withProbability: aFloat [
	"A probabilistic sampler with a probability between 0 and 1"

	^ OTProbabilisticSampler new probability: aFloat
]

{ #category : 'accessing' }
OTSampler class >> withRate: anInteger [
	"A fixed-rate sampler with a positive rate"

	^ OTFixedRateSampler new rate: anInteger
]

{ #category : 'asserting' }
OTSampler >> shouldSample [

	self subclassResponsibility
]
