"
I am a component responsible for making decisions about whether or not to sample a trace.
This allows to control the amount of data that is recorded and sent to backends.

My subclasses implement specific sampling strategies.
"
Class {
	#name : 'OTSampler',
	#superclass : 'Object',
	#category : 'OpenTelemetry-Sampling',
	#package : 'OpenTelemetry-Sampling'
}

{ #category : 'instance creation' }
OTSampler class >> alwaysRecord: aSampler [
	"Wrap a sampler so DROP becomes RECORD_ONLY while preserving the original sampling rate"

	^ OTAlwaysRecordSampler new rootSampler: aSampler
]

{ #category : 'instance creation' }
OTSampler class >> parentBased [

	^ OTParentBasedSampler default
]

{ #category : 'instance creation' }
OTSampler class >> parentBased: aSampler [

	^ OTParentBasedSampler root: aSampler
]

{ #category : 'instance creation' }
OTSampler class >> traceIdRatioBased: aNumber [
	"A deterministic trace-id-ratio sampler with a probability between 0 and 1"

	^ OTTraceIdRatioBasedSampler new probability: aNumber
]

{ #category : 'instance creation' }
OTSampler class >> withInterval: anInteger [
	"A minimum time interval sampler using milliseconds"

	^ OTTimeIntervalSampler new interval: anInteger
]

{ #category : 'instance creation' }
OTSampler class >> withProbability: aNumber [
	"A deterministic trace-id-ratio sampler with a probability between 0 and 1"

	^ self traceIdRatioBased: aNumber
]

{ #category : 'instance creation' }
OTSampler class >> withRate: anInteger [
	"A fixed-rate sampler with a positive rate"

	^ OTFixedRateSampler new rate: anInteger
]

{ #category : 'accessing' }
OTSampler >> description [

	^ self class name
]

{ #category : 'testing' }
OTSampler >> isShutdown [

	^ false
]

{ #category : 'lifecycle' }
OTSampler >> shutdown [

	^ true
]

{ #category : 'lifecycle' }
OTSampler >> start [

	self
]

{ #category : 'asserting' }
OTSampler >> shouldSample [

	self subclassResponsibility
]

{ #category : 'sampling' }
OTSampler >> shouldSampleIn: aContext traceId: aTraceId name: aString kind: aSpanKind attributes: someAttributes links: someLinks [

	^ self shouldSample
		ifTrue: [ OTSamplingResult recordAndSample ]
		ifFalse: [ OTSamplingResult drop ]
]
