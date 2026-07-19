"
A sampler that follows the parent sampling decision when a valid parent exists and delegates to a root sampler otherwise.
"
Class {
	#name : 'OTParentBasedSampler',
	#superclass : 'OTSampler',
	#instVars : [
		'rootSampler',
		'remoteParentSampledSampler',
		'remoteParentNotSampledSampler',
		'localParentSampledSampler',
		'localParentNotSampledSampler'
	],
	#category : 'OpenTelemetry-Sampling',
	#package : 'OpenTelemetry-Sampling'
}

{ #category : 'instance creation' }
OTParentBasedSampler class >> default [

	^ self new initialize
]

{ #category : 'instance creation' }
OTParentBasedSampler class >> root: aSampler [

	^ self default
		rootSampler: aSampler;
		yourself
]

{ #category : 'instance creation' }
OTParentBasedSampler class >> root: aRootSampler remoteParentSampled: aRemoteParentSampledSampler remoteParentNotSampled: aRemoteParentNotSampledSampler localParentSampled: aLocalParentSampledSampler localParentNotSampled: aLocalParentNotSampledSampler [

	^ (self root: aRootSampler)
		remoteParentSampledSampler: aRemoteParentSampledSampler;
		remoteParentNotSampledSampler: aRemoteParentNotSampledSampler;
		localParentSampledSampler: aLocalParentSampledSampler;
		localParentNotSampledSampler: aLocalParentNotSampledSampler;
		yourself
]
{ #category : 'accessing' }
OTParentBasedSampler >> description [

	^ String streamContents: [ :stream |
		stream
			nextPutAll: 'ParentBased{root:';
			nextPutAll: rootSampler description;
			nextPutAll: ',remoteParentSampled:';
			nextPutAll: remoteParentSampledSampler description;
			nextPutAll: ',remoteParentNotSampled:';
			nextPutAll: remoteParentNotSampledSampler description;
			nextPutAll: ',localParentSampled:';
			nextPutAll: localParentSampledSampler description;
			nextPutAll: ',localParentNotSampled:';
			nextPutAll: localParentNotSampledSampler description;
			nextPut: $} ]
]

{ #category : 'private - lifecycle' }
OTParentBasedSampler >> componentSamplers [

	| delegates seen |
	delegates := OrderedCollection new.
	seen := IdentitySet new.
	{
		rootSampler.
		remoteParentSampledSampler.
		remoteParentNotSampledSampler.
		localParentSampledSampler.
		localParentNotSampledSampler } do: [ :each |
		(seen includes: each) ifFalse: [
			seen add: each.
			delegates add: each ] ].
	^ delegates
]

{ #category : 'private' }
OTParentBasedSampler >> isConsistentThreshold: aThreshold forParentSpanContext: aSpanContext traceState: aTraceState [

	| sampled |
	sampled := OTConsistentProbability
		sampledWithRandomness: (OTConsistentProbability
				randomnessValueFromTraceId: aSpanContext traceId
				traceState: aTraceState)
		threshold: aThreshold.
	^ sampled = aSpanContext isSampled
]

{ #category : 'initialization' }
OTParentBasedSampler >> initialize [

	super initialize.
	rootSampler := OTAlwaysOnSampler new.
	remoteParentSampledSampler := OTAlwaysOnSampler new.
	remoteParentNotSampledSampler := OTAlwaysOffSampler new.
	localParentSampledSampler := OTAlwaysOnSampler new.
	localParentNotSampledSampler := OTAlwaysOffSampler new
]

{ #category : 'lifecycle' }
OTParentBasedSampler >> shutdown [

	| allShutdown |
	allShutdown := true.
	self componentSamplers do: [ :each |
		allShutdown := each shutdown & allShutdown ].
	^ allShutdown
]

{ #category : 'lifecycle' }
OTParentBasedSampler >> start [

	self componentSamplers do: [ :each | each start ]
]

{ #category : 'accessing' }
OTParentBasedSampler >> localParentNotSampledSampler [

	^ localParentNotSampledSampler
]

{ #category : 'accessing' }
OTParentBasedSampler >> localParentNotSampledSampler: aSampler [

	aSampler ifNil: [ self error: 'ParentBasedSampler requires a local-parent-not-sampled delegate sampler' ].
	localParentNotSampledSampler := aSampler
]

{ #category : 'accessing' }
OTParentBasedSampler >> localParentSampledSampler [

	^ localParentSampledSampler
]

{ #category : 'accessing' }
OTParentBasedSampler >> localParentSampledSampler: aSampler [

	aSampler ifNil: [ self error: 'ParentBasedSampler requires a local-parent-sampled delegate sampler' ].
	localParentSampledSampler := aSampler
]

{ #category : 'accessing' }
OTParentBasedSampler >> remoteParentNotSampledSampler [

	^ remoteParentNotSampledSampler
]

{ #category : 'accessing' }
OTParentBasedSampler >> remoteParentNotSampledSampler: aSampler [

	aSampler ifNil: [ self error: 'ParentBasedSampler requires a remote-parent-not-sampled delegate sampler' ].
	remoteParentNotSampledSampler := aSampler
]

{ #category : 'accessing' }
OTParentBasedSampler >> remoteParentSampledSampler [

	^ remoteParentSampledSampler
]

{ #category : 'accessing' }
OTParentBasedSampler >> remoteParentSampledSampler: aSampler [

	aSampler ifNil: [ self error: 'ParentBasedSampler requires a remote-parent-sampled delegate sampler' ].
	remoteParentSampledSampler := aSampler
]

{ #category : 'accessing' }
OTParentBasedSampler >> rootSampler [

	^ rootSampler
]

{ #category : 'accessing' }
OTParentBasedSampler >> rootSampler: aSampler [

	aSampler ifNil: [ self error: 'ParentBasedSampler requires a root delegate sampler' ].
	rootSampler := aSampler
]

{ #category : 'accessing' }
OTParentBasedSampler >> sampledParentSampler [

	^ self localParentSampledSampler
]

{ #category : 'accessing' }
OTParentBasedSampler >> sampledParentSampler: aSampler [

	self
		remoteParentSampledSampler: aSampler;
		localParentSampledSampler: aSampler.
	^ aSampler
]

{ #category : 'private' }
OTParentBasedSampler >> normalizedInheritedTraceStateForParentSpanContext: aSpanContext traceState: aTraceState [

	| threshold |
	aTraceState ifNil: [ ^ nil ].
	threshold := OTConsistentProbability thresholdFromTraceState: aTraceState.
	threshold ifNil: [ ^ aTraceState ].
	(self
		isConsistentThreshold: threshold
		forParentSpanContext: aSpanContext
		traceState: aTraceState) ifTrue: [ ^ aTraceState ].
	^ aTraceState withoutOtelValueAt: 'th'
]

{ #category : 'private' }
OTParentBasedSampler >> normalizedSamplingResult: aSamplingResult parentSpanContext: aSpanContext traceState: aTraceState [

	| normalizedTraceState |
	aSamplingResult traceState ifNotNil: [ ^ aSamplingResult ].
	normalizedTraceState := self
		normalizedInheritedTraceStateForParentSpanContext: aSpanContext
		traceState: aTraceState.
	normalizedTraceState == aTraceState ifTrue: [ ^ aSamplingResult ].
	^ OTSamplingResult
		decision: aSamplingResult decision
		attributes: aSamplingResult attributes
		traceState: normalizedTraceState
]

{ #category : 'sampling' }
OTParentBasedSampler >> shouldSampleIn: aContext traceId: aTraceId name: aString kind: aSpanKind attributes: someAttributes links: someLinks [

	| parentSpan parentSpanContext delegate result |
	parentSpan := aContext ifNotNil: [ aContext span ].
	parentSpan ifNil: [
		^ rootSampler
			shouldSampleIn: aContext
			traceId: aTraceId
			name: aString
			kind: aSpanKind
			attributes: someAttributes
			links: someLinks ].
	parentSpanContext := parentSpan spanContext.
	parentSpanContext isValid ifFalse: [
		^ rootSampler
			shouldSampleIn: aContext
			traceId: aTraceId
			name: aString
			kind: aSpanKind
			attributes: someAttributes
			links: someLinks ].
	delegate := parentSpanContext isRemote
		ifTrue: [
			parentSpanContext isSampled
				ifTrue: [ remoteParentSampledSampler ]
				ifFalse: [ remoteParentNotSampledSampler ] ]
		ifFalse: [
			parentSpanContext isSampled
				ifTrue: [ localParentSampledSampler ]
				ifFalse: [ localParentNotSampledSampler ] ].
	result := delegate
		shouldSampleIn: aContext
		traceId: aTraceId
		name: aString
		kind: aSpanKind
		attributes: someAttributes
		links: someLinks.
	^ self
		normalizedSamplingResult: result
		parentSpanContext: parentSpanContext
		traceState: parentSpan traceState
]

{ #category : 'accessing' }
OTParentBasedSampler >> unsampledParentSampler [

	^ self localParentNotSampledSampler
]

{ #category : 'accessing' }
OTParentBasedSampler >> unsampledParentSampler: aSampler [

	self
		remoteParentNotSampledSampler: aSampler;
		localParentNotSampledSampler: aSampler.
	^ aSampler
]
