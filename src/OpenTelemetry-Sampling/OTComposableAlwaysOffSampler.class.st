Class {
	#name : 'OTComposableAlwaysOffSampler',
	#superclass : 'OTComposableSampler',
	#category : 'OpenTelemetry-Sampling',
	#package : 'OpenTelemetry-Sampling'
}

{ #category : 'accessing' }
OTComposableAlwaysOffSampler >> description [

	^ 'ComposableAlwaysOff'
]

{ #category : 'sampling' }
OTComposableAlwaysOffSampler >> samplingIntentIn: aContext name: aString kind: aSpanKind attributes: someAttributes links: someLinks [

	^ OTSamplingIntent drop
]
