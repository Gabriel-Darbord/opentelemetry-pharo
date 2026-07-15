"
A sampler that always returns DROP.
"
Class {
	#name : 'OTAlwaysOffSampler',
	#superclass : 'OTSampler',
	#category : 'OpenTelemetry-Sampling',
	#package : 'OpenTelemetry-Sampling'
}

{ #category : 'accessing' }
OTAlwaysOffSampler >> description [

	^ 'AlwaysOffSampler'
]

{ #category : 'asserting' }
OTAlwaysOffSampler >> shouldSample [

	^ false
]

{ #category : 'sampling' }
OTAlwaysOffSampler >> shouldSampleIn: aContext traceId: aTraceId name: aString kind: aSpanKind attributes: someAttributes links: someLinks [

	^ OTSamplingResult drop
]
