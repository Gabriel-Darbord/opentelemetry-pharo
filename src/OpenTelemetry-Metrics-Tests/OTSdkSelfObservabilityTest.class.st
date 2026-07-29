Class {
	#name : 'OTSdkSelfObservabilityTest',
	#superclass : 'TestCase',
	#instVars : [
		'previousSelfObservability',
		'selfObservabilityProvider',
		'selfObservabilityReader'
	],
	#category : 'OpenTelemetry-Metrics-Tests',
	#package : 'OpenTelemetry-Metrics-Tests'
}

{ #category : 'private' }
OTSdkSelfObservabilityTest >> installMetricsBackedSelfObservability [

	selfObservabilityProvider := OTMeterProvider new.
	selfObservabilityReader := OTInMemoryMetricReader new.
	selfObservabilityProvider addMetricReader: selfObservabilityReader.
	OTSdkSelfObservability current: (OTMetricsSdkSelfObservability onMeterProvider: selfObservabilityProvider)
]

{ #category : 'private' }
OTSdkSelfObservabilityTest >> metricNamed: aString in: anOTMetricSnapshot [

	^ anOTMetricSnapshot metrics detect: [ :each | each name = aString ] ifNone: [ self fail: 'Expected metric named ' , aString ]
]

{ #category : 'private' }
OTSdkSelfObservabilityTest >> pointIn: anOTMetricData matching: aDictionary [

	^ anOTMetricData points
		  detect: [ :each |
			  aDictionary associations allSatisfy: [ :association |
				  (each attributes at: association key ifAbsent: [ nil ]) = association value ] ]
		  ifNone: [ self fail: 'Expected point matching attributes' ]
]

{ #category : 'running' }
OTSdkSelfObservabilityTest >> setUp [

	super setUp.
	OTMetricsSdkSelfObservability initialize.
	previousSelfObservability := {
		                             OTSdkSelfObservability current.
		                             OTSdkSelfObservability enabled }.
	selfObservabilityProvider := nil.
	selfObservabilityReader := nil
]

{ #category : 'running' }
OTSdkSelfObservabilityTest >> tearDown [

	previousSelfObservability ifNotNil: [
			OTSdkSelfObservability enabled: previousSelfObservability second.
			OTSdkSelfObservability current: previousSelfObservability first ].
	super tearDown
]

{ #category : 'tests' }
OTSdkSelfObservabilityTest >> testLogSelfObservabilityRecordsCreatedAndExportedLogs [

	| createdMetric createdPoint durationMetric durationPoint exportedMetric exportedPoint logger processedMetric processedPoint provider snapshot processor |
	self installMetricsBackedSelfObservability.
	provider := OTLoggerProvider new.
	processor := OTSimpleLogRecordProcessor new.
	processor exporter: OTNoopLogRecordExporter new.
	provider addLogRecordProcessor: processor.
	logger := provider loggerNamed: 'demo.logs'.
	self assert: (logger emitBody: 'hello').
	snapshot := selfObservabilityReader collectSnapshot.
	createdMetric := self metricNamed: 'otel.sdk.log.created' in: snapshot.
	createdPoint := self pointIn: createdMetric matching: Dictionary new.
	self assert: createdPoint value equals: 1.
	processedMetric := self metricNamed: 'otel.sdk.processor.log.processed' in: snapshot.
	processedPoint := self pointIn: processedMetric matching: { ('otel.component.type' -> 'simple_log_processor') } asDictionary.
	self assert: processedPoint value equals: 1.
	exportedMetric := self metricNamed: 'otel.sdk.exporter.log.exported' in: snapshot.
	exportedPoint := self pointIn: exportedMetric matching: { ('otel.component.type' -> 'OTNoopLogRecordExporter') } asDictionary.
	self assert: exportedPoint value equals: 1.
	durationMetric := self metricNamed: 'otel.sdk.exporter.operation.duration' in: snapshot.
	durationPoint := self pointIn: durationMetric matching: { ('otel.component.type' -> 'OTNoopLogRecordExporter') } asDictionary.
	self assert: durationPoint count equals: 1
]

{ #category : 'tests' }
OTSdkSelfObservabilityTest >> testMetricSelfObservabilityRecordsCollectionAndExport [

	| collectionMetric collectionPoint durationMetric durationPoint exportedMetric exportedPoint exporter provider reader snapshot |
	self installMetricsBackedSelfObservability.
	exporter := OTInMemoryMetricExporter new.
	provider := OTMeterProvider new.
	reader := OTPeriodicExportingMetricReader exporter: exporter.
	reader exportIntervalMillis: 1000000.
	provider addMetricReader: reader.
	((provider meterNamed: 'demo.metrics') counterNamed: 'requests.total') add: 2.
	self assert: reader collect metrics size equals: 1.
	snapshot := selfObservabilityReader collectSnapshot.
	collectionMetric := self metricNamed: 'otel.sdk.metric_reader.collection.duration' in: snapshot.
	collectionPoint := self pointIn: collectionMetric matching: { ('otel.component.type' -> 'periodic_metric_reader') } asDictionary.
	self assert: collectionPoint count equals: 1.
	exportedMetric := self metricNamed: 'otel.sdk.exporter.metric_data_point.exported' in: snapshot.
	exportedPoint := self pointIn: exportedMetric matching: { ('otel.component.type' -> 'OTInMemoryMetricExporter') } asDictionary.
	self assert: exportedPoint value equals: 1.
	durationMetric := self metricNamed: 'otel.sdk.exporter.operation.duration' in: snapshot.
	durationPoint := self pointIn: durationMetric matching: { ('otel.component.type' -> 'OTInMemoryMetricExporter') } asDictionary.
	self assert: durationPoint count equals: 1
]

{ #category : 'tests' }
OTSdkSelfObservabilityTest >> testResetPreservesMetricsFactory [

	| current |
	OTSdkSelfObservability reset.
	OTSdkSelfObservability enable.
	current := OTSdkSelfObservability current.
	self assert: current class identicalTo: OTMetricsSdkSelfObservability
]

{ #category : 'tests' }
OTSdkSelfObservabilityTest >> testTraceSelfObservabilityRecordsSpanLifecycleAndExport [

	| durationMetric durationPoint exportedMetric exportedPoint liveMetric livePoint processedMetric processedPoint provider snapshot span startedMetric startedPoint tracer processor |
	self installMetricsBackedSelfObservability.
	provider := OTTracerProvider new.
	processor := OTSimpleSpanProcessor new.
	processor exporter: OTNoopSpanExporter new.
	provider addSpanProcessor: processor.
	tracer := provider tracerNamed: 'demo.trace'.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	span end.
	snapshot := selfObservabilityReader collectSnapshot.
	startedMetric := self metricNamed: 'otel.sdk.span.started' in: snapshot.
	startedPoint := self pointIn: startedMetric matching: {
			                ('otel.span.parent.origin' -> 'none').
			                ('otel.span.sampling_result' -> 'RECORD_AND_SAMPLE') } asDictionary.
	self assert: startedPoint value equals: 1.
	liveMetric := self metricNamed: 'otel.sdk.span.live' in: snapshot.
	livePoint := self pointIn: liveMetric matching: { ('otel.span.sampling_result' -> 'RECORD_AND_SAMPLE') } asDictionary.
	self assert: livePoint value equals: 0.
	processedMetric := self metricNamed: 'otel.sdk.processor.span.processed' in: snapshot.
	processedPoint := self pointIn: processedMetric matching: { ('otel.component.type' -> 'simple_span_processor') } asDictionary.
	self assert: processedPoint value equals: 1.
	exportedMetric := self metricNamed: 'otel.sdk.exporter.span.exported' in: snapshot.
	exportedPoint := self pointIn: exportedMetric matching: { ('otel.component.type' -> 'OTNoopSpanExporter') } asDictionary.
	self assert: exportedPoint value equals: 1.
	durationMetric := self metricNamed: 'otel.sdk.exporter.operation.duration' in: snapshot.
	durationPoint := self pointIn: durationMetric matching: { ('otel.component.type' -> 'OTNoopSpanExporter') } asDictionary.
	self assert: durationPoint count equals: 1
]
