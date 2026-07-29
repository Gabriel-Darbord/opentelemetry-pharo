"
Metric instruments for SDK metric-reader self-observability.

I record the duration and outcome of metric collection operations for one reader component.
"
Class {
	#name : 'OTSdkMetricReaderSelfMetrics',
	#superclass : 'Object',
	#instVars : [
		'collectionDuration',
		'componentAttributes'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTSdkMetricReaderSelfMetrics class >> component: anOTSdkSelfObservabilityComponent meter: anOTMeter [

	^ self new initializeComponent: anOTSdkSelfObservabilityComponent meter: anOTMeter
]

{ #category : 'initialization' }
OTSdkMetricReaderSelfMetrics >> initializeComponent: anOTSdkSelfObservabilityComponent meter: anOTMeter [

	componentAttributes := anOTSdkSelfObservabilityComponent attributes.
	collectionDuration := anOTMeter
		                      histogramNamed: 'otel.sdk.metric_reader.collection.duration'
		                      unit: 's'
		                      description: 'The duration of the collect operation of the metric reader.'
		                      advice: { ('ExplicitBucketBoundaries' -> #(  )) } asDictionary.
	^ self
]

{ #category : 'recording' }
OTSdkMetricReaderSelfMetrics >> recordCollectionResult: anOTMetricBatchResult durationSeconds: aNumber [

	| attributes errorType |
	errorType := anOTMetricBatchResult isSuccess
		             ifTrue: [ nil ]
		             ifFalse: [
				             anOTMetricBatchResult isTimeout
					             ifTrue: [ 'timeout' ]
					             ifFalse: [ 'failed' ] ].
	attributes := errorType ifNil: [ componentAttributes ] ifNotNil: [
			              componentAttributes copy
				              at: 'error.type' put: errorType;
				              yourself ].
	collectionDuration record: aNumber attributes: attributes
]
