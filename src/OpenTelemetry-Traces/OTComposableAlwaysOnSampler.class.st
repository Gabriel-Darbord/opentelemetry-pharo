"
I am a composable sampler that always samples spans.
I contribute a zero-threshold sampling intent to composed sampling decisions.
"
Class {
	#name : 'OTComposableAlwaysOnSampler',
	#superclass : 'OTComposableSampler',
	#category : 'OpenTelemetry-Traces',
	#package : 'OpenTelemetry-Traces'
}

{ #category : 'accessing' }
OTComposableAlwaysOnSampler >> description [

	^ 'ComposableAlwaysOn'
]

{ #category : 'sampling' }
OTComposableAlwaysOnSampler >> samplingIntentIn: aContext name: aString kind: aSpanKind attributes: someAttributes links: someLinks [

	^ OTSamplingIntent threshold: 0 adjustedCountReliable: true
]
