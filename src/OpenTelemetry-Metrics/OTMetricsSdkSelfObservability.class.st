"
The metrics-backed implementation of SDK self-observability.

I translate shared SDK self-observability events into OpenTelemetry metrics using a dedicated meter. I stay signal-agnostic at the call surface while reusing small metric-set objects internally for spans, logs, exporters, and metric readers.
"
Class {
	#name : 'OTMetricsSdkSelfObservability',
	#superclass : 'OTSdkSelfObservability',
	#instVars : [
		'meter',
		'stateLock',
		'tracerMetrics',
		'loggerMetrics',
		'componentByObject',
		'spanProcessorMetricsByProcessor',
		'logProcessorMetricsByProcessor',
		'metricReaderMetricsByReader',
		'exporterMetricsBySignal'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'private' }
OTMetricsSdkSelfObservability class >> componentTypeForExporter: anObject signal: aSymbol [

	| className |
	className := anObject class name.
	aSymbol == #span ifTrue: [
			className = 'OTOtlpGrpcSpanExporter' ifTrue: [ ^ 'otlp_grpc_span_exporter' ].
			className = 'OTOtlpHttpJsonSpanExporter' ifTrue: [ ^ 'otlp_http_json_span_exporter' ].
			className = 'OTOtlpHttpProtobufSpanExporter' ifTrue: [ ^ 'otlp_http_span_exporter' ].
			className = 'OTZipkinSpanExporter' ifTrue: [ ^ 'zipkin_http_span_exporter' ] ].
	aSymbol == #log ifTrue: [
			className = 'OTOtlpGrpcLogRecordExporter' ifTrue: [ ^ 'otlp_grpc_log_exporter' ].
			className = 'OTOtlpHttpJsonLogRecordExporter' ifTrue: [ ^ 'otlp_http_json_log_exporter' ].
			className = 'OTOtlpHttpProtobufLogRecordExporter' ifTrue: [ ^ 'otlp_http_log_exporter' ] ].
	aSymbol == #metric ifTrue: [
			className = 'OTOtlpGrpcMetricExporter' ifTrue: [ ^ 'otlp_grpc_metric_exporter' ].
			className = 'OTOtlpHttpJsonMetricExporter' ifTrue: [ ^ 'otlp_http_json_metric_exporter' ].
			className = 'OTOtlpHttpProtobufMetricExporter' ifTrue: [ ^ 'otlp_http_metric_exporter' ].
			className = 'OTPrometheusMetricExporter' ifTrue: [ ^ 'prometheus_http_text_metric_exporter' ] ].
	^ className
]

