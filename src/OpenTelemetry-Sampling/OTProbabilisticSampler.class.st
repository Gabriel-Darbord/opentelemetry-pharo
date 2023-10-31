"
I make trace sampling decisions based on a probability rate, allowing traces to be sampled randomly.

For example, with a probability of 0.1, approximately 10% of traces are expected to be sampled.
"
Class {
	#name : 'OTProbabilisticSampler',
	#superclass : 'OTSampler',
	#instVars : [
		'probability'
	],
	#category : 'OpenTelemetry-Sampling',
	#package : 'OpenTelemetry-Sampling'
}

{ #category : 'accessing' }
OTProbabilisticSampler >> probability [

	^ probability
]

{ #category : 'accessing' }
OTProbabilisticSampler >> probability: aFloat [
	"Should be between 0 and 1"

	probability := aFloat
]

{ #category : 'asserting' }
OTProbabilisticSampler >> shouldSample [

	^ SharedRandom globalGenerator next < probability
]
