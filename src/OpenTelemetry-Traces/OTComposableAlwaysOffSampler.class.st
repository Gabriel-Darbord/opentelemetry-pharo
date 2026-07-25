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
