"
Metric instruments for `otel.sdk.span.*` self-observability.

I record started spans for every sampling decision and maintain the currently live recording-span count.
"
Class {
	#name : 'OTSdkTracerSelfMetrics',
	#superclass : 'Object',
	#instVars : [
		'startedSpans',
		'liveSpans'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTSdkTracerSelfMetrics class >> onMeter: anOTMeter [

	^ self new initializeOnMeter: anOTMeter
]

{ #category : 'initialization' }
OTSdkTracerSelfMetrics >> initializeOnMeter: anOTMeter [

	startedSpans := anOTMeter
		                counterNamed: 'otel.sdk.span.started'
		                unit: '{span}'
		                description: 'The number of created spans.'
		                advice: Dictionary new.
	liveSpans := anOTMeter
		             upDownCounterNamed: 'otel.sdk.span.live'
		             unit: '{span}'
		             description: 'The number of currently live spans.'
		             advice: Dictionary new.
	^ self
]

{ #category : 'recording' }
OTSdkTracerSelfMetrics >> recordEndedWithSamplingResult: aString [

	aString = 'DROP' ifFalse: [ liveSpans add: -1 attributes: { ('otel.span.sampling_result' -> aString) } asDictionary ]
]

{ #category : 'recording' }
OTSdkTracerSelfMetrics >> recordStartedWithParentOrigin: aString samplingResult: anotherString [

	| attributes |
	attributes := {
		              ('otel.span.parent.origin' -> aString).
		              ('otel.span.sampling_result' -> anotherString) } asDictionary.
	startedSpans add: 1 attributes: attributes.
	anotherString = 'DROP' ifFalse: [ liveSpans add: 1 attributes: { ('otel.span.sampling_result' -> anotherString) } asDictionary ]
]
