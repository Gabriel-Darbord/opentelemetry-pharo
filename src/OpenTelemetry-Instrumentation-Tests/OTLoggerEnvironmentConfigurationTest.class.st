Class {
	#name : 'OTLoggerEnvironmentConfigurationTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'private' }
OTLoggerEnvironmentConfigurationTest >> setEnvironmentValue: aValue forKey: aKey [

	| environment currentValue |
	environment := Smalltalk os environment.
	currentValue := environment at: aKey ifAbsent: [ nil ].
	aValue
		ifNil: [ currentValue ifNotNil: [ environment removeKey: aKey ] ]
		ifNotNil: [ environment at: aKey put: aValue ]
]

{ #category : 'running' }
OTLoggerEnvironmentConfigurationTest >> setUp [

	super setUp.
	OTLoggerProvider current: nil
]

{ #category : 'running' }
OTLoggerEnvironmentConfigurationTest >> tearDown [

	[
		OTLoggerProvider configurationWarningSink: nil.
		OTLoggerProvider current: nil ]
		ensure: [ super tearDown ]
]

{ #category : 'tests' }
OTLoggerEnvironmentConfigurationTest >> testCurrentUsesBatchOtlpGrpcExporterWhenConfigured [

	self
		withEnvironmentValues: (Dictionary new
			at: 'OTEL_LOGS_EXPORTER' put: 'otlp';
			at: 'OTEL_EXPORTER_OTLP_LOGS_PROTOCOL' put: 'grpc';
			yourself)
		during: [
			| provider processor |
			provider := OTLoggerProvider current.
			self assert: provider logRecordProcessors size equals: 1.
			processor := provider logRecordProcessors first.
			self assert: processor class identicalTo: OTBatchLogRecordProcessor.
			self assert: processor exporter class identicalTo: OTOtlpGrpcLogRecordExporter ]
]

{ #category : 'tests' }
OTLoggerEnvironmentConfigurationTest >> testCurrentUsesDefaultOtlpHttpProtobufExporterWhenSettingIsAbsent [

	self
		withEnvironmentValues: Dictionary new
		during: [
			| provider processor |
			provider := OTLoggerProvider current.
			self assert: provider logRecordProcessors size equals: 1.
			processor := provider logRecordProcessors first.
			self assert: processor class identicalTo: OTBatchLogRecordProcessor.
			self
				assert: processor exporter class
				identicalTo: OTOtlpHttpProtobufLogRecordExporter ]
]

{ #category : 'tests' }
OTLoggerEnvironmentConfigurationTest >> testCurrentUsesBatchOtlpHttpJsonExporterWhenConfigured [

	self
		withEnvironmentValues: (Dictionary new
			at: 'OTEL_LOGS_EXPORTER' put: 'otlp';
			at: 'OTEL_EXPORTER_OTLP_LOGS_PROTOCOL' put: 'http/json';
			yourself)
		during: [
			| provider processor |
			provider := OTLoggerProvider current.
			self assert: provider logRecordProcessors size equals: 1.
			processor := provider logRecordProcessors first.
			self assert: processor class identicalTo: OTBatchLogRecordProcessor.
			self assert: processor exporter class identicalTo: OTOtlpHttpJsonLogRecordExporter ]
]

{ #category : 'tests' }
OTLoggerEnvironmentConfigurationTest >> testCurrentUsesBatchOtlpHttpProtobufExporterByDefault [

	self
		withEnvironmentValues: (Dictionary new
			at: 'OTEL_LOGS_EXPORTER' put: 'otlp';
			yourself)
		during: [
			| provider processor |
			provider := OTLoggerProvider current.
			self assert: provider logRecordProcessors size equals: 1.
			processor := provider logRecordProcessors first.
			self assert: processor class identicalTo: OTBatchLogRecordProcessor.
			self
				assert: processor exporter class
				identicalTo: OTOtlpHttpProtobufLogRecordExporter ]
]

{ #category : 'tests' }
OTLoggerEnvironmentConfigurationTest >> testCurrentUsesMultipleConfiguredLogExportersWithExporterSpecificProcessors [

	self
		withEnvironmentValues: (Dictionary new
			at: 'OTEL_LOGS_EXPORTER' put: 'console,otlp';
			yourself)
		during: [
			| provider processors |
			provider := OTLoggerProvider current.
			processors := provider logRecordProcessors.
			self assert: processors size equals: 2.
			self assert: processors first class identicalTo: OTSimpleLogRecordProcessor.
			self assert: processors second class identicalTo: OTBatchLogRecordProcessor.
			self
				assert: processors first exporter class
				identicalTo: OTConsoleLogRecordExporter.
			self
				assert: processors second exporter class
				identicalTo: OTOtlpHttpProtobufLogRecordExporter ]
]

{ #category : 'tests' }
OTLoggerEnvironmentConfigurationTest >> testCurrentUsesConsoleAliasWithSimpleProcessor [

	self
		withEnvironmentValues: (Dictionary new
			at: 'OTEL_LOGS_EXPORTER' put: 'logging';
			yourself)
		during: [
			| provider processor |
			provider := OTLoggerProvider current.
			self assert: provider logRecordProcessors size equals: 1.
			processor := provider logRecordProcessors first.
			self assert: processor class identicalTo: OTSimpleLogRecordProcessor.
			self assert: processor exporter class identicalTo: OTConsoleLogRecordExporter ]
]

{ #category : 'tests' }
OTLoggerEnvironmentConfigurationTest >> testCurrentUsesOtlpStdoutExporterWithBatchProcessor [

	self
		withEnvironmentValues: (Dictionary new
			at: 'OTEL_LOGS_EXPORTER' put: 'otlp/stdout';
			yourself)
		during: [
			| provider processor |
			provider := OTLoggerProvider current.
			self assert: provider logRecordProcessors size equals: 1.
			processor := provider logRecordProcessors first.
			self assert: processor class identicalTo: OTBatchLogRecordProcessor.
			self assert: processor exporter class identicalTo: OTOtlpStdoutLogRecordExporter ]
]

{ #category : 'tests' }
OTLoggerEnvironmentConfigurationTest >> testCurrentUsesNoProcessorsWhenLogExportIsDisabled [

	self
		withEnvironmentValues: (Dictionary new
			at: 'OTEL_LOGS_EXPORTER' put: 'none';
			yourself)
		during: [ self assert: OTLoggerProvider current logRecordProcessors isEmpty ]
]

{ #category : 'tests' }
OTLoggerEnvironmentConfigurationTest >> testCurrentWarnsAboutInvalidBatchProcessorEnvironmentValuesAndUsesDefaults [

	self withWarningsDo: [ :warnings |
		self
			withEnvironmentValues: (Dictionary new
				at: 'OTEL_LOGS_EXPORTER' put: 'otlp';
				at: 'OTEL_BLRP_MAX_QUEUE_SIZE' put: 'invalid';
				at: 'OTEL_BLRP_MAX_EXPORT_BATCH_SIZE' put: '-10';
				at: 'OTEL_BLRP_SCHEDULE_DELAY' put: '-1';
				at: 'OTEL_BLRP_EXPORT_TIMEOUT' put: 'not-a-number';
				yourself)
			during: [
				| processor |
				processor := OTLoggerProvider current logRecordProcessors first.
				self assert: processor maxQueueSize equals: 2048.
				self assert: processor maxExportBatchSize equals: 512.
				self assert: processor scheduledDelayMillis equals: 1000.
				self assert: processor exportTimeoutMillis equals: 30000 ].
		self
			assert: warnings asArray
			equals: #(
				'OpenTelemetry batch log record processor configuration was invalid and has been ignored for ''OTEL_BLRP_MAX_QUEUE_SIZE'': ''invalid'''
				'OpenTelemetry batch log record processor configuration was invalid and has been ignored for ''OTEL_BLRP_MAX_EXPORT_BATCH_SIZE'': ''-10'''
				'OpenTelemetry batch log record processor configuration was invalid and has been ignored for ''OTEL_BLRP_SCHEDULE_DELAY'': ''-1'''
				'OpenTelemetry batch log record processor configuration was invalid and has been ignored for ''OTEL_BLRP_EXPORT_TIMEOUT'': ''not-a-number''' ) ]
]

{ #category : 'tests' }
OTLoggerEnvironmentConfigurationTest >> testCurrentWarnsAboutUnknownLogExporterNameAndFallsBackToDefaultExporter [

	self withWarningsDo: [ :warnings |
		self
			withEnvironmentValues: (Dictionary new
				at: 'OTEL_LOGS_EXPORTER' put: 'mystery';
				yourself)
			during: [
				| processor |
				processor := OTLoggerProvider current logRecordProcessors first.
				self
					assert: processor exporter class
					identicalTo: OTOtlpHttpProtobufLogRecordExporter ].
		self assert: warnings size equals: 1.
		self assert: warnings first equals:
			'OpenTelemetry logs exporter name was unrecognized and has been ignored: ''mystery''' ]
]

{ #category : 'tests' }
OTLoggerEnvironmentConfigurationTest >> testCurrentWarnsWhenNoneIsCombinedWithOtherLogExportersAndFallsBackToDefaultExporter [

	self withWarningsDo: [ :warnings |
		self
			withEnvironmentValues: (Dictionary new
				at: 'OTEL_LOGS_EXPORTER' put: 'console,none';
				yourself)
			during: [
				| processor |
				processor := OTLoggerProvider current logRecordProcessors first.
				self
					assert: processor exporter class
					identicalTo: OTOtlpHttpProtobufLogRecordExporter ].
		self assert: warnings size equals: 1.
		self assert: warnings first equals:
			'OpenTelemetry logs exporter configuration mixes ''none'' with other exporters and has been ignored: ''console,none''' ]
]

{ #category : 'tests' }
OTLoggerEnvironmentConfigurationTest >> testCurrentFallsBackToHttpProtobufWhenOtlpLogsProtocolIsInvalid [

	self withWarningsDo: [ :warnings |
		self
			withEnvironmentValues: (Dictionary new
				at: 'OTEL_LOGS_EXPORTER' put: 'otlp';
				at: 'OTEL_EXPORTER_OTLP_LOGS_PROTOCOL' put: 'udp';
				yourself)
			during: [
				| processor |
				processor := OTLoggerProvider current logRecordProcessors first.
				self
					assert: processor exporter class
					identicalTo: OTOtlpHttpProtobufLogRecordExporter ].
		self assert: warnings isEmpty ]
]

{ #category : 'private' }
OTLoggerEnvironmentConfigurationTest >> withEnvironmentValues: aDictionary during: aBlock [

	| absent environment snapshot |
	absent := Object new.
	environment := Smalltalk os environment.
	snapshot := Dictionary new.
	aDictionary keysAndValuesDo: [ :key :value |
		snapshot at: key put: (environment at: key ifAbsent: [ absent ]).
		self setEnvironmentValue: value forKey: key ].
	[
		OTLoggerProvider current: nil.
		^ aBlock value ]
		ensure: [
			snapshot keysAndValuesDo: [ :key :value |
				self
					setEnvironmentValue: (value == absent ifTrue: [ nil ] ifFalse: [ value ])
					forKey: key ].
			OTLoggerProvider current: nil ]
]

{ #category : 'private' }
OTLoggerEnvironmentConfigurationTest >> withWarningsDo: aBlock [

	| warnings |
	warnings := OrderedCollection new.
	OTLoggerProvider configurationWarningSink: [ :message | warnings add: message ].
	[
		^ aBlock value: warnings ]
		ensure: [ OTLoggerProvider configurationWarningSink: nil ]
]
