"
I wrap another sampler and upgrade drop decisions into record-only results while preserving the delegate's other sampling behavior.
"
Class {
	#name : 'OTAlwaysRecordSampler',
	#superclass : 'OTSampler',
	#instVars : [
		'rootSampler'
	],
	#category : 'OpenTelemetry-Sampling',
	#package : 'OpenTelemetry-Sampling'
}

{ #category : 'accessing' }
OTAlwaysRecordSampler >> description [

	^ String streamContents: [ :s | s << 'AlwaysRecordSampler{' << rootSampler description << '}' ]
]

{ #category : 'accessing' }
OTAlwaysRecordSampler >> rootSampler [

	^ rootSampler
]

{ #category : 'accessing' }
OTAlwaysRecordSampler >> rootSampler: aSampler [

	aSampler ifNil: [ self error: 'AlwaysRecordSampler requires a delegate sampler' ].
	rootSampler := aSampler.
	^ self
]

{ #category : 'sampling' }
OTAlwaysRecordSampler >> shouldSampleIn: aContext traceId: aTraceId name: aString kind: aSpanKind attributes: someAttributes links: someLinks [

	| result |
	result := rootSampler
		          shouldSampleIn: aContext
		          traceId: aTraceId
		          name: aString
		          kind: aSpanKind
		          attributes: someAttributes
		          links: someLinks.
	result isDrop ifFalse: [ ^ result ].
	^ OTSamplingResult decision: #recordOnly attributes: result attributes traceState: result traceState
]

{ #category : 'lifecycle' }
OTAlwaysRecordSampler >> shutdown [

	^ rootSampler shutdown
]

{ #category : 'lifecycle' }
OTAlwaysRecordSampler >> start [

	rootSampler start
]
