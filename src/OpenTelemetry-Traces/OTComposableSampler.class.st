"
An abstract composable sampler that answers a sampling intent instead of a final sampling result.
"
Class {
	#name : 'OTComposableSampler',
	#superclass : 'Object',
	#category : 'OpenTelemetry-Traces',
	#package : 'OpenTelemetry-Traces'
}

{ #category : 'instance creation' }
OTComposableSampler class >> alwaysOff [

	^ OTComposableAlwaysOffSampler new
]

{ #category : 'instance creation' }
OTComposableSampler class >> alwaysOn [

	^ OTComposableAlwaysOnSampler new
]

{ #category : 'instance creation' }
OTComposableSampler class >> annotating: someAttributes delegate: aComposableSampler [

	^ OTComposableAnnotatingSampler new
		  attributes: someAttributes;
		  delegate: aComposableSampler;
		  yourself
]

{ #category : 'instance creation' }
OTComposableSampler class >> parentThreshold: aComposableSampler [

	^ OTComposableParentThresholdSampler new
		  rootSampler: aComposableSampler;
		  yourself
]

{ #category : 'instance creation' }
OTComposableSampler class >> probability: aNumber [

	aNumber = 0 ifTrue: [ ^ self alwaysOff ].
	^ OTComposableProbabilitySampler new probability: aNumber
]

{ #category : 'instance creation' }
OTComposableSampler class >> ruleBased: someRules [

	^ OTComposableRuleBasedSampler new
		  rules: someRules;
		  yourself
]

{ #category : 'accessing' }
OTComposableSampler >> description [

	^ self class name
]

{ #category : 'sampling' }
OTComposableSampler >> samplingIntentIn: aContext name: aString kind: aSpanKind attributes: someAttributes links: someLinks [

	self subclassResponsibility
]

{ #category : 'lifecycle' }
OTComposableSampler >> shutdown [

	^ true
]

{ #category : 'lifecycle' }
OTComposableSampler >> start [

	self
]
