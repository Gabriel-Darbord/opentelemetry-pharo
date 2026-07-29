"
Metric instruments for SDK processor self-observability.

I record processed span or log counts and, when relevant, maintain queue-capacity and queue-size metrics for batching processors.
"
Class {
	#name : 'OTSdkProcessorSelfMetrics',
	#superclass : 'Object',
	#instVars : [
		'processed',
		'queueCapacity',
		'queueSize',
		'currentCapacity',
		'componentAttributes'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTSdkProcessorSelfMetrics class >> signal: aSymbol component: anOTSdkSelfObservabilityComponent meter: anOTMeter queueCapacity: anIntegerOrNil [

	^ self new
		  initializeSignal: aSymbol
		  component: anOTSdkSelfObservabilityComponent
		  meter: anOTMeter
		  queueCapacity: anIntegerOrNil
]

{ #category : 'recording' }
OTSdkProcessorSelfMetrics >> adjustQueueSizeBy: anInteger [

	queueSize ifNotNil: [ queueSize add: anInteger attributes: componentAttributes ]
]

{ #category : 'recording' }
OTSdkProcessorSelfMetrics >> ensureQueueCapacity: anInteger [

	| delta |
	queueCapacity ifNil: [ ^ self ].
	delta := anInteger - currentCapacity.
	delta = 0 ifTrue: [ ^ self ].
	queueCapacity add: delta attributes: componentAttributes.
	currentCapacity := anInteger
]

{ #category : 'initialization' }
OTSdkProcessorSelfMetrics >> initializeSignal: aSymbol component: anOTSdkSelfObservabilityComponent meter: anOTMeter queueCapacity: anIntegerOrNil [

	| unitSuffix |
	componentAttributes := anOTSdkSelfObservabilityComponent attributes.
	unitSuffix := aSymbol = #span
		              ifTrue: [ '{span}' ]
		              ifFalse: [ '{log_record}' ].
	processed := anOTMeter
		             counterNamed: (aSymbol = #span
				              ifTrue: [ 'otel.sdk.processor.span.processed' ]
				              ifFalse: [ 'otel.sdk.processor.log.processed' ])
		             unit: unitSuffix
		             description: 'The number of telemetry records for which the processing has finished, either successful or failed.'
		             advice: Dictionary new.
	anIntegerOrNil ifNotNil: [
			queueCapacity := anOTMeter
				                 upDownCounterNamed: (aSymbol = #span
						                  ifTrue: [ 'otel.sdk.processor.span.queue.capacity' ]
						                  ifFalse: [ 'otel.sdk.processor.log.queue.capacity' ])
				                 unit: unitSuffix
				                 description: 'The maximum number of telemetry records the queue of a given processor can hold.'
				                 advice: Dictionary new.
			queueSize := anOTMeter
				             upDownCounterNamed: (aSymbol = #span
						              ifTrue: [ 'otel.sdk.processor.span.queue.size' ]
						              ifFalse: [ 'otel.sdk.processor.log.queue.size' ])
				             unit: unitSuffix
				             description: 'The number of telemetry records in the queue of a given processor.'
				             advice: Dictionary new.
			currentCapacity := 0.
			self ensureQueueCapacity: anIntegerOrNil ].
	^ self
]

{ #category : 'recording' }
OTSdkProcessorSelfMetrics >> recordProcessedCount: anInteger errorType: aStringOrNil [

	| attributes |
	attributes := aStringOrNil ifNil: [ componentAttributes ] ifNotNil: [
			              componentAttributes copy
				              at: 'error.type' put: aStringOrNil;
				              yourself ].
	processed add: anInteger attributes: attributes
]
