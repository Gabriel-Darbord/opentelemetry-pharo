Class {
	#name : 'OTComposableProbabilitySampler',
	#superclass : 'OTComposableSampler',
	#instVars : [
		'probability',
		'threshold'
	],
	#category : 'OpenTelemetry-Sampling',
	#package : 'OpenTelemetry-Sampling'
}

{ #category : 'accessing' }
OTComposableProbabilitySampler >> description [

	^ 'ComposableProbability{' , self probability printString , '}'
]

{ #category : 'initialization' }
OTComposableProbabilitySampler >> initialize [

	super initialize.
	self probability: 1
]

{ #category : 'accessing' }
OTComposableProbabilitySampler >> probability [

	^ probability
]

{ #category : 'accessing' }
OTComposableProbabilitySampler >> probability: aNumber [

	(aNumber isNumber and: [ aNumber between: OTConsistentProbability minimumProbability and: 1 ]) ifFalse: [
		Error signal: 'ComposableProbability ratio must be between 2^-56 and 1' ].
	probability := aNumber.
	threshold := OTConsistentProbability thresholdForProbability: probability
]

{ #category : 'sampling' }
OTComposableProbabilitySampler >> samplingIntentIn: aContext name: aString kind: aSpanKind attributes: someAttributes links: someLinks [

	^ OTSamplingIntent threshold: threshold adjustedCountReliable: true
]

{ #category : 'accessing' }
OTComposableProbabilitySampler >> threshold [

	^ threshold
]
