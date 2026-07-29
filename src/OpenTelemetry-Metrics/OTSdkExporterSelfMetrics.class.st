"
Metric instruments for SDK exporter self-observability.

I track exporter inflight item counts, completed export counts, and export operation duration for one exporter component and one signal kind.
"
Class {
	#name : 'OTSdkExporterSelfMetrics',
	#superclass : 'Object',
	#instVars : [
		'exported',
		'inflight',
		'operationDuration',
		'componentAttributes'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTSdkExporterSelfMetrics class >> signal: aSymbol component: anOTSdkSelfObservabilityComponent meter: anOTMeter [

	^ self new initializeSignal: aSymbol component: anOTSdkSelfObservabilityComponent meter: anOTMeter
]

{ #category : 'private' }
OTSdkExporterSelfMetrics >> attributesForResult: anOTLifecycleResult [

	| errorType |
	errorType := anOTLifecycleResult ifNil: [ 'failed' ] ifNotNil: [
			             anOTLifecycleResult isSuccess
				             ifTrue: [ nil ]
				             ifFalse: [
						             anOTLifecycleResult isTimeout
							             ifTrue: [ 'timeout' ]
							             ifFalse: [ 'failed' ] ] ].
	^ errorType ifNil: [ componentAttributes ] ifNotNil: [
			  componentAttributes copy
				  at: 'error.type' put: errorType;
				  yourself ]
]

{ #category : 'initialization' }
OTSdkExporterSelfMetrics >> initializeSignal: aSymbol component: anOTSdkSelfObservabilityComponent meter: anOTMeter [

	| metricStem unitSuffix |
	componentAttributes := anOTSdkSelfObservabilityComponent attributes.
	metricStem := aSymbol = #span
		              ifTrue: [ 'otel.sdk.exporter.span' ]
		              ifFalse: [
				              aSymbol = #log
					              ifTrue: [ 'otel.sdk.exporter.log' ]
					              ifFalse: [ 'otel.sdk.exporter.metric_data_point' ] ].
	unitSuffix := aSymbol = #span
		              ifTrue: [ '{span}' ]
		              ifFalse: [
				              aSymbol = #log
					              ifTrue: [ '{log_record}' ]
					              ifFalse: [ '{data_point}' ] ].
	exported := anOTMeter
		            counterNamed: metricStem , '.exported'
		            unit: unitSuffix
		            description: 'The number of telemetry records for which the export has finished, either successful or failed.'
		            advice: Dictionary new.
	inflight := anOTMeter
		            upDownCounterNamed: metricStem , '.inflight'
		            unit: unitSuffix
		            description: 'The number of telemetry records passed to the exporter that have not been exported yet.'
		            advice: Dictionary new.
	operationDuration := anOTMeter
		                     histogramNamed: 'otel.sdk.exporter.operation.duration'
		                     unit: 's'
		                     description: 'The duration of exporting a batch of telemetry records.'
		                     advice: { ('ExplicitBucketBoundaries' -> #(  )) } asDictionary.
	^ self
]

{ #category : 'recording' }
OTSdkExporterSelfMetrics >> markInflightCount: anInteger [

	inflight add: anInteger attributes: componentAttributes
]

{ #category : 'recording' }
OTSdkExporterSelfMetrics >> recordExportWithItemCount: anInteger result: anOTLifecycleResult durationSeconds: aNumber [

	| attributes |
	inflight add: anInteger negated attributes: componentAttributes.
	attributes := self attributesForResult: anOTLifecycleResult.
	exported add: anInteger attributes: attributes.
	operationDuration record: aNumber attributes: attributes
]
