"
I am a composable sampler that always drops spans.
I contribute a drop intent to composed sampling decisions.
"
Class {
	#name : 'OTComposableAlwaysOffSampler',
	#superclass : 'OTComposableSampler',
	#category : 'OpenTelemetry-Traces',
	#package : 'OpenTelemetry-Traces'
}

{ #category : 'accessing' }
OTComposableAlwaysOffSampler >> description [

	^ 'ComposableAlwaysOff'
]

{ #category : 'sampling' }
OTComposableAlwaysOffSampler >> samplingIntentIn: aContext name: aString kind: aSpanKind attributes: someAttributes links: someLinks [

	^ OTSamplingIntent drop
]
