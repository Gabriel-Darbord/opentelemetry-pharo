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

{ #category : 'private - configuration file' }
OTConfigurationSource class >> configurationFilePath [

	| path |
	path := self rawEnvironmentValueAt: 'OTEL_CONFIG_FILE'.
	^ path ifNil: [ self rawEnvironmentValueAt: 'OTEL_EXPERIMENTAL_CONFIG_FILE' ] ifNotNil: [ path ]
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> configuredEnvironmentValues [

	| cachedPath path values |
	path := self configurationFilePath.
	cachedPath := self cachedConfigurationFilePath.
	(cachedPath = path and: [ cachedPath notNil ]) ifTrue: [
		^ self cachedEnvironmentValues ].
	path ifNil: [
		self cachedConfigurationFilePath: nil.
		self cachedEnvironmentValues: nil.
		^ nil ].
	values := self environmentValuesFromConfigurationFileAt: path.
	self cachedConfigurationFilePath: path.
	self cachedEnvironmentValues: values.
	^ values
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

	| configuration fileContents |
	fileContents := self readConfigurationFileAt: aString.
	configuration := OTDeclarativeConfigFileParser
		parse: fileContents
		environmentLookup: [ :name | self rawEnvironmentValueAt: name ].
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
OTConfigurationSource class >> projectExporterNode: aDictionary signalNamed: aString into: anEnvironment [

	| endpoint exporterName exporterOptions exporterType headers signalPrefix tls |
	aDictionary ifNil: [ ^ self ].
	aDictionary associations size = 1 ifFalse: [
		Error signal: 'Declarative configuration exporter nodes must contain exactly one exporter' ].
	exporterType := aDictionary associations first key.
	exporterOptions := aDictionary associations first value ifNil: [ OrderedDictionary new ].
	signalPrefix := 'OTEL_EXPORTER_OTLP_', aString, '_'.
	exporterType = 'console' ifTrue: [
		anEnvironment at: (self exportEnvironmentNameForSignalNamed: aString) put: 'console'.
		^ self ].
	exporterType = 'zipkin' ifTrue: [
		aString = 'TRACES' ifFalse: [
			Error signal: 'Zipkin declarative configuration is only supported for traces' ].
		anEnvironment at: 'OTEL_TRACES_EXPORTER' put: 'zipkin'.
		self put: 'OTEL_EXPORTER_ZIPKIN_ENDPOINT' from: 'endpoint' in: exporterOptions into: anEnvironment.
		self put: 'OTEL_EXPORTER_ZIPKIN_TIMEOUT' from: 'timeout' in: exporterOptions into: anEnvironment.
		^ self ].
	exporterType = 'prometheus' ifTrue: [
		aString = 'METRICS' ifFalse: [
			Error signal: 'Prometheus declarative configuration is only supported for metrics' ].
		anEnvironment at: 'OTEL_METRICS_EXPORTER' put: 'prometheus'.
		self put: 'OTEL_EXPORTER_PROMETHEUS_HOST' from: 'host' in: exporterOptions into: anEnvironment.
		self put: 'OTEL_EXPORTER_PROMETHEUS_PORT' from: 'port' in: exporterOptions into: anEnvironment.
		^ self ].
	exporterName := exporterType = 'otlp_grpc'
		ifTrue: [ 'grpc' ]
		ifFalse: [
			exporterType = 'otlp_http'
				ifTrue: [ 'http/protobuf' ]
				ifFalse: [ Error signal: 'Unsupported declarative exporter type: ', exporterType printString ] ].
	anEnvironment at: (self exportEnvironmentNameForSignalNamed: aString) put: 'otlp'.
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
OTConfigurationSource class >> projectLoggerProviderFrom: aConfiguration into: anEnvironment [

	| batch loggerProvider |
	loggerProvider := self dictionaryValueAt: 'logger_provider' in: aConfiguration.
	loggerProvider ifNil: [ ^ self ].
	self projectLogRecordLimitsFrom: loggerProvider into: anEnvironment.
	batch := self firstNodeNamed: 'batch' inSequence: (self sequenceValueAt: 'processors' in: loggerProvider).
	batch ifNil: [ ^ self ].
	self projectBatchProcessorNode: batch prefix: 'OTEL_BLRP' into: anEnvironment.
	self projectExporterNode: (self exporterNodeFromProcessorNode: batch) signalNamed: 'LOGS' into: anEnvironment
]

{ #category : 'private - projection' }
OTConfigurationSource class >> projectMeterProviderFrom: aConfiguration into: anEnvironment [

	| exporter exporterAssociation exporterOptions meterProvider periodic |
	meterProvider := self dictionaryValueAt: 'meter_provider' in: aConfiguration.
	meterProvider ifNil: [ ^ self ].
	self put: 'OTEL_METRICS_EXEMPLAR_FILTER' fromAnyOf: #( 'exemplar_filter' 'exemplar' ) in: meterProvider into: anEnvironment.
	periodic := self firstNodeNamed: 'periodic' inSequence: (self sequenceValueAt: 'readers' in: meterProvider).
	periodic ifNil: [ ^ self ].
	self put: 'OTEL_METRIC_EXPORT_INTERVAL' from: 'interval' in: periodic into: anEnvironment.
	self put: 'OTEL_METRIC_EXPORT_TIMEOUT' from: 'timeout' in: periodic into: anEnvironment.
	exporter := self exporterNodeFromProcessorNode: periodic.
	exporterAssociation := exporter ifNil: [ nil ] ifNotNil: [ self samplerAssociationFrom: exporter ].
	exporterOptions := exporterAssociation
		ifNil: [ nil ]
		ifNotNil: [ exporterAssociation value ifNil: [ OrderedDictionary new ] ].
	self
		put: 'OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE'
		from: 'temporality_preference'
		in: exporterOptions
		into: anEnvironment.
	self
		put: 'OTEL_EXPORTER_OTLP_METRICS_DEFAULT_HISTOGRAM_AGGREGATION'
		from: 'default_histogram_aggregation'
		in: exporterOptions
		into: anEnvironment.
	self projectExporterNode: exporter signalNamed: 'METRICS' into: anEnvironment
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

	| batch traceProvider |
	traceProvider := self dictionaryValueAt: 'tracer_provider' in: aConfiguration.
	traceProvider ifNil: [ ^ self ].
	self projectTraceSamplerFrom: traceProvider into: anEnvironment.
	batch := self firstNodeNamed: 'batch' inSequence: (self sequenceValueAt: 'processors' in: traceProvider).
	batch ifNotNil: [
		self projectBatchProcessorNode: batch prefix: 'OTEL_BSP' into: anEnvironment.
		self projectExporterNode: (self exporterNodeFromProcessorNode: batch) signalNamed: 'TRACES' into: anEnvironment ].
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
	self cachedEnvironmentValues: nil
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
OTConfigurationSource class >> samplerAssociationFrom: aDictionary [

	aDictionary ifNil: [
		Error signal: 'Declarative configuration sampler nodes must not be nil' ].
	aDictionary associations size = 1 ifFalse: [
		Error signal: 'Declarative configuration sampler nodes must contain exactly one sampler' ].
	^ aDictionary associations first
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
