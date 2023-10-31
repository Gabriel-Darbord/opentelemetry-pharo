"
I make trace sampling decisions based on a fixed sampling rate, allowing a specified portion of traces to be recorded.
This rate is set during initialization and remains constant.

For example, with a rate of 10, every 10th trace is sampled.
"
Class {
	#name : 'OTFixedRateSampler',
	#superclass : 'OTSampler',
	#instVars : [
		'rate',
		'count'
	],
	#category : 'OpenTelemetry-Sampling',
	#package : 'OpenTelemetry-Sampling'
}

{ #category : 'initialization' }
OTFixedRateSampler >> initialize [

	count := 0
]

{ #category : 'accessing' }
OTFixedRateSampler >> rate [

	^ rate
]

{ #category : 'accessing' }
OTFixedRateSampler >> rate: anInteger [
	"Should be positive"

	rate := anInteger
]

{ #category : 'asserting' }
OTFixedRateSampler >> shouldSample [

	count := count + 1.
	^ count >= rate
		  ifTrue: [
			  count := 0.
			  true ]
		  ifFalse: [ false ]
]
