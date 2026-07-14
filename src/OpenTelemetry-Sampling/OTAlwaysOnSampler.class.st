"
A sampler that always returns RECORD_AND_SAMPLE.
"
Class {
	#name : 'OTAlwaysOnSampler',
	#superclass : 'OTSampler',
	#category : 'OpenTelemetry-Sampling',
	#package : 'OpenTelemetry-Sampling'
}

{ #category : 'accessing' }
OTAlwaysOnSampler >> description [

	^ 'AlwaysOnSampler'
]

{ #category : 'asserting' }
OTAlwaysOnSampler >> shouldSample [

	^ true
]

{ #category : 'sampling' }
OTAlwaysOnSampler >> shouldSampleIn: aContext traceId: aTraceId name: aString kind: aSpanKind attributes: someAttributes links: someLinks [

	^ OTSamplingResult recordAndSample
]
