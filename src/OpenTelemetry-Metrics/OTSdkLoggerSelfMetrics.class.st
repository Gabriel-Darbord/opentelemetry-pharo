"
Metric instruments for `otel.sdk.log.*` self-observability.

I record the number of log records submitted through enabled SDK loggers.
"
Class {
	#name : 'OTSdkLoggerSelfMetrics',
	#superclass : 'Object',
	#instVars : [
		'createdLogs'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTSdkLoggerSelfMetrics class >> onMeter: anOTMeter [

	^ self new initializeOnMeter: anOTMeter
]

{ #category : 'initialization' }
OTSdkLoggerSelfMetrics >> initializeOnMeter: anOTMeter [

	createdLogs := anOTMeter
		               counterNamed: 'otel.sdk.log.created'
		               unit: '{log_record}'
		               description: 'The number of logs submitted to enabled SDK Loggers.'
		               advice: Dictionary new.
	^ self
]

{ #category : 'recording' }
OTSdkLoggerSelfMetrics >> recordCreated [

	createdLogs add: 1
]
