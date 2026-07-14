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

{ #category : 'initialization' }
OTParentBasedSampler >> initialize [

	super initialize.
	rootSampler := OTAlwaysOnSampler new.
	remoteParentSampledSampler := OTAlwaysOnSampler new.
	remoteParentNotSampledSampler := OTAlwaysOffSampler new.
	localParentSampledSampler := OTAlwaysOnSampler new.
	localParentNotSampledSampler := OTAlwaysOffSampler new.
	^ self
]

{ #category : 'accessing' }
OTParentBasedSampler >> localParentNotSampledSampler [

	^ localParentNotSampledSampler
]

{ #category : 'accessing' }
OTParentBasedSampler >> localParentNotSampledSampler: aSampler [

	localParentNotSampledSampler := aSampler
]

{ #category : 'accessing' }
OTParentBasedSampler >> localParentSampledSampler [

	^ localParentSampledSampler
]

{ #category : 'accessing' }
OTParentBasedSampler >> localParentSampledSampler: aSampler [

	localParentSampledSampler := aSampler
]

{ #category : 'accessing' }
OTParentBasedSampler >> remoteParentNotSampledSampler [

	^ remoteParentNotSampledSampler
]

{ #category : 'accessing' }
OTParentBasedSampler >> remoteParentNotSampledSampler: aSampler [

	remoteParentNotSampledSampler := aSampler
]

{ #category : 'accessing' }
OTParentBasedSampler >> remoteParentSampledSampler [

	^ remoteParentSampledSampler
]

{ #category : 'accessing' }
OTParentBasedSampler >> remoteParentSampledSampler: aSampler [

	remoteParentSampledSampler := aSampler
]

{ #category : 'accessing' }
OTParentBasedSampler >> rootSampler [

	^ rootSampler
]

{ #category : 'accessing' }
OTParentBasedSampler >> rootSampler: aSampler [

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

{ #category : 'sampling' }
OTParentBasedSampler >> shouldSampleIn: aContext traceId: aTraceId name: aString kind: aSpanKind attributes: someAttributes links: someLinks [

	| parentSpan parentSpanContext delegate |
	parentSpan := aContext ifNil: [ nil ] ifNotNil: [ aContext span ].
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
	^ delegate
		shouldSampleIn: aContext
		traceId: aTraceId
		name: aString
		kind: aSpanKind
		attributes: someAttributes
		links: someLinks
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
