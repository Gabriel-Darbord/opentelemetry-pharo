"
A sampler that finalizes composable sampling intents into spec-shaped sampling results.
"
Class {
	#name : 'OTCompositeSampler',
	#superclass : 'OTSampler',
	#instVars : [
		'delegate'
	],
	#category : 'OpenTelemetry-Sampling',
	#package : 'OpenTelemetry-Sampling'
}

{ #category : 'accessing' }
OTCompositeSampler >> delegate [

	^ delegate
]

{ #category : 'accessing' }
OTCompositeSampler >> delegate: aComposableSampler [

	aComposableSampler ifNil: [ self error: 'CompositeSampler requires a composable delegate sampler' ].
	delegate := aComposableSampler.
	self
]

{ #category : 'accessing' }
OTCompositeSampler >> description [

	^ 'CompositeSampler{', delegate description, '}'
]

{ #category : 'private' }
OTCompositeSampler >> finalizedTraceStateFrom: aTraceState sampled: aBoolean threshold: aThreshold adjustedCountReliable: isReliable [

	| baseState |
	baseState := OTTraceState from: aTraceState.
	(baseState isNil and: [ aBoolean and: [ isReliable ] ]) ifTrue: [
		baseState := OTTraceState empty ].
	baseState ifNil: [ ^ nil ].
	aBoolean ifFalse: [ ^ baseState withoutOtelValueAt: 'th' ].
	isReliable ifFalse: [ ^ baseState withoutOtelValueAt: 'th' ].
	^ baseState
		withOtelValueAt: 'th'
		put: (OTConsistentProbability thresholdStringFor: aThreshold)
]

{ #category : 'private' }
OTCompositeSampler >> parentTraceStateFrom: aContext [

	^ (aContext ifNotNil: [ aContext span ])
		ifNotNil: [ :parentSpan | parentSpan traceState ]
]

{ #category : 'sampling' }
OTCompositeSampler >> shouldSampleIn: aContext traceId: aTraceId name: aString kind: aSpanKind attributes: someAttributes links: someLinks [

	| decision intent randomness sampled traceState |
	intent := delegate
		samplingIntentIn: aContext
		name: aString
		kind: aSpanKind
		attributes: someAttributes
		links: someLinks.
	intent threshold ifNil: [
		traceState := intent
			traceStateForParent: (self parentTraceStateFrom: aContext)
			decision: #drop.
		^ OTSamplingResult
			decision: #drop
			attributes: #()
			traceState: (self
				finalizedTraceStateFrom: traceState
				sampled: false
				threshold: nil
				adjustedCountReliable: intent adjustedCountReliable) ].
	randomness := intent adjustedCountReliable
		ifTrue: [
			OTConsistentProbability
				randomnessValueFromTraceId: aTraceId
				traceState: (self parentTraceStateFrom: aContext) ]
		ifFalse: [ OTConsistentProbability newRandomnessValue ].
	sampled := OTConsistentProbability
		sampledWithRandomness: randomness
		threshold: intent threshold.
	decision := sampled
		ifTrue: [ #recordAndSample ]
		ifFalse: [ #drop ].
	traceState := intent
		traceStateForParent: (self parentTraceStateFrom: aContext)
		decision: decision.
	^ OTSamplingResult
		decision: decision
		attributes: (sampled ifTrue: [ intent attributes ] ifFalse: [ #() ])
		traceState: (self
			finalizedTraceStateFrom: traceState
			sampled: sampled
			threshold: intent threshold
			adjustedCountReliable: intent adjustedCountReliable)
]

{ #category : 'lifecycle' }
OTCompositeSampler >> shutdown [

	^ delegate shutdown
]

{ #category : 'lifecycle' }
OTCompositeSampler >> start [

	delegate start
]