{ #category : 'private' }
OTMetricsSdkSelfObservability class >> componentTypeForLogProcessor: anObject [

	| className |
	className := anObject class name.
	className = 'OTSimpleLogRecordProcessor' ifTrue: [ ^ 'simple_log_processor' ].
	className = 'OTBatchLogRecordProcessor' ifTrue: [ ^ 'batching_log_processor' ].
	^ className
]

{ #category : 'private' }
OTMetricsSdkSelfObservability class >> componentTypeForMetricReader: anObject [

	anObject class == OTPeriodicExportingMetricReader ifTrue: [ ^ 'periodic_metric_reader' ].
	^ anObject class name
]

{ #category : 'private' }
OTMetricsSdkSelfObservability class >> componentTypeForSpanProcessor: anObject [

	anObject class == OTSimpleSpanProcessor ifTrue: [ ^ 'simple_span_processor' ].
	anObject class == OTBatchSpanProcessor ifTrue: [ ^ 'batching_span_processor' ].
	^ anObject class name
]

{ #category : 'private' }
OTMetricsSdkSelfObservability class >> defaultMeterName [

	^ 'opentelemetry.sdk'
]

{ #category : 'class initialization' }
OTMetricsSdkSelfObservability class >> initialize [

	OTSdkSelfObservability registerFactory: [ self onMeterProvider: OTMeterProvider current ]
]

{ #category : 'instance creation' }
OTMetricsSdkSelfObservability class >> onMeterProvider: anOTMeterProvider [

	^ self new initializeOnMeterProvider: anOTMeterProvider
]

{ #category : 'recording' }
OTMetricsSdkSelfObservability >> adjustQueueSizeBy: anInteger forProcessor: anObject signal: aSymbol capacity: aCapacityInteger [

	| metricSet |
	metricSet := aSymbol == #span
		             ifTrue: [ self spanProcessorMetricsFor: anObject capacity: aCapacityInteger ]
		             ifFalse: [ self logProcessorMetricsFor: anObject capacity: aCapacityInteger ].
	metricSet ensureQueueCapacity: aCapacityInteger.
	metricSet adjustQueueSizeBy: anInteger
]

{ #category : 'private' }
OTMetricsSdkSelfObservability >> componentFor: anObject type: aString [

	^ stateLock critical: [ self componentForUnlocked: anObject type: aString ]
]

{ #category : 'private' }
OTMetricsSdkSelfObservability >> componentForUnlocked: anObject type: aString [

	^ componentByObject
		  at: anObject
		  ifAbsentPut: [ OTSdkSelfObservabilityComponent type: aString name: (OTSdkSelfObservability nextComponentNameForType: aString) ]
]

{ #category : 'private' }
OTMetricsSdkSelfObservability >> errorTypeFromLifecycleResult: anOTLifecycleResult [

	^ OTSdkSelfObservability lifecycleErrorTypeFor: anOTLifecycleResult
]

{ #category : 'private' }
OTMetricsSdkSelfObservability >> exporterMetricsFor: anObject signal: aSymbol [

	| byExporter component |
	^ stateLock critical: [
			  byExporter := exporterMetricsBySignal at: aSymbol.
			  byExporter at: anObject ifAbsentPut: [
					  component := self componentForUnlocked: anObject type: (self class componentTypeForExporter: anObject signal: aSymbol).
					  OTSdkExporterSelfMetrics signal: aSymbol component: component meter: meter ] ]
]

{ #category : 'initialization' }
OTMetricsSdkSelfObservability >> initializeOnMeterProvider: anOTMeterProvider [

	meter := anOTMeterProvider meterNamed: self class defaultMeterName.
	stateLock := Semaphore forMutualExclusion.
	tracerMetrics := OTSdkTracerSelfMetrics onMeter: meter.
	loggerMetrics := OTSdkLoggerSelfMetrics onMeter: meter.
	componentByObject := IdentityDictionary new.
	spanProcessorMetricsByProcessor := IdentityDictionary new.
	logProcessorMetricsByProcessor := IdentityDictionary new.
	metricReaderMetricsByReader := IdentityDictionary new.
	exporterMetricsBySignal := Dictionary new
		                           at: #span put: IdentityDictionary new;
		                           at: #log put: IdentityDictionary new;
		                           at: #metric put: IdentityDictionary new;
		                           yourself.
	^ self
]

{ #category : 'private' }
OTMetricsSdkSelfObservability >> logProcessorMetricsFor: anObject capacity: anIntegerOrNil [

	| component |
	^ stateLock critical: [
			  logProcessorMetricsByProcessor at: anObject ifAbsentPut: [
					  component := self componentForUnlocked: anObject type: (self class componentTypeForLogProcessor: anObject).
					  OTSdkProcessorSelfMetrics
						  signal: #log
						  component: component
						  meter: meter
						  queueCapacity: anIntegerOrNil ] ]
]

{ #category : 'private' }
OTMetricsSdkSelfObservability >> metricDataPointCountIn: anOTMetricSnapshot [

	^ anOTMetricSnapshot metrics inject: 0 into: [ :sum :each | sum + each points size ]
]

{ #category : 'private' }
OTMetricsSdkSelfObservability >> metricReaderMetricsFor: anObject [

	| component |
	^ stateLock critical: [
			  metricReaderMetricsByReader at: anObject ifAbsentPut: [
					  component := self componentForUnlocked: anObject type: (self class componentTypeForMetricReader: anObject).
					  OTSdkMetricReaderSelfMetrics component: component meter: meter ] ]
]

{ #category : 'private' }
OTMetricsSdkSelfObservability >> parentOriginFrom: anOTSpanContext [

	anOTSpanContext ifNil: [ ^ 'none' ].
	^ anOTSpanContext isRemote
		  ifTrue: [ 'remote' ]
		  ifFalse: [ 'local' ]
]

{ #category : 'recording' }
OTMetricsSdkSelfObservability >> recordCollectionResult: anOTMetricBatchResult forMetricReader: anObject durationSeconds: aNumber [

	(self metricReaderMetricsFor: anObject) recordCollectionResult: anOTMetricBatchResult durationSeconds: aNumber
]

{ #category : 'recording' }
OTMetricsSdkSelfObservability >> recordCreatedLog [

	loggerMetrics recordCreated
]

{ #category : 'recording' }
OTMetricsSdkSelfObservability >> recordEndedSpan: anOTSpan [

	tracerMetrics recordEndedWithSamplingResult: (self samplingResultStringForSpan: anOTSpan)
]

{ #category : 'recording' }
OTMetricsSdkSelfObservability >> recordExportFinishedFor: anExporter signal: aSymbol itemCount: anInteger result: anOTLifecycleResult durationSeconds: aNumber [

	(self exporterMetricsFor: anExporter signal: aSymbol)
		recordExportWithItemCount: anInteger
		result: anOTLifecycleResult
		durationSeconds: aNumber
]

{ #category : 'recording' }
OTMetricsSdkSelfObservability >> recordExportStartedFor: anExporter signal: aSymbol itemCount: anInteger [

	(self exporterMetricsFor: anExporter signal: aSymbol) markInflightCount: anInteger
]

{ #category : 'recording' }
OTMetricsSdkSelfObservability >> recordProcessedCount: anInteger forProcessor: anObject signal: aSymbol errorType: aStringOrNil [

	| metricSet |
	metricSet := aSymbol == #span
		             ifTrue: [ self spanProcessorMetricsFor: anObject capacity: nil ]
		             ifFalse: [ self logProcessorMetricsFor: anObject capacity: nil ].
	metricSet recordProcessedCount: anInteger errorType: aStringOrNil
]

{ #category : 'recording' }
OTMetricsSdkSelfObservability >> recordStartedSpanWithParentSpanContext: anOTSpanContext samplingResult: anOTSamplingResult [

	tracerMetrics
		recordStartedWithParentOrigin: (self parentOriginFrom: anOTSpanContext)
		samplingResult: (self samplingResultStringFrom: anOTSamplingResult)
]

{ #category : 'private' }
OTMetricsSdkSelfObservability >> samplingResultStringForSpan: anOTSpan [

	anOTSpan spanContext isValid ifFalse: [ ^ 'DROP' ].
	^ anOTSpan spanContext isSampled
		  ifTrue: [ 'RECORD_AND_SAMPLE' ]
		  ifFalse: [ 'RECORD_ONLY' ]
]

{ #category : 'private' }
OTMetricsSdkSelfObservability >> samplingResultStringFrom: anOTSamplingResult [

	anOTSamplingResult isRecordAndSample ifTrue: [ ^ 'RECORD_AND_SAMPLE' ].
	anOTSamplingResult isRecording ifTrue: [ ^ 'RECORD_ONLY' ].
	^ 'DROP'
]

{ #category : 'private' }
OTMetricsSdkSelfObservability >> secondsSinceMillisecondsClockValue: aMillisecondClockValue [

	^ OTSdkSelfObservability elapsedSecondsSinceMillisecondClockValue: aMillisecondClockValue
]

{ #category : 'private' }
OTMetricsSdkSelfObservability >> spanProcessorMetricsFor: anObject capacity: anIntegerOrNil [

	| component |
	^ stateLock critical: [
			  spanProcessorMetricsByProcessor at: anObject ifAbsentPut: [
					  component := self componentForUnlocked: anObject type: (self class componentTypeForSpanProcessor: anObject).
					  OTSdkProcessorSelfMetrics
						  signal: #span
						  component: component
						  meter: meter
						  queueCapacity: anIntegerOrNil ] ]
]
