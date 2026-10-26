"
A sampler that always returns RECORD_AND_SAMPLE.
"
Class {
	#name : 'OTAlwaysOnSampler',
	#superclass : 'OTSampler',
	#category : 'OpenTelemetry-Traces',
	#package : 'OpenTelemetry-Traces'
}

{ #category : 'accessing' }
OTAlwaysOnSampler >> description [

	^ 'AlwaysOnSampler'
]

{ #category : 'asserting' }
OTAlwaysOnSampler >> shouldSample [

	self isShutdown ifTrue: [ ^ false ].
	^ true
]

{ #category : 'sampling' }
OTAlwaysOnSampler >> shouldSampleIn: aContext traceId: aTraceId name: aString kind: aSpanKind attributes: someAttributes links: someLinks [

	self isShutdown ifTrue: [ ^ OTSamplingResult drop ].
	^ OTSamplingResult recordAndSample
]
