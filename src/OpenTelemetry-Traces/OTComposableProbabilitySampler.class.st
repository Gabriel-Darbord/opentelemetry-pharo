"
I produce composable sampling intents from a fixed probability by translating that probability into a consistent-sampling threshold.
"
Class {
	#name : 'OTComposableProbabilitySampler',
	#superclass : 'OTComposableSampler',
	#instVars : [
		'probability',
		'threshold'
	],
	#category : 'OpenTelemetry-Traces',
	#package : 'OpenTelemetry-Traces'
}

{ #category : 'accessing' }
OTComposableProbabilitySampler >> description [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'ComposableProbability{';
				  print: self probability;
				  nextPutAll: '}' ]
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
