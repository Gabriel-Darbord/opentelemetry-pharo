"
A sampler that always returns DROP.
"
Class {
	#name : 'OTAlwaysOffSampler',
	#superclass : 'OTSampler',
	#category : 'OpenTelemetry-Traces',
	#package : 'OpenTelemetry-Traces'
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
