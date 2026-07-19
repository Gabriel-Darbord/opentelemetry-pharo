Class {
	#name : 'OTComposableAlwaysOnSampler',
	#superclass : 'OTComposableSampler',
	#category : 'OpenTelemetry-Sampling',
	#package : 'OpenTelemetry-Sampling'
}

{ #category : 'accessing' }
OTComposableAlwaysOnSampler >> description [

	^ 'ComposableAlwaysOn'
]

{ #category : 'sampling' }
OTComposableAlwaysOnSampler >> samplingIntentIn: aContext name: aString kind: aSpanKind attributes: someAttributes links: someLinks [

	^ OTSamplingIntent threshold: 0 adjustedCountReliable: true
]
