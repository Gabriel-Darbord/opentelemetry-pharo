"
I provide a shared autoconfiguration view that reads either the process
environment or a declarative migration config file projected onto the existing
environment-variable surface.
"
Class {
	#name : 'OTConfigurationSource',
	#superclass : 'Object',
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'private - caching' }
OTConfigurationSource class >> cachedConfigurationFilePath [

	^ OTClassStateStore
		valueAt: #otConfigurationFilePath
		forClass: self
		ifAbsent: [ nil ]
]

{ #category : 'private - caching' }
OTConfigurationSource class >> cachedConfigurationFilePath: aStringOrNil [

	aStringOrNil
		ifNil: [
			OTClassStateStore
				removeValueAt: #otConfigurationFilePath
				forClass: self
				ifAbsent: [  ] ]
		ifNotNil: [
			OTClassStateStore
				valueAt: #otConfigurationFilePath
				forClass: self
				put: aStringOrNil ]
]

{ #category : 'private - caching' }
OTConfigurationSource class >> cachedEnvironmentValues [

	^ OTClassStateStore
		valueAt: #otConfigurationEnvironmentValues
		forClass: self
		ifAbsent: [ nil ]
]

{ #category : 'private - caching' }
OTConfigurationSource class >> cachedEnvironmentValues: aDictionaryOrNil [

	aDictionaryOrNil
		ifNil: [
			OTClassStateStore
				removeValueAt: #otConfigurationEnvironmentValues
				forClass: self
				ifAbsent: [  ] ]
		ifNotNil: [
			OTClassStateStore
				valueAt: #otConfigurationEnvironmentValues
				forClass: self
				put: aDictionaryOrNil ]
]

{ #category : 'private - caching' }
OTConfigurationSource class >> cachedParsedConfiguration [

	^ OTClassStateStore
		valueAt: #otConfigurationParsedConfiguration
		forClass: self
		ifAbsent: [ nil ]
]

{ #category : 'private - caching' }
OTConfigurationSource class >> cachedParsedConfiguration: aDictionaryOrNil [

	aDictionaryOrNil
		ifNil: [
			OTClassStateStore
				removeValueAt: #otConfigurationParsedConfiguration
				forClass: self
				ifAbsent: [  ] ]
		ifNotNil: [
			OTClassStateStore
				valueAt: #otConfigurationParsedConfiguration
				forClass: self
				put: aDictionaryOrNil ]
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> configurationFilePath [

	| path |
	path := self rawEnvironmentValueAt: 'OTEL_CONFIG_FILE'.
	^ path ifNil: [ self rawEnvironmentValueAt: 'OTEL_EXPERIMENTAL_CONFIG_FILE' ] ifNotNil: [ path ]
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> configuredEnvironmentValues [

	self configuredConfiguration.
	^ self cachedEnvironmentValues
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> configuredConfiguration [

	| cachedPath configuration path values |
	path := self configurationFilePath.
	cachedPath := self cachedConfigurationFilePath.
	(cachedPath = path
		and: [ cachedPath notNil and: [ self cachedParsedConfiguration notNil ] ]) ifTrue: [
		^ self cachedParsedConfiguration ].
	path ifNil: [
		self cachedConfigurationFilePath: nil.
		self cachedEnvironmentValues: nil.
		self cachedParsedConfiguration: nil.
		^ nil ].
	configuration := self parsedConfigurationFromConfigurationFileAt: path.
	values := self projectedEnvironmentValuesFromConfiguration: configuration.
	self cachedConfigurationFilePath: path.
	self cachedParsedConfiguration: configuration.
	self cachedEnvironmentValues: values.
	^ configuration
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> configuredLoggerConfigurator [

	| configuration loggerProvider node |
	configuration := self configuredConfiguration.
	configuration ifNil: [ ^ nil ].
	loggerProvider := self dictionaryValueAt: 'logger_provider' in: configuration.
	node := self
		dictionaryValueAt: 'logger_configurator/development'
		in: loggerProvider.
	node ifNil: [ ^ nil ].
	^ self loggerConfiguratorFrom: node
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> configuredMeterConfigurator [

	| configuration meterProvider node |
	configuration := self configuredConfiguration.
	configuration ifNil: [ ^ nil ].
	meterProvider := self dictionaryValueAt: 'meter_provider' in: configuration.
	node := self
		dictionaryValueAt: 'meter_configurator/development'
		in: meterProvider.
	node ifNil: [ ^ nil ].
	^ self meterConfiguratorFrom: node
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> configuredMetricViews [

	| configuration meterProvider views |
	configuration := self configuredConfiguration.
	configuration ifNil: [ ^ #() ].
	meterProvider := self dictionaryValueAt: 'meter_provider' in: configuration.
	views := self sequenceValueAt: 'views' in: meterProvider.
	views ifNil: [ ^ #() ].
	^ views collect: [ :each | self metricViewFrom: each ]
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> configuredTracerConfigurator [

	| configuration tracerProvider node |
	configuration := self configuredConfiguration.
	configuration ifNil: [ ^ nil ].
	tracerProvider := self dictionaryValueAt: 'tracer_provider' in: configuration.
	node := self
		dictionaryValueAt: 'tracer_configurator/development'
		in: tracerProvider.
	node ifNil: [ ^ nil ].
	^ self tracerConfiguratorFrom: node
]

{ #category : 'private - projection' }
OTConfigurationSource class >> encodedResourceAttributesFrom: aDictionary [

	aDictionary isEmpty ifTrue: [ ^ nil ].
	^ String streamContents: [ :stream |
		aDictionary associationsDo: [ :each |
			stream position > 0 ifTrue: [ stream nextPut: $, ].
			stream
				nextPutAll: each key asString urlEncoded;
				nextPut: $=;
				nextPutAll: each value asString urlEncoded ] ]
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> environmentValuesFromConfigurationFileAt: aString [

	| configuration |
	configuration := self parsedConfigurationFromConfigurationFileAt: aString.
	^ self projectedEnvironmentValuesFromConfiguration: configuration
]

{ #category : 'accessing' }
OTConfigurationSource class >> environmentValueAt: aString [

	| configuredValues trimmed value |
	configuredValues := self configuredEnvironmentValues.
	configuredValues ifNil: [ ^ self rawEnvironmentValueAt: aString ].
	value := configuredValues at: aString ifAbsent: [ ^ nil ].
	trimmed := value asString trimBoth.
	^ trimmed isEmpty ifTrue: [ nil ] ifFalse: [ trimmed ]
]

{ #category : 'private - projection' }
OTConfigurationSource class >> exportEnvironmentNameForSignalNamed: aString [

	^ 'OTEL_', aString, '_EXPORTER'
]

{ #category : 'private - projection' }
OTConfigurationSource class >> exporterNodeFromProcessorNode: aDictionary [

	^ self dictionaryValueAt: 'exporter' in: aDictionary
]

{ #category : 'private - projection' }
OTConfigurationSource class >> headersListStringFrom: aCollection [

	aCollection ifNil: [ ^ nil ].
	^ String streamContents: [ :stream |
		aCollection doWithIndex: [ :each :index |
			| key value |
			key := self stringValueAt: 'name' in: each.
			value := self stringValueAt: 'value' in: each.
			(key isNil or: [ value isNil ]) ifFalse: [
				index > 1 ifTrue: [ stream nextPut: $, ].
				stream
					nextPutAll: key urlEncoded;
					nextPut: $=;
					nextPutAll: value urlEncoded ] ] ]
]

{ #category : 'private - projection' }
OTConfigurationSource class >> nodeKindsStringFrom: aCollection [

	aCollection ifNil: [ ^ nil ].
	^ String streamContents: [ :stream |
		aCollection do: [ :each |
			| association |
			association := self samplerAssociationFrom: each.
			stream position > 0 ifTrue: [ stream nextPut: $, ].
			stream nextPutAll: association key asString ] ]
]

{ #category : 'private - projection' }
OTConfigurationSource class >> dictionaryValueAt: aKey in: aDictionary [

	| value |
	aDictionary ifNil: [ ^ nil ].
	value := aDictionary at: aKey ifAbsent: [ ^ nil ].
	^ (value isKindOf: Dictionary) ifTrue: [ value ] ifFalse: [ nil ]
]

{ #category : 'private - projection' }
OTConfigurationSource class >> firstNodeNamed: aKey inSequence: aCollection [

	aCollection ifNil: [ ^ nil ].
	aCollection do: [ :each |
		(self dictionaryValueAt: aKey in: each) ifNotNil: [ :value | ^ value ] ].
	^ nil
]

{ #category : 'private - projection' }
OTConfigurationSource class >> loggerConfigFrom: aDictionary [

	| config enabled |
	aDictionary ifNil: [ ^ OTLoggerConfig default ].
	config := OTLoggerConfig default.
	enabled := self enabledValueFrom: aDictionary.
	enabled ifNotNil: [ config enabled: enabled ].
	(self loggerSeverityValueAt: 'minimum_severity' in: aDictionary) ifNotNil: [ :value |
		config minimumSeverity: value ].
	(self booleanValueAt: 'trace_based' in: aDictionary) ifNotNil: [ :value |
		config traceBased: value ].
	^ config
]

{ #category : 'private - projection' }
OTConfigurationSource class >> loggerConfigFor: anInstrumentationScope rules: aCollection default: anOTLoggerConfig [

	^ self
		namedScopeConfigFor: anInstrumentationScope
		rules: aCollection
		default: anOTLoggerConfig
]

{ #category : 'private - projection' }
OTConfigurationSource class >> loggerConfiguratorFrom: aDictionary [

	| defaultConfig rules |
	defaultConfig := self
		loggerConfigFrom: (self dictionaryValueAt: 'default_config' in: aDictionary).
	rules := self
		loggerConfiguratorRulesFrom: (self sequenceValueAt: 'loggers' in: aDictionary).
	^ [ :scope |
		self
			loggerConfigFor: scope
			rules: rules
			default: defaultConfig ]
]

{ #category : 'private - projection' }
OTConfigurationSource class >> loggerConfiguratorRuleFrom: aDictionary [

	^ self
		namedScopeRuleFrom: aDictionary
		configBlock: [ :configNode | self loggerConfigFrom: configNode ]
]

{ #category : 'private - projection' }
OTConfigurationSource class >> loggerConfiguratorRulesFrom: aCollection [

	aCollection ifNil: [ ^ #() ].
	^ aCollection collect: [ :each | self loggerConfiguratorRuleFrom: each ]
]

{ #category : 'private - projection' }
OTConfigurationSource class >> loggerNamePattern: aPattern matches: aString [

	aPattern = '*' ifTrue: [ ^ true ].
	((aPattern includes: $*) or: [ aPattern includes: $? ]) ifTrue: [
		^ self
			loggerNamePattern: aPattern
			at: 1
			matches: aString
			at: 1 ].
	^ aPattern = aString
]

{ #category : 'private - projection' }
OTConfigurationSource class >> loggerNamePattern: aPattern at: patternIndex matches: aString at: stringIndex [

	| character |
	patternIndex > aPattern size ifTrue: [ ^ stringIndex > aString size ].
	character := aPattern at: patternIndex.
	character = $* ifTrue: [
		patternIndex = aPattern size ifTrue: [ ^ true ].
		stringIndex to: aString size + 1 do: [ :eachIndex |
			(self
				loggerNamePattern: aPattern
				at: patternIndex + 1
				matches: aString
				at: eachIndex) ifTrue: [ ^ true ] ].
		^ false ].
	stringIndex > aString size ifTrue: [ ^ false ].
	(character = $? or: [ character = (aString at: stringIndex) ]) ifFalse: [ ^ false ].
	^ self
		loggerNamePattern: aPattern
		at: patternIndex + 1
		matches: aString
		at: stringIndex + 1
]

{ #category : 'private - projection' }
OTConfigurationSource class >> loggerSeverityValueAt: aKey in: aDictionary [

	| value |
	aDictionary ifNil: [ ^ nil ].
	value := aDictionary at: aKey ifAbsent: [ ^ nil ].
	value ifNil: [ ^ nil ].
	value isInteger ifTrue: [ ^ OTSeverity normalize: value ].
	(value isString or: [ value isSymbol ]) ifFalse: [ ^ nil ].
	^ OTSeverity fromName: value
]

{ #category : 'private - projection' }
OTConfigurationSource class >> meterConfigFrom: aDictionary [

	| enabled |
	enabled := self enabledValueFrom: aDictionary.
	^ OTMeterConfig enabled:
		(enabled
			ifNil: [ true ]
			ifNotNil: [ enabled ])
]

{ #category : 'private - projection' }
OTConfigurationSource class >> meterConfiguratorFrom: aDictionary [

	| defaultConfig rules |
	defaultConfig := self
		meterConfigFrom: (self dictionaryValueAt: 'default_config' in: aDictionary).
	rules := self
		namedScopeRulesFrom: (self sequenceValueAt: 'meters' in: aDictionary)
		configBlock: [ :configNode | self meterConfigFrom: configNode ].
	^ [ :scope |
		self
			namedScopeConfigFor: scope
			rules: rules
			default: defaultConfig ]
]

{ #category : 'private - projection' }
OTConfigurationSource class >> namedScopeConfigFor: anInstrumentationScope rules: aCollection default: anObject [

	| scopeName |
	scopeName := anInstrumentationScope name.
	aCollection do: [ :each |
		(self loggerNamePattern: each key matches: scopeName) ifTrue: [
			^ each value ] ].
	^ anObject
]

{ #category : 'private - projection' }
OTConfigurationSource class >> namedScopeRuleFrom: aDictionary configBlock: aBlock [

	| configNode name |
	name := self stringValueAt: 'name' in: aDictionary.
	name ifNil: [
		Error signal: 'Declarative scope configurator entries require a name' ].
	configNode := self dictionaryValueAt: 'config' in: aDictionary.
	configNode ifNil: [
		Error signal: 'Declarative scope configurator entries require a config' ].
	^ name -> (aBlock value: configNode)
]

{ #category : 'private - projection' }
OTConfigurationSource class >> namedScopeRulesFrom: aCollection configBlock: aBlock [

	aCollection ifNil: [ ^ #() ].
	^ aCollection collect: [ :each |
		self namedScopeRuleFrom: each configBlock: aBlock ]
]

{ #category : 'private - projection' }
OTConfigurationSource class >> metricViewAggregationParametersFor: anAssociation [

	| kind options |
	kind := anAssociation key.
	options := anAssociation value ifNil: [ OrderedDictionary new ].
	(#( 'default' 'drop' 'last_value' 'sum' ) includes: kind) ifTrue: [ ^ nil ].
	kind = 'explicit_bucket_histogram' ifTrue: [
		^ self explicitBucketHistogramAggregationParametersFrom: options ].
	kind = 'base2_exponential_bucket_histogram' ifTrue: [
		^ self base2ExponentialHistogramAggregationParametersFrom: options ].
	Error signal: 'Unsupported declarative metric view aggregation: ', kind printString
]

{ #category : 'private - projection' }
OTConfigurationSource class >> metricViewAttributeKeysFrom: aDictionary [

	| attributeKeys excluded included |
	attributeKeys := self dictionaryValueAt: 'attribute_keys' in: aDictionary.
	attributeKeys ifNil: [ ^ nil ].
	included := self stringCollectionValueAt: 'included' in: attributeKeys.
	excluded := self stringCollectionValueAt: 'excluded' in: attributeKeys.
	included ifNil: [
		excluded ifNotNil: [
			Error signal:
				'Declarative metric views with excluded-only attribute_keys are not representable by OTMetricView' ].
		^ nil ].
	excluded ifNil: [ ^ included ].
	^ included reject: [ :each | excluded includes: each ]
]

{ #category : 'private - projection' }
OTConfigurationSource class >> metricViewFrom: aDictionary [

	| selector stream view |
	view := OTMetricView new.
	selector := self dictionaryValueAt: 'selector' in: aDictionary.
	selector ifNotNil: [ self configureMetricView: view selectorFrom: selector ].
	stream := self dictionaryValueAt: 'stream' in: aDictionary.
	stream ifNotNil: [ self configureMetricView: view streamFrom: stream ].
	^ view
]

{ #category : 'private - projection' }
OTConfigurationSource class >> mergeResourceAttributesFromListValue: aString into: anOrderedDictionary [

	aString ifNil: [ ^ anOrderedDictionary ].
	(aString substrings: ',') do: [ :each |
		| entry key separator value |
		entry := each trimBoth.
		entry ifNotEmpty: [
			separator := entry indexOf: $=.
			separator > 0 ifFalse: [
				Error signal: 'Malformed resource attribute entry in declarative configuration' ].
			key := (entry copyFrom: 1 to: separator - 1) urlDecoded.
			value := (entry copyFrom: separator + 1 to: entry size) urlDecoded.
			anOrderedDictionary at: key put: value ] ].
	^ anOrderedDictionary
]

{ #category : 'private - projection' }
OTConfigurationSource class >> singleAssociationFrom: aDictionary describedAs: aString [

	aDictionary ifNil: [
		Error signal: 'Declarative configuration ', aString, ' nodes must not be nil' ].
	aDictionary associations size = 1 ifFalse: [
		Error signal:
			'Declarative configuration ', aString, ' nodes must contain exactly one entry' ].
	^ aDictionary associations first
}

{ #category : 'private - projection' }
OTConfigurationSource class >> projectAttributeLimitsFrom: aDictionary into: anEnvironment [

	| attributeLimits |
	attributeLimits := self dictionaryValueAt: 'attribute_limits' in: aDictionary.
	attributeLimits ifNil: [ ^ self ].
	self
		put: 'OTEL_ATTRIBUTE_COUNT_LIMIT'
		from: 'attribute_count_limit'
		in: attributeLimits
		into: anEnvironment.
	self
		put: 'OTEL_ATTRIBUTE_VALUE_LENGTH_LIMIT'
		from: 'attribute_value_length_limit'
		in: attributeLimits
		into: anEnvironment
]

{ #category : 'private - projection' }
OTConfigurationSource class >> projectBatchProcessorNode: aDictionary prefix: aString into: anEnvironment [

	aDictionary ifNil: [ ^ self ].
	self put: aString , '_SCHEDULE_DELAY' from: 'schedule_delay' in: aDictionary into: anEnvironment.
	self put: aString , '_EXPORT_TIMEOUT' from: 'export_timeout' in: aDictionary into: anEnvironment.
	self put: aString , '_MAX_QUEUE_SIZE' from: 'max_queue_size' in: aDictionary into: anEnvironment.
	self put: aString , '_MAX_EXPORT_BATCH_SIZE' from: 'max_export_batch_size' in: aDictionary into: anEnvironment
]

{ #category : 'private - projection' }
OTConfigurationSource class >> projectCommonSettingsFrom: aConfiguration into: anEnvironment [

	self put: 'OTEL_SDK_DISABLED' from: 'disabled' in: aConfiguration into: anEnvironment.
	self put: 'OTEL_LOG_LEVEL' from: 'log_level' in: aConfiguration into: anEnvironment.
	self projectAttributeLimitsFrom: aConfiguration into: anEnvironment.
	self projectPropagatorsFrom: aConfiguration into: anEnvironment.
	self projectResourceFrom: aConfiguration into: anEnvironment
]

{ #category : 'private - projection' }
OTConfigurationSource class >> projectExporterConfigurationNode: aDictionary signalNamed: aString into: anEnvironment [

	| endpoint exporterName exporterOptions exporterType headers signalPrefix tls |
	aDictionary ifNil: [ ^ self ].
	aDictionary associations size = 1 ifFalse: [
		Error signal: 'Declarative configuration exporter nodes must contain exactly one exporter' ].
	exporterType := aDictionary associations first key.
	exporterOptions := aDictionary associations first value ifNil: [ OrderedDictionary new ].
	signalPrefix := 'OTEL_EXPORTER_OTLP_', aString, '_'.
	exporterType = 'console' ifTrue: [
		^ self ].
	exporterType = 'zipkin' ifTrue: [
		aString = 'TRACES' ifFalse: [
			Error signal: 'Zipkin declarative configuration is only supported for traces' ].
		self put: 'OTEL_EXPORTER_ZIPKIN_ENDPOINT' from: 'endpoint' in: exporterOptions into: anEnvironment.
		self put: 'OTEL_EXPORTER_ZIPKIN_TIMEOUT' from: 'timeout' in: exporterOptions into: anEnvironment.
		^ self ].
	exporterType = 'prometheus' ifTrue: [
		aString = 'METRICS' ifFalse: [
			Error signal: 'Prometheus declarative configuration is only supported for metrics' ].
		self put: 'OTEL_EXPORTER_PROMETHEUS_HOST' from: 'host' in: exporterOptions into: anEnvironment.
		self put: 'OTEL_EXPORTER_PROMETHEUS_PORT' from: 'port' in: exporterOptions into: anEnvironment.
		^ self ].
	exporterName := exporterType = 'otlp_grpc'
		ifTrue: [ 'grpc' ]
		ifFalse: [
			exporterType = 'otlp_http'
				ifTrue: [ 'http/protobuf' ]
				ifFalse: [ Error signal: 'Unsupported declarative exporter type: ', exporterType printString ] ].
	anEnvironment at: signalPrefix , 'PROTOCOL' put: exporterName.
	endpoint := self stringValueAt: 'endpoint' in: exporterOptions.
	endpoint ifNotNil: [ anEnvironment at: signalPrefix , 'ENDPOINT' put: endpoint ].
	self put: signalPrefix , 'COMPRESSION' from: 'compression' in: exporterOptions into: anEnvironment.
	self put: signalPrefix , 'TIMEOUT' from: 'timeout' in: exporterOptions into: anEnvironment.
	headers := self
		headersListStringFrom:
			(self sequenceValueAt: 'headers_list' in: exporterOptions).
	headers ifNotNil: [ anEnvironment at: signalPrefix , 'HEADERS' put: headers ].
	tls := self dictionaryValueAt: 'tls' in: exporterOptions.
	tls ifNil: [ ^ self ].
	self put: signalPrefix , 'CERTIFICATE' from: 'ca_file' in: tls into: anEnvironment.
	self put: signalPrefix , 'CLIENT_KEY' from: 'key_file' in: tls into: anEnvironment.
	self put: signalPrefix , 'CLIENT_CERTIFICATE' from: 'cert_file' in: tls into: anEnvironment
]

{ #category : 'private - projection' }
OTConfigurationSource class >> projectExporterNode: aDictionary signalNamed: aString into: anEnvironment [

	| exporterName |
	aDictionary ifNil: [ ^ self ].
	exporterName := self projectedExporterEnvironmentNameFrom: aDictionary signalNamed: aString.
	anEnvironment at: (self exportEnvironmentNameForSignalNamed: aString) put: exporterName.
	self projectExporterConfigurationNode: aDictionary signalNamed: aString into: anEnvironment.
	^ self
]

{ #category : 'private - projection' }
OTConfigurationSource class >> projectLoggerProviderFrom: aConfiguration into: anEnvironment [

	| loggerProvider |
	loggerProvider := self dictionaryValueAt: 'logger_provider' in: aConfiguration.
	loggerProvider ifNil: [ ^ self ].
	self projectLogRecordLimitsFrom: loggerProvider into: anEnvironment.
	self
		projectProcessorSequenceFrom: loggerProvider
		signalNamed: 'LOGS'
		batchPrefix: 'OTEL_BLRP'
		into: anEnvironment
]

{ #category : 'private - projection' }
OTConfigurationSource class >> projectMeterProviderFrom: aConfiguration into: anEnvironment [

	| meterProvider |
	meterProvider := self dictionaryValueAt: 'meter_provider' in: aConfiguration.
	meterProvider ifNil: [ ^ self ].
	self put: 'OTEL_METRICS_EXEMPLAR_FILTER' fromAnyOf: #( 'exemplar_filter' 'exemplar' ) in: meterProvider into: anEnvironment.
	self projectMetricReadersFrom: meterProvider into: anEnvironment
]

{ #category : 'private - projection' }
OTConfigurationSource class >> projectProcessorSequenceFrom: aDictionary signalNamed: aString batchPrefix: anotherString into: anEnvironment [

	| batchSettings exporters processors |
	processors := self sequenceValueAt: 'processors' in: aDictionary.
	processors ifNil: [ ^ self ].
	processors ifEmpty: [
		anEnvironment at: (self exportEnvironmentNameForSignalNamed: aString) put: 'none'.
		^ self ].
	exporters := self
		projectedExporterNodesFromProcessors: processors
		signalNamed: aString.
	batchSettings := self
		sharedBatchProcessorSettingsFrom: processors.
	batchSettings ifNotNil: [
		self
			projectBatchProcessorEnvironmentSettings: batchSettings
			prefix: anotherString
			into: anEnvironment ].
	anEnvironment
		at: (self exportEnvironmentNameForSignalNamed: aString)
		put: (self projectedExporterSelectionFrom: exporters).
	exporters values do: [ :each |
		self projectExporterConfigurationNode: each signalNamed: aString into: anEnvironment ].
	^ self
]

{ #category : 'private - projection' }
OTConfigurationSource class >> projectBatchProcessorEnvironmentSettings: aDictionary prefix: aString into: anEnvironment [

	aDictionary ifNil: [ ^ self ].
	self put: aString , '_SCHEDULE_DELAY' from: 'schedule_delay' in: aDictionary into: anEnvironment.
	self put: aString , '_EXPORT_TIMEOUT' from: 'export_timeout' in: aDictionary into: anEnvironment.
	self put: aString , '_MAX_QUEUE_SIZE' from: 'max_queue_size' in: aDictionary into: anEnvironment.
	self put: aString , '_MAX_EXPORT_BATCH_SIZE' from: 'max_export_batch_size' in: aDictionary into: anEnvironment.
	^ self
]

{ #category : 'private - projection' }
OTConfigurationSource class >> projectMetricReadersFrom: aDictionary into: anEnvironment [

	| exporters metricExporterSettings periodicSettings readers |
	readers := self sequenceValueAt: 'readers' in: aDictionary.
	readers ifNil: [ ^ self ].
	readers ifEmpty: [
		anEnvironment at: 'OTEL_METRICS_EXPORTER' put: 'none'.
		^ self ].
	exporters := self projectedMetricExporterNodesFromReaders: readers.
	periodicSettings := self sharedPeriodicMetricReaderSettingsFrom: readers.
	periodicSettings ifNotNil: [
		self put: 'OTEL_METRIC_EXPORT_INTERVAL' from: 'interval' in: periodicSettings into: anEnvironment.
		self put: 'OTEL_METRIC_EXPORT_TIMEOUT' from: 'timeout' in: periodicSettings into: anEnvironment ].
	metricExporterSettings := self sharedOtlpMetricExporterSettingsFromReaders: readers.
	metricExporterSettings ifNotNil: [
		self
			put: 'OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE'
			from: 'temporality_preference'
			in: metricExporterSettings
			into: anEnvironment.
		self
			put: 'OTEL_EXPORTER_OTLP_METRICS_DEFAULT_HISTOGRAM_AGGREGATION'
			from: 'default_histogram_aggregation'
			in: metricExporterSettings
			into: anEnvironment ].
	anEnvironment
		at: 'OTEL_METRICS_EXPORTER'
		put: (self projectedExporterSelectionFrom: exporters).
	exporters values do: [ :each |
		self projectExporterConfigurationNode: each signalNamed: 'METRICS' into: anEnvironment ].
	^ self
]

{ #category : 'private - projection' }
OTConfigurationSource class >> projectLogRecordLimitsFrom: aDictionary into: anEnvironment [

	| limits |
	limits := self dictionaryValueAt: 'limits' in: aDictionary.
	limits ifNil: [ ^ self ].
	self
		put: 'OTEL_LOGRECORD_ATTRIBUTE_COUNT_LIMIT'
		from: 'attribute_count_limit'
		in: limits
		into: anEnvironment.
	self
		put: 'OTEL_LOGRECORD_ATTRIBUTE_VALUE_LENGTH_LIMIT'
		from: 'attribute_value_length_limit'
		in: limits
		into: anEnvironment
]

{ #category : 'private - projection' }
OTConfigurationSource class >> projectPropagatorsFrom: aConfiguration into: anEnvironment [

	| compositeNodes compositeList propagator |
	propagator := self dictionaryValueAt: 'propagator' in: aConfiguration.
	propagator ifNil: [ ^ self ].
	compositeNodes := self sequenceValueAt: 'composite' in: propagator.
	compositeList := self
		nodeKindsStringFrom: compositeNodes.
	compositeList ifNil: [ compositeList := self stringValueAt: 'composite' in: propagator ].
	compositeList ifNil: [ compositeList := self stringValueAt: 'composite_list' in: propagator ].
	compositeList ifNotNil: [
		anEnvironment at: 'OTEL_PROPAGATORS' put: compositeList ]
]

{ #category : 'private - projection' }
OTConfigurationSource class >> projectResourceFrom: aConfiguration into: anEnvironment [

	| attributes explicitAttributes resource resourceString serviceName |
	resource := self dictionaryValueAt: 'resource' in: aConfiguration.
	resource ifNil: [ ^ self ].
	attributes := OrderedDictionary new.
	self
		mergeResourceAttributesFromListValue: (self stringValueAt: 'attributes_list' in: resource)
		into: attributes.
	explicitAttributes := self sequenceValueAt: 'attributes' in: resource.
	explicitAttributes ifNotNil: [
		explicitAttributes do: [ :each |
			| key value |
			key := self stringValueAt: 'name' in: each.
			value := self stringValueAt: 'value' in: each.
			(key isNil or: [ value isNil ]) ifFalse: [
				attributes at: key put: value ] ] ].
	resourceString := self encodedResourceAttributesFrom: attributes.
	resourceString ifNotNil: [
		anEnvironment at: 'OTEL_RESOURCE_ATTRIBUTES' put: resourceString ].
	serviceName := attributes at: 'service.name' ifAbsent: [ nil ].
	serviceName ifNotNil: [
		anEnvironment at: 'OTEL_SERVICE_NAME' put: serviceName ]
]

{ #category : 'private - projection' }
OTConfigurationSource class >> projectSpanLimitsFrom: aDictionary into: anEnvironment [

	| limits |
	limits := self dictionaryValueAt: 'limits' in: aDictionary.
	limits ifNil: [ ^ self ].
	self put: 'OTEL_SPAN_ATTRIBUTE_COUNT_LIMIT' from: 'attribute_count_limit' in: limits into: anEnvironment.
	self
		put: 'OTEL_SPAN_ATTRIBUTE_VALUE_LENGTH_LIMIT'
		from: 'attribute_value_length_limit'
		in: limits
		into: anEnvironment.
	self put: 'OTEL_SPAN_EVENT_COUNT_LIMIT' from: 'event_count_limit' in: limits into: anEnvironment.
	self put: 'OTEL_SPAN_LINK_COUNT_LIMIT' from: 'link_count_limit' in: limits into: anEnvironment.
	self
		put: 'OTEL_EVENT_ATTRIBUTE_COUNT_LIMIT'
		fromAnyOf: #( 'event_attribute_count_limit' 'attribute_per_event_count_limit' )
		in: limits
		into: anEnvironment.
	self
		put: 'OTEL_LINK_ATTRIBUTE_COUNT_LIMIT'
		fromAnyOf: #( 'link_attribute_count_limit' 'attribute_per_link_count_limit' )
		in: limits
		into: anEnvironment
]

{ #category : 'private - projection' }
OTConfigurationSource class >> projectTraceSamplerFrom: aDictionary into: anEnvironment [

	| sampler samplerPair |
	sampler := self dictionaryValueAt: 'sampler' in: aDictionary.
	sampler ifNil: [ ^ self ].
	samplerPair := self samplerEnvironmentPairFrom: sampler.
	anEnvironment at: 'OTEL_TRACES_SAMPLER' put: samplerPair first.
	samplerPair second ifNotNil: [
		anEnvironment at: 'OTEL_TRACES_SAMPLER_ARG' put: samplerPair second ].
	^ self
]

{ #category : 'private - projection' }
OTConfigurationSource class >> projectTracerProviderFrom: aConfiguration into: anEnvironment [

	| traceProvider |
	traceProvider := self dictionaryValueAt: 'tracer_provider' in: aConfiguration.
	traceProvider ifNil: [ ^ self ].
	self projectTraceSamplerFrom: traceProvider into: anEnvironment.
	self
		projectProcessorSequenceFrom: traceProvider
		signalNamed: 'TRACES'
		batchPrefix: 'OTEL_BSP'
		into: anEnvironment.
	self projectSpanLimitsFrom: traceProvider into: anEnvironment
]

{ #category : 'private - projection' }
OTConfigurationSource class >> projectedEnvironmentValuesFromConfiguration: aConfiguration [

	| environment fileFormat |
	environment := OrderedDictionary new.
	fileFormat := self stringValueAt: 'file_format' in: aConfiguration.
	(fileFormat notNil and: [ fileFormat ~= '1.0' and: [ fileFormat ~= '1.1' ] ]) ifTrue: [
		Error signal: 'Unsupported declarative configuration file_format: ', fileFormat printString ].
	self projectCommonSettingsFrom: aConfiguration into: environment.
	self projectTracerProviderFrom: aConfiguration into: environment.
	self projectMeterProviderFrom: aConfiguration into: environment.
	self projectLoggerProviderFrom: aConfiguration into: environment.
	^ environment
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> parsedConfigurationFromConfigurationFileAt: aString [

	| fileContents |
	fileContents := self readConfigurationFileAt: aString.
	^ OTDeclarativeConfigFileParser
		parse: fileContents
		environmentLookup: [ :name | self rawEnvironmentValueAt: name ]
}

{ #category : 'private - configuration file' }
OTConfigurationSource class >> readConfigurationFileAt: aString [

	| fileReference |
	fileReference := aString asFileReference.
	fileReference exists ifFalse: [
		Error signal: 'OpenTelemetry declarative configuration file was not found: ', aString printString ].
	^ fileReference contents
]

{ #category : 'accessing' }
OTConfigurationSource class >> rawEnvironmentValueAt: aString [

	| value |
	value := Smalltalk os environment at: aString ifAbsent: [ ^ nil ].
	value := value asString trimBoth.
	^ value isEmpty ifTrue: [ nil ] ifFalse: [ value ]
]

{ #category : 'accessing' }
OTConfigurationSource class >> reset [

	self cachedConfigurationFilePath: nil.
	self cachedEnvironmentValues: nil.
	self cachedParsedConfiguration: nil
]

{ #category : 'private - projection' }
OTConfigurationSource class >> put: anEnvironmentName from: aConfigurationKey in: aDictionary into: anEnvironment [

	| value |
	value := self stringValueAt: aConfigurationKey in: aDictionary.
	value ifNotNil: [ anEnvironment at: anEnvironmentName put: value ].
	^ anEnvironment
]

{ #category : 'private - projection' }
OTConfigurationSource class >> put: anEnvironmentName fromAnyOf: aCollection in: aDictionary into: anEnvironment [

	aCollection do: [ :each |
		| value |
		value := self stringValueAt: each in: aDictionary.
		value ifNotNil: [
			anEnvironment at: anEnvironmentName put: value.
			^ anEnvironment ] ].
	^ anEnvironment
]

{ #category : 'private - projection' }
OTConfigurationSource class >> projectedBatchProcessorSettingsFrom: aDictionary [

	| settings |
	settings := OrderedDictionary new.
	#( 'schedule_delay' 'export_timeout' 'max_queue_size' 'max_export_batch_size' ) do: [ :each |
		(self stringValueAt: each in: aDictionary) ifNotNil: [ :value |
			settings at: each put: value ] ].
	^ settings
]

{ #category : 'private - projection' }
OTConfigurationSource class >> projectedExporterEnvironmentNameFrom: aDictionary signalNamed: aString [

	| association exporterType |
	aDictionary ifNil: [
		Error signal: 'Declarative configuration processors require an exporter' ].
	association := self samplerAssociationFrom: aDictionary.
	exporterType := association key.
	exporterType = 'console' ifTrue: [ ^ 'console' ].
	exporterType = 'zipkin' ifTrue: [
		aString = 'TRACES' ifFalse: [
			Error signal: 'Zipkin declarative configuration is only supported for traces' ].
		^ 'zipkin' ].
	exporterType = 'prometheus' ifTrue: [
		aString = 'METRICS' ifFalse: [
			Error signal: 'Prometheus declarative configuration is only supported for metrics' ].
		^ 'prometheus' ].
	(#( 'otlp_grpc' 'otlp_http' ) includes: exporterType) ifTrue: [ ^ 'otlp' ].
	Error signal: 'Unsupported declarative exporter type: ', exporterType printString
]

{ #category : 'private - projection' }
OTConfigurationSource class >> projectedMetricExporterNodesFromReaders: aCollection [

	| exporters |
	exporters := OrderedDictionary new.
	aCollection do: [ :each |
		| exporterName exporterNode readerAssociation readerKind readerOptions |
		readerAssociation := self samplerAssociationFrom: each.
		readerKind := self normalizedSamplerKind: readerAssociation key.
		readerOptions := readerAssociation value ifNil: [ OrderedDictionary new ].
		exporterNode := self exporterNodeFromProcessorNode: readerOptions.
		exporterName := self projectedExporterEnvironmentNameFrom: exporterNode signalNamed: 'METRICS'.
		self validateMetricReaderKind: readerKind exporterName: exporterName node: each.
		(self projectedPeriodicMetricReaderSettingsFrom: readerOptions) isEmpty ifFalse: [
			readerKind = 'periodic' ifFalse: [
				Error signal:
					'Declarative pull metric readers are not representable with interval or timeout settings via SDK environment variables' ] ].
		self
			validateMetricExporterSettingsIn: exporterNode
			exporterName: exporterName.
		(exporters includesKey: exporterName) ifTrue: [
			Error signal:
				'Declarative metric readers configure the same exporter more than once, which is not representable via SDK environment variables' ].
		exporters at: exporterName put: exporterNode ].
	^ exporters
]

{ #category : 'private - projection' }
OTConfigurationSource class >> projectedMetricExporterSettingsFrom: aDictionary [

	| association exporterOptions settings |
	aDictionary ifNil: [ ^ OrderedDictionary new ].
	association := self samplerAssociationFrom: aDictionary.
	exporterOptions := association value ifNil: [ OrderedDictionary new ].
	settings := OrderedDictionary new.
	#( 'temporality_preference' 'default_histogram_aggregation' ) do: [ :each |
		(self stringValueAt: each in: exporterOptions) ifNotNil: [ :value |
			settings at: each put: value ] ].
	^ settings
]

{ #category : 'private - projection' }
OTConfigurationSource class >> projectedPeriodicMetricReaderSettingsFrom: aDictionary [

	| settings |
	settings := OrderedDictionary new.
	#( 'interval' 'timeout' ) do: [ :each |
		(self stringValueAt: each in: aDictionary) ifNotNil: [ :value |
			settings at: each put: value ] ].
	^ settings
]

{ #category : 'private - projection' }
OTConfigurationSource class >> projectedExporterNodesFromProcessors: aCollection signalNamed: aString [

	| exporters |
	exporters := OrderedDictionary new.
	aCollection do: [ :each |
		| batchSettings exporterName exporterNode processorAssociation processorKind processorOptions |
		processorAssociation := self samplerAssociationFrom: each.
		processorKind := self normalizedSamplerKind: processorAssociation key.
		processorOptions := processorAssociation value ifNil: [ OrderedDictionary new ].
		exporterNode := self exporterNodeFromProcessorNode: processorOptions.
		exporterName := self projectedExporterEnvironmentNameFrom: exporterNode signalNamed: aString.
		self
			validateProcessorKind: processorKind
			exporterName: exporterName
			node: each.
		batchSettings := self projectedBatchProcessorSettingsFrom: processorOptions.
		processorKind = 'simple' ifTrue: [
				batchSettings isEmpty ifFalse: [
					Error signal:
						'Declarative simple processor settings are not representable via SDK environment variables' ] ].
		(exporters includesKey: exporterName) ifTrue: [
			Error signal:
				'Declarative processor sequence configures the same exporter more than once, which is not representable via SDK environment variables' ].
		exporters at: exporterName put: exporterNode ].
	^ exporters
]

{ #category : 'private - projection' }
OTConfigurationSource class >> projectedExporterSelectionFrom: anOrderedDictionary [

	^ String streamContents: [ :stream |
		anOrderedDictionary keysDo: [ :each |
			stream position > 0 ifTrue: [ stream nextPut: $, ].
			stream nextPutAll: each ] ]
]

{ #category : 'private - projection' }
OTConfigurationSource class >> samplerAssociationFrom: aDictionary [

	^ self singleAssociationFrom: aDictionary describedAs: 'sampler'
]

{ #category : 'private - projection' }
OTConfigurationSource class >> samplerEnvironmentPairFrom: aDictionary [

	| association kind options ratio |
	association := self samplerAssociationFrom: aDictionary.
	kind := self normalizedSamplerKind: association key.
	options := association value ifNil: [ OrderedDictionary new ].
	kind = 'always_on' ifTrue: [ ^ #( 'always_on' nil ) ].
	kind = 'always_off' ifTrue: [ ^ #( 'always_off' nil ) ].
	((kind = 'probability') or: [ kind = 'trace_id_ratio_based' ]) ifTrue: [
		ratio := self stringValueAt: 'ratio' in: options.
		ratio ifNil: [
			Error signal: 'Declarative configuration probability samplers require a ratio' ].
		^ { 'traceidratio'. ratio } ].
	kind = 'parent_based' ifTrue: [
		^ self parentBasedSamplerEnvironmentPairFrom: options ].
	kind = 'jaeger_remote' ifTrue: [
		^ { 'jaeger_remote'. (self jaegerRemoteSamplerArgumentFrom: options) } ].
	Error signal: 'Unsupported declarative sampler type: ', association key printString
]

{ #category : 'private - projection' }
OTConfigurationSource class >> jaegerRemoteInitialSamplingRateFrom: aDictionary [

	| pair samplerName |
	aDictionary ifNil: [
		Error signal: 'Declarative jaeger_remote sampler requires an initial_sampler' ].
	pair := self samplerEnvironmentPairFrom: aDictionary.
	samplerName := pair first.
	samplerName = 'always_off' ifTrue: [ ^ '0' ].
	samplerName = 'always_on' ifTrue: [ ^ '1' ].
	samplerName = 'traceidratio' ifTrue: [ ^ pair second ].
	Error signal:
		'Declarative jaeger_remote initial_sampler is not representable via SDK environment variables'
]

{ #category : 'private - projection' }
OTConfigurationSource class >> jaegerRemoteSamplerArgumentFrom: aDictionary [

	| endpoint initialSampler interval |
	endpoint := self stringValueAt: 'endpoint' in: aDictionary.
	endpoint ifNil: [
		Error signal: 'Declarative jaeger_remote sampler requires an endpoint' ].
	initialSampler := self
		jaegerRemoteInitialSamplingRateFrom: (self dictionaryValueAt: 'initial_sampler' in: aDictionary).
	interval := self stringValueAt: 'interval' in: aDictionary.
	^ String streamContents: [ :stream |
		stream nextPutAll: 'endpoint='; nextPutAll: endpoint.
		interval ifNotNil: [
			stream nextPutAll: ',pollingIntervalMs='; nextPutAll: interval ].
		stream nextPutAll: ',initialSamplingRate='; nextPutAll: initialSampler ]
]

{ #category : 'private - projection' }
OTConfigurationSource class >> normalizedSamplerKind: aString [

	| delimiter |
	delimiter := aString indexOf: $/ ifAbsent: [ 0 ].
	^ delimiter = 0
		ifTrue: [ aString ]
		ifFalse: [ aString copyFrom: 1 to: delimiter - 1 ]
]

{ #category : 'private - projection' }
OTConfigurationSource class >> parentBasedSamplerEnvironmentPairFrom: aDictionary [

	| root rootPair |
	root := self dictionaryValueAt: 'root' in: aDictionary.
	root ifNil: [
		Error signal: 'Declarative parent_based sampler requires a root sampler' ].
	self
		validateParentBasedDelegateNamed: 'remote_parent_sampled'
		expectedSampler: 'always_on'
		in: aDictionary.
	self
		validateParentBasedDelegateNamed: 'remote_parent_not_sampled'
		expectedSampler: 'always_off'
		in: aDictionary.
	self
		validateParentBasedDelegateNamed: 'local_parent_sampled'
		expectedSampler: 'always_on'
		in: aDictionary.
	self
		validateParentBasedDelegateNamed: 'local_parent_not_sampled'
		expectedSampler: 'always_off'
		in: aDictionary.
	rootPair := self samplerEnvironmentPairFrom: root.
	rootPair first = 'always_on' ifTrue: [ ^ #( 'parentbased_always_on' nil ) ].
	rootPair first = 'always_off' ifTrue: [ ^ #( 'parentbased_always_off' nil ) ].
	rootPair first = 'traceidratio' ifTrue: [ ^ { 'parentbased_traceidratio'. rootPair second } ].
	rootPair first = 'jaeger_remote' ifTrue: [ ^ { 'parentbased_jaeger_remote'. rootPair second } ].
	Error signal:
		'Declarative parent_based sampler root is not representable via SDK environment variables'
]

{ #category : 'private - projection' }
OTConfigurationSource class >> sequenceValueAt: aKey in: aDictionary [

	| value |
	aDictionary ifNil: [ ^ nil ].
	value := aDictionary at: aKey ifAbsent: [ ^ nil ].
	^ value isArray
		ifTrue: [ value ]
		ifFalse: [
			((value isSequenceableCollection) and: [ value isString not ])
				ifTrue: [ value asArray ]
				ifFalse: [ nil ] ]
]

{ #category : 'private - projection' }
OTConfigurationSource class >> stringValueAt: aKey in: aDictionary [

	| value |
	aDictionary ifNil: [ ^ nil ].
	value := aDictionary at: aKey ifAbsent: [ ^ nil ].
	value ifNil: [ ^ nil ].
	(value isString or: [ value isSymbol ]) ifFalse: [ ^ nil ].
	value := value asString trimBoth.
	^ value isEmpty ifTrue: [ nil ] ifFalse: [ value ]
]

{ #category : 'private - projection' }
OTConfigurationSource class >> stringCollectionValueAt: aKey in: aDictionary [

	| values |
	values := self sequenceValueAt: aKey in: aDictionary.
	values ifNil: [ ^ nil ].
	^ values collect: [ :each | each asString ]
]

{ #category : 'private - projection' }
OTConfigurationSource class >> booleanValueAt: aKey in: aDictionary [

	| value |
	aDictionary ifNil: [ ^ nil ].
	value := aDictionary at: aKey ifAbsent: [ ^ nil ].
	(OTAttributeNormalizer isBoolean: value) ifTrue: [ ^ value ].
	(value isString or: [ value isSymbol ]) ifFalse: [ ^ nil ].
	value := value asString trimBoth asLowercase.
	value = 'true' ifTrue: [ ^ true ].
	value = 'false' ifTrue: [ ^ false ].
	^ nil
]

{ #category : 'private - projection' }
OTConfigurationSource class >> enabledValueFrom: aDictionary [

	| disabled enabled |
	enabled := self booleanValueAt: 'enabled' in: aDictionary.
	enabled ifNotNil: [ ^ enabled ].
	disabled := self booleanValueAt: 'disabled' in: aDictionary.
	disabled ifNotNil: [ ^ disabled not ].
	^ nil
]

{ #category : 'private - projection' }
OTConfigurationSource class >> tracerConfiguratorFrom: aDictionary [

	| defaultConfig rules |
	defaultConfig := self
		tracerEnabledFrom: (self dictionaryValueAt: 'default_config' in: aDictionary).
	rules := self
		namedScopeRulesFrom: (self sequenceValueAt: 'tracers' in: aDictionary)
		configBlock: [ :configNode | self tracerEnabledFrom: configNode ].
	^ [ :scope |
		self
			namedScopeConfigFor: scope
			rules: rules
			default: defaultConfig ]
]

{ #category : 'private - projection' }
OTConfigurationSource class >> tracerEnabledFrom: aDictionary [

	^ self enabledValueFrom: aDictionary
]

{ #category : 'private - projection' }
OTConfigurationSource class >> base2ExponentialHistogramAggregationParametersFrom: aDictionary [

	| parameters |
	parameters := OrderedDictionary new.
	(self integerValueAt: 'max_scale' in: aDictionary) ifNotNil: [ :value |
		parameters at: 'max_scale' put: value ].
	(self integerValueAt: 'max_size' in: aDictionary) ifNotNil: [ :value |
		parameters at: 'max_size' put: value ].
	(self booleanValueAt: 'record_min_max' in: aDictionary) ifNotNil: [ :value |
		parameters at: 'record_min_max' put: value ].
	^ parameters isEmpty ifTrue: [ nil ] ifFalse: [ parameters ]
]

{ #category : 'private - projection' }
OTConfigurationSource class >> configureMetricView: anOTMetricView selectorFrom: aDictionary [

	(self stringValueAt: 'instrument_name' in: aDictionary) ifNotNil: [ :value |
		anOTMetricView namePattern: value ].
	(self stringValueAt: 'instrument_type' in: aDictionary) ifNotNil: [ :value |
		anOTMetricView instrumentType: value ].
	(self stringValueAt: 'unit' in: aDictionary) ifNotNil: [ :value |
		anOTMetricView unit: value ].
	(self stringValueAt: 'meter_name' in: aDictionary) ifNotNil: [ :value |
		anOTMetricView meterName: value ].
	(self stringValueAt: 'meter_version' in: aDictionary) ifNotNil: [ :value |
		anOTMetricView meterVersion: value ].
	(self stringValueAt: 'meter_schema_url' in: aDictionary) ifNotNil: [ :value |
		anOTMetricView meterSchemaUrl: value ].
	^ anOTMetricView
]

{ #category : 'private - projection' }
OTConfigurationSource class >> configureMetricView: anOTMetricView streamFrom: aDictionary [

	| attributeKeys |
	(self stringValueAt: 'name' in: aDictionary) ifNotNil: [ :value |
		anOTMetricView streamName: value ].
	(self stringValueAt: 'description' in: aDictionary) ifNotNil: [ :value |
		anOTMetricView streamDescription: value ].
	(self integerValueAt: 'aggregation_cardinality_limit' in: aDictionary) ifNotNil: [ :value |
		anOTMetricView aggregationCardinalityLimit: value ].
	attributeKeys := self metricViewAttributeKeysFrom: aDictionary.
	attributeKeys ifNotNil: [ anOTMetricView attributeKeys: attributeKeys ].
	self configureMetricView: anOTMetricView aggregationFrom: aDictionary.
	^ anOTMetricView
]

{ #category : 'private - projection' }
OTConfigurationSource class >> configureMetricView: anOTMetricView aggregationFrom: aDictionary [

	| aggregationNode parameters |
	aggregationNode := self dictionaryValueAt: 'aggregation' in: aDictionary.
	aggregationNode ifNil: [ ^ anOTMetricView ].
	aggregationNode := self
		singleAssociationFrom: aggregationNode
		describedAs: 'metric view aggregation'.
	anOTMetricView aggregation: aggregationNode key.
	parameters := self metricViewAggregationParametersFor: aggregationNode.
	parameters ifNotNil: [ anOTMetricView aggregationParameters: parameters ].
	^ anOTMetricView
]

{ #category : 'private - projection' }
OTConfigurationSource class >> explicitBucketHistogramAggregationParametersFrom: aDictionary [

	| boundaries parameters |
	parameters := OrderedDictionary new.
	boundaries := self sequenceValueAt: 'boundaries' in: aDictionary.
	boundaries ifNotNil: [ parameters at: 'boundaries' put: boundaries ].
	(self booleanValueAt: 'record_min_max' in: aDictionary) ifNotNil: [ :value |
		parameters at: 'record_min_max' put: value ].
	^ parameters isEmpty ifTrue: [ nil ] ifFalse: [ parameters ]
]

{ #category : 'private - projection' }
OTConfigurationSource class >> integerValueAt: aKey in: aDictionary [

	| value |
	aDictionary ifNil: [ ^ nil ].
	value := aDictionary at: aKey ifAbsent: [ ^ nil ].
	value isInteger ifTrue: [ ^ value ].
	^ nil
]

{ #category : 'private - projection' }
OTConfigurationSource class >> validateParentBasedDelegateNamed: aString expectedSampler: anotherString in: aDictionary [

	| delegate |
	delegate := self dictionaryValueAt: aString in: aDictionary.
	delegate ifNil: [ ^ self ].
	(self normalizedSamplerKind: (self samplerAssociationFrom: delegate) key) = anotherString ifFalse: [
		Error signal:
			'Declarative parent_based sampler delegate is not representable via SDK environment variables: '
				, aString printString ].
	^ self
]

{ #category : 'private - projection' }
OTConfigurationSource class >> sharedBatchProcessorSettingsFrom: aCollection [

	| foundSettings |
	foundSettings := nil.
	aCollection do: [ :each |
		| processorAssociation processorKind processorOptions settings |
		processorAssociation := self samplerAssociationFrom: each.
		processorKind := self normalizedSamplerKind: processorAssociation key.
		processorKind = 'batch' ifTrue: [
			processorOptions := processorAssociation value ifNil: [ OrderedDictionary new ].
			settings := self projectedBatchProcessorSettingsFrom: processorOptions.
			settings isEmpty ifFalse: [
				foundSettings
					ifNil: [ foundSettings := settings ]
					ifNotNil: [
						foundSettings = settings ifFalse: [
							Error signal:
								'Declarative processor sequence configures incompatible batch processor settings for one signal' ] ] ] ] ].
	^ foundSettings
]

{ #category : 'private - projection' }
OTConfigurationSource class >> sharedOtlpMetricExporterSettingsFromReaders: aCollection [

	| foundSettings |
	foundSettings := nil.
	aCollection do: [ :each |
		| exporterName exporterNode readerAssociation readerOptions settings |
		readerAssociation := self samplerAssociationFrom: each.
		readerOptions := readerAssociation value ifNil: [ OrderedDictionary new ].
		exporterNode := self exporterNodeFromProcessorNode: readerOptions.
		exporterName := self projectedExporterEnvironmentNameFrom: exporterNode signalNamed: 'METRICS'.
		exporterName = 'otlp' ifTrue: [
			settings := self projectedMetricExporterSettingsFrom: exporterNode.
			settings isEmpty ifFalse: [
				foundSettings
					ifNil: [ foundSettings := settings ]
					ifNotNil: [
						foundSettings = settings ifFalse: [
							Error signal:
								'Declarative metric readers configure incompatible OTLP reader settings for one signal' ] ] ] ] ].
	^ foundSettings
]

{ #category : 'private - projection' }
OTConfigurationSource class >> sharedPeriodicMetricReaderSettingsFrom: aCollection [

	| foundSettings |
	foundSettings := nil.
	aCollection do: [ :each |
		| readerAssociation readerKind readerOptions settings |
		readerAssociation := self samplerAssociationFrom: each.
		readerKind := self normalizedSamplerKind: readerAssociation key.
		readerKind = 'periodic' ifTrue: [
			readerOptions := readerAssociation value ifNil: [ OrderedDictionary new ].
			settings := self projectedPeriodicMetricReaderSettingsFrom: readerOptions.
			settings isEmpty ifFalse: [
				foundSettings
					ifNil: [ foundSettings := settings ]
					ifNotNil: [
						foundSettings = settings ifFalse: [
							Error signal:
								'Declarative metric readers configure incompatible periodic reader settings for one signal' ] ] ] ] ].
	^ foundSettings
]

{ #category : 'private - projection' }
OTConfigurationSource class >> validateProcessorKind: aString exporterName: anotherString node: aDictionary [

	aString = 'simple' ifTrue: [
		anotherString = 'console' ifTrue: [ ^ self ].
		Error signal:
			'Declarative simple processors are only representable for console exporters via SDK environment variables' ].
	aString = 'batch' ifTrue: [
		anotherString = 'console' ifTrue: [
			Error signal:
				'Declarative batch processors are not representable for console exporters via SDK environment variables' ].
		^ self ].
	Error signal:
		'Unsupported declarative processor type: '
			, (self samplerAssociationFrom: aDictionary) key printString
]

{ #category : 'private - projection' }
OTConfigurationSource class >> validateMetricExporterSettingsIn: aDictionary exporterName: aString [

	| settings |
	settings := self projectedMetricExporterSettingsFrom: aDictionary.
	settings isEmpty ifTrue: [ ^ self ].
	aString = 'otlp' ifTrue: [ ^ self ].
	Error signal:
		'Declarative metric exporter settings for temporality or histogram aggregation are only representable for OTLP exporters via SDK environment variables'
]

{ #category : 'private - projection' }
OTConfigurationSource class >> validateMetricReaderKind: aString exporterName: anotherString node: aDictionary [

	aString = 'periodic' ifTrue: [
		anotherString = 'prometheus' ifTrue: [
			Error signal:
				'Declarative periodic metric readers are not representable for Prometheus exporters via SDK environment variables' ].
		^ self ].
	aString = 'pull' ifTrue: [
		anotherString = 'prometheus' ifTrue: [ ^ self ].
		Error signal:
			'Declarative pull metric readers are only representable for Prometheus exporters via SDK environment variables' ].
	Error signal:
		'Unsupported declarative metric reader type: '
			, (self samplerAssociationFrom: aDictionary) key printString
]
