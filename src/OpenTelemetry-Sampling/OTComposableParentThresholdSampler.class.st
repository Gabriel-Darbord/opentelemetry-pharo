Class {
	#name : 'OTComposableParentThresholdSampler',
	#superclass : 'OTComposableSampler',
	#instVars : [
		'rootSampler'
	],
	#category : 'OpenTelemetry-Sampling',
	#package : 'OpenTelemetry-Sampling'
}

{ #category : 'accessing' }
OTComposableParentThresholdSampler >> description [

	^ 'ComposableParentThreshold{', rootSampler description, '}'
]

{ #category : 'private' }
OTComposableParentThresholdSampler >> intentForParentSpanContext: aSpanContext traceState: aTraceState [

	| parentThreshold sampled |
	sampled := aSpanContext isSampled.
	parentThreshold := OTConsistentProbability thresholdFromTraceState: aTraceState.
	parentThreshold ifNotNil: [
		(self
			isConsistentThreshold: parentThreshold
			forParentSpanContext: aSpanContext
			traceState: aTraceState) ifFalse: [
			parentThreshold := nil ] ].
	parentThreshold ifNil: [
		^ sampled
			ifTrue: [ OTSamplingIntent threshold: 0 adjustedCountReliable: false ]
			ifFalse: [ OTSamplingIntent drop ] ].
	^ OTSamplingIntent
		threshold: parentThreshold
		adjustedCountReliable: true
]

{ #category : 'private' }
OTComposableParentThresholdSampler >> isConsistentThreshold: aThreshold forParentSpanContext: aSpanContext traceState: aTraceState [

	| sampled |
	sampled := OTConsistentProbability
		sampledWithRandomness: (OTConsistentProbability
				randomnessValueFromTraceId: aSpanContext traceId
				traceState: aTraceState)
		threshold: aThreshold.
	^ sampled = aSpanContext isSampled
]

{ #category : 'accessing' }
OTComposableParentThresholdSampler >> rootSampler [

	^ rootSampler
]

{ #category : 'accessing' }
OTComposableParentThresholdSampler >> rootSampler: aComposableSampler [

	aComposableSampler ifNil: [ self error: 'ComposableParentThreshold requires a root delegate sampler' ].
	rootSampler := aComposableSampler
]

{ #category : 'sampling' }
OTComposableParentThresholdSampler >> samplingIntentIn: aContext name: aString kind: aSpanKind attributes: someAttributes links: someLinks [

	| parentSpan parentSpanContext |
	parentSpan := aContext ifNotNil: [ aContext span ].
	parentSpan ifNil: [
			^ rootSampler
				  samplingIntentIn: aContext
				  name: aString
				  kind: aSpanKind
				  attributes: someAttributes
				  links: someLinks ].
	parentSpanContext := parentSpan spanContext.
	parentSpanContext isValid ifFalse: [
			^ rootSampler
				  samplingIntentIn: aContext
				  name: aString
				  kind: aSpanKind
				  attributes: someAttributes
				  links: someLinks ].
	^ self intentForParentSpanContext: parentSpanContext traceState: parentSpanContext traceState
]

{ #category : 'lifecycle' }
OTComposableParentThresholdSampler >> shutdown [

	^ rootSampler shutdown
]

{ #category : 'lifecycle' }
OTComposableParentThresholdSampler >> start [

	rootSampler start
]
