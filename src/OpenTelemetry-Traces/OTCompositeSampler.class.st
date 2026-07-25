"
A sampler that finalizes composable sampling intents into spec-shaped sampling results.
"
Class {
	#name : 'OTCompositeSampler',
	#superclass : 'OTSampler',
	#instVars : [
		'delegate'
	],
	#category : 'OpenTelemetry-Traces',
	#package : 'OpenTelemetry-Traces'
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

	^ String streamContents: [ :s | s << 'CompositeSampler{' << delegate description << '}' ]
]

{ #category : 'private' }
OTCompositeSampler >> finalizedTraceStateFrom: aTraceState sampled: aBoolean threshold: aThreshold adjustedCountReliable: isReliable [

	| baseState |
	baseState := OTTraceState from: aTraceState.
	(baseState isNil and: [ aBoolean and: [ isReliable ] ]) ifTrue: [ baseState := OTTraceState empty ].
	baseState ifNil: [ ^ nil ].
	aBoolean ifFalse: [ ^ baseState withoutOtelValueAt: 'th' ].
	isReliable ifFalse: [ ^ baseState withoutOtelValueAt: 'th' ].
	^ baseState withOtelValueAt: 'th' put: (OTConsistentProbability thresholdStringFor: aThreshold)
]

{ #category : 'private' }
OTCompositeSampler >> parentTraceStateFrom: aContext [

	^ (aContext ifNotNil: [ aContext span ]) ifNotNil: [ :parentSpan | parentSpan spanContext traceState ]
]

{ #category : 'private' }
OTCompositeSampler >> sanitizedTraceStateFrom: aTraceState preservingParentOtelEntriesFrom: parentTraceState [

	| sanitizedTraceState preservedOtelValue |
	sanitizedTraceState := OTTraceState from: aTraceState.
	preservedOtelValue := parentTraceState ifNotNil: [ parentTraceState valueAt: 'ot' ].
	sanitizedTraceState := sanitizedTraceState ifNotNil: [ sanitizedTraceState withoutKey: 'ot' ].
	preservedOtelValue ifNil: [ ^ sanitizedTraceState ].
	sanitizedTraceState ifNil: [ sanitizedTraceState := OTTraceState empty ].
	^ sanitizedTraceState withKey: 'ot' value: preservedOtelValue
]

{ #category : 'sampling' }
OTCompositeSampler >> shouldSampleIn: aContext traceId: aTraceId name: aString kind: aSpanKind attributes: someAttributes links: someLinks [

	| decision intent parentTraceState randomness sampled traceState |
	intent := delegate
		          samplingIntentIn: aContext
		          name: aString
		          kind: aSpanKind
		          attributes: someAttributes
		          links: someLinks.
	parentTraceState := self parentTraceStateFrom: aContext.
	intent threshold ifNil: [
			traceState := self
				              sanitizedTraceStateFrom: (intent traceStateForParent: parentTraceState decision: #drop)
				              preservingParentOtelEntriesFrom: parentTraceState.
			^ OTSamplingResult decision: #drop attributes: #(  ) traceState: (self
					   finalizedTraceStateFrom: traceState
					   sampled: false
					   threshold: nil
					   adjustedCountReliable: intent adjustedCountReliable) ].
	randomness := intent adjustedCountReliable
		              ifTrue: [ OTConsistentProbability randomnessValueFromTraceId: aTraceId traceState: parentTraceState ]
		              ifFalse: [ OTConsistentProbability newRandomnessValue ].
	sampled := OTConsistentProbability sampledWithRandomness: randomness threshold: intent threshold.
	decision := sampled
		            ifTrue: [ #recordAndSample ]
		            ifFalse: [ #drop ].
	traceState := self
		              sanitizedTraceStateFrom: (intent traceStateForParent: parentTraceState decision: decision)
		              preservingParentOtelEntriesFrom: parentTraceState.
	^ OTSamplingResult
		  decision: decision
		  attributes: (sampled
				   ifTrue: [ intent attributes ]
				   ifFalse: [ #(  ) ])
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
