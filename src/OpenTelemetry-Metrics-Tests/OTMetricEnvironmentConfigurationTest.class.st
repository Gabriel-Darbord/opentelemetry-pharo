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
	aValue
		ifNil: [ currentValue ifNotNil: [ environment removeKey: aKey ] ]
		ifNotNil: [ environment at: aKey put: aValue ]
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
		OTMeterProvider reset ]
		ensure: [ super tearDown ]
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
OTMetricEnvironmentConfigurationTest >> testCurrentUsesDefaultOtlpHttpProtobufExporterWhenSettingIsAbsent [

	self
		withEnvironmentValues: Dictionary new
		during: [
			| provider reader |
			provider := OTMeterProvider current.
			self assert: provider metricReaders size equals: 1.
			reader := provider metricReaders first.
			self assert: reader class identicalTo: OTPeriodicExportingMetricReader.
			self
				assert: reader exporter class
				identicalTo: OTOtlpHttpProtobufMetricExporter.
			self assert: reader exportIntervalMillis equals: 60000.
			self assert: reader exportTimeoutMillis equals: 30000 ]
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
			self
				assert: readers second exporter class
				identicalTo: OTOtlpHttpProtobufMetricExporter ]
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
			equals: #(
				'OpenTelemetry periodic metric reader configuration was invalid and has been ignored for ''OTEL_METRIC_EXPORT_INTERVAL'': ''invalid'''
				'OpenTelemetry periodic metric reader configuration was invalid and has been ignored for ''OTEL_METRIC_EXPORT_TIMEOUT'': ''-1''' ) ]
]

{ #category : 'tests' }
OTMetricEnvironmentConfigurationTest >> testCurrentWarnsAboutPrometheusExporterAndFallsBackToDefaultExporter [

	self withWarningsDo: [ :warnings |
		self
			withEnvironmentValues: (Dictionary new
				at: 'OTEL_METRICS_EXPORTER' put: 'prometheus';
				yourself)
			during: [
				| reader |
				reader := OTMeterProvider current metricReaders first.
				self
					assert: reader exporter class
					identicalTo: OTOtlpHttpProtobufMetricExporter ].
		self assert: warnings size equals: 1.
		self assert: warnings first equals:
			'OpenTelemetry metrics exporter name is recognized but not supported by this SDK yet and has been ignored: ''prometheus''' ]
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
				self
					assert: reader exporter class
					identicalTo: OTOtlpHttpProtobufMetricExporter ].
		self assert: warnings size equals: 1.
		self assert: warnings first equals:
			'OpenTelemetry metrics exporter name was unrecognized and has been ignored: ''mystery''' ]
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
				self
					assert: reader exporter class
					identicalTo: OTOtlpHttpProtobufMetricExporter ].
		self assert: warnings size equals: 1.
		self assert: warnings first equals:
			'OpenTelemetry metrics exporter configuration mixes ''none'' with other exporters and has been ignored: ''console,none''' ]
]

{ #category : 'tests' }
OTMetricEnvironmentConfigurationTest >> testCurrentWarnsWhenOtlpMetricsProtocolIsUnsupportedAndFallsBackToHttpProtobuf [

	self withWarningsDo: [ :warnings |
		self
			withEnvironmentValues: (Dictionary new
				at: 'OTEL_METRICS_EXPORTER' put: 'otlp';
				at: 'OTEL_EXPORTER_OTLP_METRICS_PROTOCOL' put: 'grpc';
				yourself)
			during: [
				| reader |
				reader := OTMeterProvider current metricReaders first.
				self
					assert: reader exporter class
					identicalTo: OTOtlpHttpProtobufMetricExporter ].
		self assert: warnings size equals: 1.
		self assert: warnings first equals:
			'OpenTelemetry OTLP metrics exporter protocol was unsupported and defaulted to http/protobuf: ''grpc''' ]
]

{ #category : 'private' }
OTMetricEnvironmentConfigurationTest >> withEnvironmentValues: aDictionary during: aBlock [

	| absent environment snapshot |
	absent := Object new.
	environment := Smalltalk os environment.
	snapshot := Dictionary new.
	aDictionary keysAndValuesDo: [ :key :value |
		snapshot at: key put: (environment at: key ifAbsent: [ absent ]).
		self setEnvironmentValue: value forKey: key ].
	[
		OTMeterProvider current: nil.
		^ aBlock value ]
		ensure: [
			snapshot keysAndValuesDo: [ :key :value |
				self
					setEnvironmentValue: (value == absent ifTrue: [ nil ] ifFalse: [ value ])
					forKey: key ].
			OTMeterProvider current: nil ]
]

{ #category : 'private' }
OTMetricEnvironmentConfigurationTest >> withWarningsDo: aBlock [

	| warnings |
	warnings := OrderedCollection new.
	OTMeterProvider configurationWarningSink: [ :message | warnings add: message ].
	[
		^ aBlock value: warnings ]
		ensure: [ OTMeterProvider configurationWarningSink: nil ]
]
