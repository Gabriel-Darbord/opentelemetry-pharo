Class {
	#name : 'OTMetricEnvironmentConfigurationTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Metrics-Tests',
	#package : 'OpenTelemetry-Metrics-Tests'
}

{ #category : 'private' }
OTMetricEnvironmentConfigurationTest >> setEnvironmentValue: aValue forKey: aKey [

	| currentValue environment |
	environment := Smalltalk os environment.
	currentValue := environment at: aKey ifAbsent: [ nil ].
	aValue ifNil: [ currentValue ifNotNil: [ environment removeKey: aKey ] ] ifNotNil: [ environment at: aKey put: aValue ]
]

{ #category : 'running' }
OTMetricEnvironmentConfigurationTest >> setUp [

	super setUp.
	OTMeterProvider current: nil
]

{ #category : 'running' }
OTMetricEnvironmentConfigurationTest >> tearDown [

	[
		OTMeterProvider configurationWarningSink: nil.
		OTMeterProvider current: nil.
		OTMeterProvider reset ] ensure: [ super tearDown ]
]

{ #category : 'tests' }
OTMetricEnvironmentConfigurationTest >> testCurrentConfiguresPrometheusMetricReader [

	self withWarningsDo: [ :warnings |
			self
				withEnvironmentValues: (Dictionary new
						 at: 'OTEL_METRICS_EXPORTER' put: 'prometheus';
						 at: 'OTEL_EXPORTER_PROMETHEUS_PORT' put: '0';
						 yourself)
				during: [
						| metricReader |
						metricReader := OTMeterProvider current metricReaders first.
						self assert: metricReader class identicalTo: OTPrometheusMetricReader.
						self assert: metricReader host equals: 'localhost'.
						self assert: metricReader port > 0 ].
			self assert: warnings isEmpty ]
]

{ #category : 'tests' }
OTMetricEnvironmentConfigurationTest >> testCurrentConfiguresPrometheusResourceConstantLabels [

	self withWarningsDo: [ :warnings |
			self
				withEnvironmentValues: (Dictionary new
						 at: 'OTEL_METRICS_EXPORTER' put: 'prometheus';
						 at: 'OTEL_EXPORTER_PROMETHEUS_PORT' put: '0';
						 at: 'OTEL_EXPORTER_PROMETHEUS_RESOURCE_CONSTANT_LABELS' put: 'service.name, service.namespace';
						 yourself)
				during: [
						| filter metricReader |
						metricReader := OTMeterProvider current metricReaders first.
						filter := metricReader resourceConstantLabels.
						self assert: filter class identicalTo: OTMetricAttributeFilter.
						self assert: filter includedKeys equals: #( 'service.name' 'service.namespace' ).
						self assert: filter excludedKeys isNil ].
			self assert: warnings isEmpty ]
]

{ #category : 'tests' }
OTMetricEnvironmentConfigurationTest >> testCurrentConfiguresPrometheusTranslationStrategy [

	self withWarningsDo: [ :warnings |
			self
				withEnvironmentValues: (Dictionary new
						 at: 'OTEL_METRICS_EXPORTER' put: 'prometheus';
						 at: 'OTEL_EXPORTER_PROMETHEUS_PORT' put: '0';
						 at: 'OTEL_EXPORTER_PROMETHEUS_TRANSLATION_STRATEGY' put: 'NoTranslation';
						 yourself)
				during: [
						| metricReader |
						metricReader := OTMeterProvider current metricReaders first.
						self assert: metricReader class identicalTo: OTPrometheusMetricReader.
						self assert: metricReader translationStrategy equals: #noTranslation ].
			self assert: warnings isEmpty ]
]

{ #category : 'tests' }
OTMetricEnvironmentConfigurationTest >> testCurrentTreatsEmptyEnvironmentValuesAsUnset [

	self withWarningsDo: [ :warnings |
			self
				withEnvironmentValues: (Dictionary new
						 at: 'OTEL_SDK_DISABLED' put: '';
						 at: 'OTEL_METRICS_EXPORTER' put: '';
						 at: 'OTEL_METRIC_EXPORT_INTERVAL' put: '';
						 at: 'OTEL_METRIC_EXPORT_TIMEOUT' put: '';
						 yourself)
				during: [
						| provider reader |
						provider := OTMeterProvider current.
						self assert: provider class identicalTo: OTMeterProvider.
						self assert: provider metricReaders size equals: 1.
						reader := provider metricReaders first.
						self assert: reader class identicalTo: OTPeriodicExportingMetricReader.
						self assert: reader exporter class identicalTo: OTOtlpHttpProtobufMetricExporter.
						self assert: reader exportIntervalMillis equals: 60000.
						self assert: reader exportTimeoutMillis equals: 30000 ].
			self assert: warnings isEmpty ]
]

{ #category : 'tests' }
OTMetricEnvironmentConfigurationTest >> testCurrentTreatsNonTrueSdkDisabledValueAsFalse [

	self
		withEnvironmentValues: (Dictionary new
				 at: 'OTEL_SDK_DISABLED' put: '1';
				 yourself)
		during: [ self deny: OTMeterProvider current class identicalTo: OTNoopMeterProvider ]
]

{ #category : 'tests' }
OTMetricEnvironmentConfigurationTest >> testCurrentUsesConfiguredExemplarFilter [

	self
		withEnvironmentValues: (Dictionary new
				 at: 'OTEL_METRICS_EXEMPLAR_FILTER' put: 'always_off';
				 yourself)
		during: [ self assert: OTMeterProvider current exemplarFilter class identicalTo: OTAlwaysOffMetricExemplarFilter ]
]

{ #category : 'tests' }
OTMetricEnvironmentConfigurationTest >> testCurrentUsesConfiguredMetricReaderIntervalAndTimeout [

	self
		withEnvironmentValues: (Dictionary new
				 at: 'OTEL_METRICS_EXPORTER' put: 'otlp';
				 at: 'OTEL_METRIC_EXPORT_INTERVAL' put: '12345';
				 at: 'OTEL_METRIC_EXPORT_TIMEOUT' put: '54321';
				 yourself)
		during: [
				| reader |
				reader := OTMeterProvider current metricReaders first.
				self assert: reader exportIntervalMillis equals: 12345.
				self assert: reader exportTimeoutMillis equals: 54321 ]
]

{ #category : 'tests' }
OTMetricEnvironmentConfigurationTest >> testCurrentUsesConsoleExporterWithShorterDefaultInterval [

	self
		withEnvironmentValues: (Dictionary new
				 at: 'OTEL_METRICS_EXPORTER' put: 'console';
				 yourself)
		during: [
				| provider reader |
				provider := OTMeterProvider current.
				self assert: provider metricReaders size equals: 1.
				reader := provider metricReaders first.
				self assert: reader class identicalTo: OTPeriodicExportingMetricReader.
				self assert: reader exporter class identicalTo: OTConsoleMetricExporter.
				self assert: reader exportIntervalMillis equals: 10000.
				self assert: reader exportTimeoutMillis equals: 30000 ]
]

{ #category : 'tests' }
OTMetricEnvironmentConfigurationTest >> testCurrentUsesCumulativeTemporalityPreferenceByDefaultForOtlpExporter [

	self
		withEnvironmentValues: (Dictionary new
				 at: 'OTEL_METRICS_EXPORTER' put: 'otlp';
				 yourself)
		during: [
				| counter histogram provider reader upDownCounter |
				provider := OTMeterProvider current.
				reader := provider metricReaders first.
				counter := (provider meterNamed: 'demo.metrics') counterNamed: 'requests.total'.
				upDownCounter := (provider meterNamed: 'demo.metrics') upDownCounterNamed: 'requests.active'.
				histogram := (provider meterNamed: 'demo.metrics') histogramNamed: 'request.duration'.
				self assert: (reader temporalityFor: counter) equals: #cumulative.
				self assert: (reader temporalityFor: upDownCounter) equals: #cumulative.
				self assert: (reader temporalityFor: histogram) equals: #cumulative ]
]

{ #category : 'tests' }
OTMetricEnvironmentConfigurationTest >> testCurrentUsesDefaultOtlpHttpProtobufExporterWhenSettingIsAbsent [

	self withEnvironmentValues: Dictionary new during: [
			| provider reader |
			provider := OTMeterProvider current.
			self assert: provider metricReaders size equals: 1.
			reader := provider metricReaders first.
			self assert: reader class identicalTo: OTPeriodicExportingMetricReader.
			self assert: reader exporter class identicalTo: OTOtlpHttpProtobufMetricExporter.
			self assert: reader exportIntervalMillis equals: 60000.
			self assert: reader exportTimeoutMillis equals: 30000 ]
]

{ #category : 'tests' }
OTMetricEnvironmentConfigurationTest >> testCurrentUsesDeltaTemporalityPreferenceForOtlpExporter [

	self
		withEnvironmentValues: (Dictionary new
				 at: 'OTEL_METRICS_EXPORTER' put: 'otlp';
				 at: 'OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE' put: 'delta';
				 yourself)
		during: [
				| asyncCounter counter histogram provider reader upDownCounter |
				provider := OTMeterProvider current.
				reader := provider metricReaders first.
				counter := (provider meterNamed: 'demo.metrics') counterNamed: 'requests.total'.
				upDownCounter := (provider meterNamed: 'demo.metrics') upDownCounterNamed: 'requests.active'.
				histogram := (provider meterNamed: 'demo.metrics') histogramNamed: 'request.duration'.
				asyncCounter := (provider meterNamed: 'demo.metrics')
					                observableCounterNamed: 'runtime.page_faults'
					                callbacks: #(  )
					                unit: '1'
					                description: ''
					                advice: Dictionary new.
				self assert: (reader temporalityFor: counter) equals: #delta.
				self assert: (reader temporalityFor: histogram) equals: #delta.
				self assert: (reader temporalityFor: asyncCounter) equals: #delta.
				self assert: (reader temporalityFor: upDownCounter) equals: #cumulative ]
]

{ #category : 'tests' }
OTMetricEnvironmentConfigurationTest >> testCurrentUsesExplicitBucketHistogramAggregationByDefaultForOtlpExporter [

	self
		withEnvironmentValues: (Dictionary new
				 at: 'OTEL_METRICS_EXPORTER' put: 'otlp';
				 yourself)
		during: [
				| histogram provider reader |
				provider := OTMeterProvider current.
				reader := provider metricReaders first.
				histogram := (provider meterNamed: 'demo.metrics') histogramNamed: 'request.duration'.
				self assert: (reader aggregationFor: histogram) equals: #default ]
]

{ #category : 'tests' }
OTMetricEnvironmentConfigurationTest >> testCurrentUsesExplicitBucketHistogramAggregationByDefaultForPrometheusExporter [

	self
		withEnvironmentValues: (Dictionary new
				 at: 'OTEL_METRICS_EXPORTER' put: 'prometheus';
				 at: 'OTEL_EXPORTER_PROMETHEUS_PORT' put: '0';
				 yourself)
		during: [
				| histogram provider reader |
				provider := OTMeterProvider current.
				reader := provider metricReaders first.
				histogram := (provider meterNamed: 'demo.metrics') histogramNamed: 'request.duration'.
				self assert: (reader aggregationFor: histogram) equals: #default ]
]

{ #category : 'tests' }
OTMetricEnvironmentConfigurationTest >> testCurrentUsesExponentialHistogramAggregationWhenConfiguredForOtlpExporter [

	self
		withEnvironmentValues: (Dictionary new
				 at: 'OTEL_METRICS_EXPORTER' put: 'otlp';
				 at: 'OTEL_EXPORTER_OTLP_METRICS_DEFAULT_HISTOGRAM_AGGREGATION' put: 'base2_exponential_bucket_histogram';
				 yourself)
		during: [
				| histogram provider reader |
				provider := OTMeterProvider current.
				reader := provider metricReaders first.
				histogram := (provider meterNamed: 'demo.metrics') histogramNamed: 'request.duration'.
				self assert: (reader aggregationFor: histogram) equals: #base2ExponentialBucketHistogram ]
]

{ #category : 'tests' }
OTMetricEnvironmentConfigurationTest >> testCurrentUsesExponentialHistogramAggregationWhenConfiguredForPrometheusExporter [

	self
		withEnvironmentValues: (Dictionary new
				 at: 'OTEL_METRICS_EXPORTER' put: 'prometheus';
				 at: 'OTEL_EXPORTER_PROMETHEUS_PORT' put: '0';
				 at: 'OTEL_EXPORTER_PROMETHEUS_DEFAULT_HISTOGRAM_AGGREGATION' put: 'base2_exponential_bucket_histogram';
				 yourself)
		during: [
				| counter histogram provider reader |
				provider := OTMeterProvider current.
				reader := provider metricReaders first.
				counter := (provider meterNamed: 'demo.metrics') counterNamed: 'requests.total'.
				histogram := (provider meterNamed: 'demo.metrics') histogramNamed: 'request.duration'.
				self assert: (reader aggregationFor: histogram) equals: #base2ExponentialBucketHistogram.
				self assert: (reader aggregationFor: counter) equals: #default ]
]

{ #category : 'tests' }
OTMetricEnvironmentConfigurationTest >> testCurrentUsesLoggingAliasWithConsoleExporter [

	self
		withEnvironmentValues: (Dictionary new
				 at: 'OTEL_METRICS_EXPORTER' put: 'logging';
				 yourself)
		during: [
				| provider reader |
				provider := OTMeterProvider current.
				self assert: provider metricReaders size equals: 1.
				reader := provider metricReaders first.
				self assert: reader class identicalTo: OTPeriodicExportingMetricReader.
				self assert: reader exporter class identicalTo: OTConsoleMetricExporter.
				self assert: reader exportIntervalMillis equals: 10000.
				self assert: reader exportTimeoutMillis equals: 30000 ]
]

{ #category : 'tests' }
OTMetricEnvironmentConfigurationTest >> testCurrentUsesLowMemoryTemporalityPreferenceForOtlpExporter [

	self
		withEnvironmentValues: (Dictionary new
				 at: 'OTEL_METRICS_EXPORTER' put: 'otlp';
				 at: 'OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE' put: 'lowmemory';
				 yourself)
		during: [
				| asyncCounter counter histogram provider reader upDownCounter |
				provider := OTMeterProvider current.
				reader := provider metricReaders first.
				counter := (provider meterNamed: 'demo.metrics') counterNamed: 'requests.total'.
				upDownCounter := (provider meterNamed: 'demo.metrics') upDownCounterNamed: 'requests.active'.
				histogram := (provider meterNamed: 'demo.metrics') histogramNamed: 'request.duration'.
				asyncCounter := (provider meterNamed: 'demo.metrics')
					                observableCounterNamed: 'runtime.page_faults'
					                callbacks: #(  )
					                unit: '1'
					                description: ''
					                advice: Dictionary new.
				self assert: (reader temporalityFor: counter) equals: #delta.
				self assert: (reader temporalityFor: histogram) equals: #delta.
				self assert: (reader temporalityFor: asyncCounter) equals: #cumulative.
				self assert: (reader temporalityFor: upDownCounter) equals: #cumulative ]
]

{ #category : 'tests' }
OTMetricEnvironmentConfigurationTest >> testCurrentUsesMultipleConfiguredMetricExporters [

	self
		withEnvironmentValues: (Dictionary new
				 at: 'OTEL_METRICS_EXPORTER' put: 'console,otlp';
				 yourself)
		during: [
				| provider readers |
				provider := OTMeterProvider current.
				readers := provider metricReaders.
				self assert: readers size equals: 2.
				self assert: readers first exporter class identicalTo: OTConsoleMetricExporter.
				self assert: readers second exporter class identicalTo: OTOtlpHttpProtobufMetricExporter ]
]

{ #category : 'tests' }
OTMetricEnvironmentConfigurationTest >> testCurrentUsesNoReadersWhenMetricExportIsDisabled [

	self
		withEnvironmentValues: (Dictionary new
				 at: 'OTEL_METRICS_EXPORTER' put: 'none';
				 yourself)
		during: [ self assert: OTMeterProvider current metricReaders isEmpty ]
]

{ #category : 'tests' }
OTMetricEnvironmentConfigurationTest >> testCurrentUsesNoopMeterProviderWhenSdkIsDisabled [

	self
		withEnvironmentValues: (Dictionary new
				 at: 'OTEL_SDK_DISABLED' put: 'TRUE';
				 yourself)
		during: [ self assert: OTMeterProvider current class identicalTo: OTNoopMeterProvider ]
]

{ #category : 'tests' }
OTMetricEnvironmentConfigurationTest >> testCurrentUsesOtlpGrpcMetricExporterWhenConfigured [

	self
		withEnvironmentValues: (Dictionary new
				 at: 'OTEL_METRICS_EXPORTER' put: 'otlp';
				 at: 'OTEL_EXPORTER_OTLP_METRICS_PROTOCOL' put: 'grpc';
				 yourself)
		during: [
				| reader |
				reader := OTMeterProvider current metricReaders first.
				self assert: reader exporter class identicalTo: OTOtlpGrpcMetricExporter ]
]

{ #category : 'tests' }
OTMetricEnvironmentConfigurationTest >> testCurrentUsesOtlpStdoutExporterWhenConfigured [

	self
		withEnvironmentValues: (Dictionary new
				 at: 'OTEL_METRICS_EXPORTER' put: 'otlp/stdout';
				 yourself)
		during: [
				| provider reader |
				provider := OTMeterProvider current.
				reader := provider metricReaders first.
				self assert: reader exporter class identicalTo: OTOtlpStdoutMetricExporter ]
]

{ #category : 'tests' }
OTMetricEnvironmentConfigurationTest >> testCurrentUsesTraceBasedExemplarFilterByDefault [

	self
		withEnvironmentValues: Dictionary new
		during: [ self assert: OTMeterProvider current exemplarFilter class identicalTo: OTTraceBasedMetricExemplarFilter ]
]

{ #category : 'tests' }
OTMetricEnvironmentConfigurationTest >> testCurrentWarnsAboutInvalidMetricReaderEnvironmentValuesAndUsesDefaults [

	self withWarningsDo: [ :warnings |
			self
				withEnvironmentValues: (Dictionary new
						 at: 'OTEL_METRICS_EXPORTER' put: 'console';
						 at: 'OTEL_METRIC_EXPORT_INTERVAL' put: 'invalid';
						 at: 'OTEL_METRIC_EXPORT_TIMEOUT' put: '-1';
						 yourself)
				during: [
						| reader |
						reader := OTMeterProvider current metricReaders first.
						self assert: reader exportIntervalMillis equals: 10000.
						self assert: reader exportTimeoutMillis equals: 30000 ].
			self
				assert: warnings asArray
				equals:
					#( 'OpenTelemetry periodic metric reader configuration was invalid and has been ignored for ''OTEL_METRIC_EXPORT_INTERVAL'': ''invalid'''
					   'OpenTelemetry periodic metric reader configuration was invalid and has been ignored for ''OTEL_METRIC_EXPORT_TIMEOUT'': ''-1''' ) ]
]

{ #category : 'tests' }
OTMetricEnvironmentConfigurationTest >> testCurrentWarnsAboutInvalidOtlpHistogramAggregationAndFallsBackToExplicitBuckets [

	self withWarningsDo: [ :warnings |
			self
				withEnvironmentValues: (Dictionary new
						 at: 'OTEL_METRICS_EXPORTER' put: 'otlp';
						 at: 'OTEL_EXPORTER_OTLP_METRICS_DEFAULT_HISTOGRAM_AGGREGATION' put: 'wide-open-spaces';
						 yourself)
				during: [
						| histogram provider reader |
						provider := OTMeterProvider current.
						reader := provider metricReaders first.
						histogram := (provider meterNamed: 'demo.metrics') histogramNamed: 'request.duration'.
						self assert: (reader aggregationFor: histogram) equals: #default ].
			self assert: warnings size equals: 1.
			self
				assert: warnings first
				equals: 'OpenTelemetry OTLP metrics default histogram aggregation was invalid and has been ignored: ''wide-open-spaces''' ]
]

{ #category : 'tests' }
OTMetricEnvironmentConfigurationTest >> testCurrentWarnsAboutInvalidOtlpTemporalityPreferenceAndFallsBackToCumulative [

	self withWarningsDo: [ :warnings |
			self
				withEnvironmentValues: (Dictionary new
						 at: 'OTEL_METRICS_EXPORTER' put: 'otlp';
						 at: 'OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE' put: 'sideways';
						 yourself)
				during: [
						| counter provider reader |
						provider := OTMeterProvider current.
						reader := provider metricReaders first.
						counter := (provider meterNamed: 'demo.metrics') counterNamed: 'requests.total'.
						self assert: (reader temporalityFor: counter) equals: #cumulative ].
			self assert: warnings size equals: 1.
			self
				assert: warnings first
				equals: 'OpenTelemetry OTLP metrics temporality preference was invalid and has been ignored: ''sideways''' ]
]

{ #category : 'tests' }
OTMetricEnvironmentConfigurationTest >> testCurrentWarnsAboutUnknownMetricExporterNameAndFallsBackToDefaultExporter [

	self withWarningsDo: [ :warnings |
			self
				withEnvironmentValues: (Dictionary new
						 at: 'OTEL_METRICS_EXPORTER' put: 'mystery';
						 yourself)
				during: [
						| reader |
						reader := OTMeterProvider current metricReaders first.
						self assert: reader exporter class identicalTo: OTOtlpHttpProtobufMetricExporter ].
			self assert: warnings size equals: 1.
			self assert: warnings first equals: 'OpenTelemetry metrics exporter name was unrecognized and has been ignored: ''mystery''' ]
]

{ #category : 'tests' }
OTMetricEnvironmentConfigurationTest >> testCurrentWarnsWhenNoneIsCombinedWithOtherMetricExportersAndFallsBackToDefaultExporter [

	self withWarningsDo: [ :warnings |
			self
				withEnvironmentValues: (Dictionary new
						 at: 'OTEL_METRICS_EXPORTER' put: 'console,none';
						 yourself)
				during: [
						| reader |
						reader := OTMeterProvider current metricReaders first.
						self assert: reader exporter class identicalTo: OTOtlpHttpProtobufMetricExporter ].
			self assert: warnings size equals: 1.
			self
				assert: warnings first
				equals:
				'OpenTelemetry metrics exporter configuration mixes ''none'' with other exporters and has been ignored: ''console,none''' ]
]

{ #category : 'private' }
OTMetricEnvironmentConfigurationTest >> withEnvironmentValues: aDictionary during: aBlock [

	| absent effectiveValues environment managedKeys snapshot |
	absent := Object new.
	environment := Smalltalk os environment.
	effectiveValues := aDictionary copy.
	managedKeys := (environment keys select: [ :each | each beginsWith: 'OTEL_' ]) asOrderedCollection.
	effectiveValues keysDo: [ :each | (managedKeys includes: each) ifFalse: [ managedKeys add: each ] ].
	snapshot := Dictionary new.
	managedKeys do: [ :key |
			| value |
			value := effectiveValues at: key ifAbsent: [ nil ].
			snapshot at: key put: (environment at: key ifAbsent: [ absent ]).
			self setEnvironmentValue: value forKey: key ].
	[
		OTMeterProvider current: nil.
		^ aBlock value ] ensure: [
			managedKeys do: [ :key |
					| value |
					value := snapshot at: key.
					self
						setEnvironmentValue: (value == absent
								 ifTrue: [ nil ]
								 ifFalse: [ value ])
						forKey: key ].
			OTMeterProvider current: nil ]
]

{ #category : 'private' }
OTMetricEnvironmentConfigurationTest >> withWarningsDo: aBlock [

	| warnings |
	warnings := OrderedCollection new.
	OTMeterProvider configurationWarningSink: [ :message | warnings add: message ].
	[ ^ aBlock value: warnings ] ensure: [ OTMeterProvider configurationWarningSink: nil ]
]
