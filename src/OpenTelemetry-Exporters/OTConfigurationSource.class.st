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

{ #category : 'private - projection' }
OTConfigurationSource class >> attributeKey: aString matchesAnyPatternIn: aCollection [

	aCollection ifNil: [ ^ false ].
	^ aCollection anySatisfy: [ :each | self wildcardPattern: each matches: aString ]
]

{ #category : 'private - projection' }
OTConfigurationSource class >> base2ExponentialHistogramAggregationParametersFrom: aDictionary [

	| parameters |
	parameters := OrderedDictionary new.
	(self integerValueAt: 'max_scale' in: aDictionary) ifNotNil: [ :value | parameters at: 'max_scale' put: value ].
	(self integerValueAt: 'max_size' in: aDictionary) ifNotNil: [ :value | parameters at: 'max_size' put: value ].
	(self booleanValueAt: 'record_min_max' in: aDictionary) ifNotNil: [ :value | parameters at: 'record_min_max' put: value ].
	^ parameters isEmpty
		  ifTrue: [ nil ]
		  ifFalse: [ parameters ]
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

{ #category : 'private - caching' }
OTConfigurationSource class >> cachedConfigurationFilePath [

	^ OTClassStateStore valueAt: #otConfigurationFilePath forClass: self ifAbsent: [ nil ]
]

{ #category : 'private - caching' }
OTConfigurationSource class >> cachedConfigurationFilePath: aStringOrNil [

	aStringOrNil
		ifNil: [ OTClassStateStore removeValueAt: #otConfigurationFilePath forClass: self ifAbsent: [ ] ]
		ifNotNil: [ OTClassStateStore valueAt: #otConfigurationFilePath forClass: self put: aStringOrNil ]
]

{ #category : 'private - caching' }
OTConfigurationSource class >> cachedEnvironmentValues [

	^ OTClassStateStore valueAt: #otConfigurationEnvironmentValues forClass: self ifAbsent: [ nil ]
]

{ #category : 'private - caching' }
OTConfigurationSource class >> cachedEnvironmentValues: aDictionaryOrNil [

	aDictionaryOrNil
		ifNil: [ OTClassStateStore removeValueAt: #otConfigurationEnvironmentValues forClass: self ifAbsent: [ ] ]
		ifNotNil: [ OTClassStateStore valueAt: #otConfigurationEnvironmentValues forClass: self put: aDictionaryOrNil ]
]

{ #category : 'private - caching' }
OTConfigurationSource class >> cachedParsedConfiguration [

	^ OTClassStateStore valueAt: #otConfigurationParsedConfiguration forClass: self ifAbsent: [ nil ]
]

{ #category : 'private - caching' }
OTConfigurationSource class >> cachedParsedConfiguration: aDictionaryOrNil [

	aDictionaryOrNil
		ifNil: [ OTClassStateStore removeValueAt: #otConfigurationParsedConfiguration forClass: self ifAbsent: [ ] ]
		ifNotNil: [ OTClassStateStore valueAt: #otConfigurationParsedConfiguration forClass: self put: aDictionaryOrNil ]
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> composableRuleAssociationFrom: aDictionary [

	| sampler |
	sampler := self dictionaryValueAt: 'sampler' in: aDictionary.
	sampler ifNil: [ Error signal: 'Declarative composite rule_based rules require a sampler' ].
	^ (self composableRulePredicateFrom: aDictionary) -> (self composableSamplerFrom: sampler)
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> composableRuleAssociationsFrom: aDictionary [

	| rules |
	rules := self sequenceValueAt: 'rules' in: aDictionary.
	rules ifNil: [ ^ #(  ) ].
	^ rules collect: [ :each | self composableRuleAssociationFrom: each ]
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> composableRuleAttributePatternsPredicateFrom: aDictionary [

	| excluded included key patterns |
	patterns := self dictionaryValueAt: 'attribute_patterns' in: aDictionary.
	patterns ifNil: [ ^ nil ].
	key := self stringValueAt: 'key' in: patterns.
	key ifNil: [ Error signal: 'Declarative composite rule_based attribute_patterns require a key' ].
	included := self sequenceValueAt: 'included' in: patterns.
	excluded := self sequenceValueAt: 'excluded' in: patterns.
	^ [ :context :spanName :kind :attributes :links |
		  | matchesExcluded matchesIncluded values |
		  values := self samplerAttributeStringValuesNamed: key in: attributes.
		  values ifEmpty: [ false ] ifNotEmpty: [
				  matchesIncluded := included isNil or: [ values anySatisfy: [ :each | self wildcardPatterns: included match: each ] ].
				  matchesExcluded := excluded notNil and: [ values anySatisfy: [ :each | self wildcardPatterns: excluded match: each ] ].
				  matchesIncluded and: [ matchesExcluded not ] ] ]
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> composableRuleAttributeValuesPredicateFrom: aDictionary [

	| attributeValues key values |
	attributeValues := self dictionaryValueAt: 'attribute_values' in: aDictionary.
	attributeValues ifNil: [ ^ nil ].
	key := self stringValueAt: 'key' in: attributeValues.
	key ifNil: [ Error signal: 'Declarative composite rule_based attribute_values require a key' ].
	values := self sequenceValueAt: 'values' in: attributeValues.
	(values isNil or: [ values isEmpty ]) ifTrue: [ Error signal: 'Declarative composite rule_based attribute_values require values' ].
	values := values collect: [ :each | each asString ] as: Set.
	^ [ :context :spanName :kind :attributes :links |
	  (self samplerAttributeStringValuesNamed: key in: attributes) anySatisfy: [ :each | values includes: each ] ]
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> composableRuleParentPredicateFrom: aDictionary [

	| parents |
	parents := self sequenceValueAt: 'parent' in: aDictionary.
	parents ifNil: [ ^ nil ].
	parents := parents collect: [ :each | each asString asLowercase asSymbol ] as: Set.
	^ [ :context :spanName :kind :attributes :links | parents includes: (self samplerParentTypeForContext: context) ]
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> composableRulePredicateFrom: aDictionary [

	| predicates |
	predicates := OrderedCollection new.
	{
		(self composableRuleAttributeValuesPredicateFrom: aDictionary).
		(self composableRuleAttributePatternsPredicateFrom: aDictionary).
		(self composableRuleParentPredicateFrom: aDictionary).
		(self composableRuleSpanKindsPredicateFrom: aDictionary) } do: [ :each | each ifNotNil: [ predicates add: each ] ].
	predicates ifEmpty: [ ^ [ true ] ].
	^ [ :context :spanName :kind :attributes :links |
		  predicates allSatisfy: [ :each |
				  each valueWithArguments: {
						  context.
						  spanName.
						  kind.
						  attributes.
						  links } ] ]
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> composableRuleSpanKindsPredicateFrom: aDictionary [

	| kinds |
	kinds := self sequenceValueAt: 'span_kinds' in: aDictionary.
	kinds ifNil: [ ^ nil ].
	kinds := kinds collect: [ :each | each asString asLowercase asSymbol ] as: Set.
	^ [ :context :spanName :kind :attributes :links | kinds includes: kind ]
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> composableSamplerAssociationFrom: aDictionary [

	^ self singleAssociationFrom: aDictionary describedAs: 'composable sampler'
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> composableSamplerFrom: aDictionary [

	| association kind options probability root |
	association := self composableSamplerAssociationFrom: aDictionary.
	kind := self normalizedSamplerKind: association key.
	options := association value ifNil: [ OrderedDictionary new ].
	kind = 'always_on' ifTrue: [ ^ OTComposableSampler alwaysOn ].
	kind = 'always_off' ifTrue: [ ^ OTComposableSampler alwaysOff ].
	kind = 'probability' ifTrue: [
			probability := self optionalSamplerProbabilityFrom: options default: 1.
			^ OTComposableSampler probability: probability ].
	kind = 'parent_threshold' ifTrue: [
			root := self dictionaryValueAt: 'root' in: options.
			root ifNil: [ Error signal: 'Declarative composite parent_threshold sampler requires a root sampler' ].
			^ OTComposableSampler parentThreshold: (self composableSamplerFrom: root) ].
	kind = 'rule_based' ifTrue: [ ^ OTComposableSampler ruleBased: (self composableRuleAssociationsFrom: options) ].
	Error signal: 'Unsupported declarative composable sampler type: ' , association key printString
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> configurationFilePath [

	| path |
	path := self rawEnvironmentValueAt: 'OTEL_CONFIG_FILE'.
	^ path ifNil: [ self rawEnvironmentValueAt: 'OTEL_EXPERIMENTAL_CONFIG_FILE' ] ifNotNil: [ path ]
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> configureBatchLogRecordProcessor: anOTBatchLogRecordProcessor from: aDictionary [

	| maxExportBatchSize maxQueueSize |
	maxQueueSize := self positiveIntegerValueAt: 'max_queue_size' in: aDictionary default: anOTBatchLogRecordProcessor maxQueueSize.
	maxExportBatchSize := self
		                      positiveIntegerValueAt: 'max_export_batch_size'
		                      in: aDictionary
		                      default: anOTBatchLogRecordProcessor maxExportBatchSize.
	anOTBatchLogRecordProcessor
		maxQueueSize: maxQueueSize;
		maxExportBatchSize: (maxExportBatchSize min: maxQueueSize);
		scheduledDelayMillis:
			(self nonNegativeIntegerValueAt: 'schedule_delay' in: aDictionary default: anOTBatchLogRecordProcessor scheduledDelayMillis);
		exportTimeoutMillis:
			(self nonNegativeIntegerValueAt: 'export_timeout' in: aDictionary default: anOTBatchLogRecordProcessor exportTimeoutMillis).
	^ anOTBatchLogRecordProcessor
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> configureBatchSpanProcessor: anOTBatchSpanProcessor from: aDictionary [

	| maxExportBatchSize maxQueueSize |
	maxQueueSize := self positiveIntegerValueAt: 'max_queue_size' in: aDictionary default: anOTBatchSpanProcessor maxQueueSize.
	maxExportBatchSize := self
		                      positiveIntegerValueAt: 'max_export_batch_size'
		                      in: aDictionary
		                      default: anOTBatchSpanProcessor batchSize.
	anOTBatchSpanProcessor
		maxQueueSize: maxQueueSize;
		batchSize: (maxExportBatchSize min: maxQueueSize);
		scheduledDelayMillis:
			(self nonNegativeIntegerValueAt: 'schedule_delay' in: aDictionary default: anOTBatchSpanProcessor scheduledDelayMillis);
		exportTimeoutMillis:
			(self nonNegativeIntegerValueAt: 'export_timeout' in: aDictionary default: anOTBatchSpanProcessor exportTimeoutMillis).
	^ anOTBatchSpanProcessor
]

{ #category : 'private - projection' }
OTConfigurationSource class >> configureMetricView: anOTMetricView aggregationFrom: aDictionary [

	| aggregationNode parameters |
	aggregationNode := self dictionaryValueAt: 'aggregation' in: aDictionary.
	aggregationNode ifNil: [ ^ anOTMetricView ].
	aggregationNode := self singleAssociationFrom: aggregationNode describedAs: 'metric view aggregation'.
	anOTMetricView aggregation: aggregationNode key.
	parameters := self metricViewAggregationParametersFor: aggregationNode.
	parameters ifNotNil: [ anOTMetricView aggregationParameters: parameters ].
	^ anOTMetricView
]

{ #category : 'private - projection' }
OTConfigurationSource class >> configureMetricView: anOTMetricView selectorFrom: aDictionary [

	(self stringValueAt: 'instrument_name' in: aDictionary) ifNotNil: [ :value | anOTMetricView namePattern: value ].
	(self stringValueAt: 'instrument_type' in: aDictionary) ifNotNil: [ :value | anOTMetricView instrumentType: value ].
	(self stringValueAt: 'unit' in: aDictionary) ifNotNil: [ :value | anOTMetricView unit: value ].
	(self stringValueAt: 'meter_name' in: aDictionary) ifNotNil: [ :value | anOTMetricView meterName: value ].
	(self stringValueAt: 'meter_version' in: aDictionary) ifNotNil: [ :value | anOTMetricView meterVersion: value ].
	(self stringValueAt: 'meter_schema_url' in: aDictionary) ifNotNil: [ :value | anOTMetricView meterSchemaUrl: value ].
	^ anOTMetricView
]

{ #category : 'private - projection' }
OTConfigurationSource class >> configureMetricView: anOTMetricView streamFrom: aDictionary [

	| attributeFilter |
	(self stringValueAt: 'name' in: aDictionary) ifNotNil: [ :value | anOTMetricView streamName: value ].
	(self stringValueAt: 'description' in: aDictionary) ifNotNil: [ :value | anOTMetricView streamDescription: value ].
	(self integerValueAt: 'aggregation_cardinality_limit' in: aDictionary) ifNotNil: [ :value |
		anOTMetricView aggregationCardinalityLimit: value ].
	attributeFilter := self metricViewAttributeFilterFrom: aDictionary.
	attributeFilter ifNotNil: [
			anOTMetricView
				attributeKeys: attributeFilter includedKeys;
				excludedAttributeKeys: attributeFilter excludedKeys ].
	self configureMetricView: anOTMetricView aggregationFrom: aDictionary.
	^ anOTMetricView
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> configureOtlpMetricExporter: anOTMetricExporter from: aDictionary [

	| aggregationPreference temporalityPreference |
	temporalityPreference := self metricTemporalityPreferenceFrom: (self stringValueAt: 'temporality_preference' in: aDictionary).
	anOTMetricExporter temporalitySelector: [ :instrument | instrument otlpTemporalityForPreference: temporalityPreference ].
	aggregationPreference := self metricAggregationPreferenceFrom:
		                         (self stringValueAt: 'default_histogram_aggregation' in: aDictionary).
	anOTMetricExporter aggregationSelector: [ :instrument | instrument otlpAggregationForPreference: aggregationPreference ].
	^ anOTMetricExporter
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> configurePeriodicMetricReader: anOTPeriodicExportingMetricReader from: aDictionary [

	anOTPeriodicExportingMetricReader
		exportIntervalMillis:
			(self positiveIntegerValueAt: 'interval' in: aDictionary default: anOTPeriodicExportingMetricReader exportIntervalMillis);
		exportTimeoutMillis:
			(self positiveIntegerValueAt: 'timeout' in: aDictionary default: anOTPeriodicExportingMetricReader exportTimeoutMillis).
	^ anOTPeriodicExportingMetricReader
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> configuredConfiguration [

	| cachedPath configuration path values |
	path := self configurationFilePath.
	cachedPath := self cachedConfigurationFilePath.
	(cachedPath = path and: [ cachedPath notNil and: [ self cachedParsedConfiguration notNil ] ]) ifTrue: [
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
OTConfigurationSource class >> configuredEnvironmentValues [

	self configuredConfiguration.
	^ self cachedEnvironmentValues
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> configuredLogRecordProcessors [

	| configuration loggerProvider processors |
	configuration := self configuredConfiguration.
	configuration ifNil: [ ^ nil ].
	loggerProvider := self dictionaryValueAt: 'logger_provider' in: configuration.
	loggerProvider ifNil: [ ^ nil ].
	processors := self sequenceValueAt: 'processors' in: loggerProvider.
	processors ifNil: [ ^ nil ].
	^ self logRecordProcessorsFrom: processors
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> configuredLoggerConfigurator [

	| configuration loggerProvider node |
	configuration := self configuredConfiguration.
	configuration ifNil: [ ^ nil ].
	loggerProvider := self dictionaryValueAt: 'logger_provider' in: configuration.
	node := self dictionaryValueAt: 'logger_configurator/development' in: loggerProvider.
	node ifNil: [ ^ nil ].
	^ self loggerConfiguratorFrom: node
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> configuredMeterConfigurator [

	| configuration meterProvider node |
	configuration := self configuredConfiguration.
	configuration ifNil: [ ^ nil ].
	meterProvider := self dictionaryValueAt: 'meter_provider' in: configuration.
	node := self dictionaryValueAt: 'meter_configurator/development' in: meterProvider.
	node ifNil: [ ^ nil ].
	^ self meterConfiguratorFrom: node
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> configuredMetricReaders [

	| configuration meterProvider readers |
	configuration := self configuredConfiguration.
	configuration ifNil: [ ^ nil ].
	meterProvider := self dictionaryValueAt: 'meter_provider' in: configuration.
	meterProvider ifNil: [ ^ nil ].
	readers := self sequenceValueAt: 'readers' in: meterProvider.
	readers ifNil: [ ^ nil ].
	^ self metricReadersFrom: readers
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> configuredMetricViews [

	| configuration meterProvider views |
	configuration := self configuredConfiguration.
	configuration ifNil: [ ^ #(  ) ].
	meterProvider := self dictionaryValueAt: 'meter_provider' in: configuration.
	views := self sequenceValueAt: 'views' in: meterProvider.
	views ifNil: [ ^ #(  ) ].
	^ views collect: [ :each | self metricViewFrom: each ]
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> configuredResource [

	| configuration resource |
	configuration := self configuredConfiguration.
	configuration ifNil: [ ^ nil ].
	resource := self dictionaryValueAt: 'resource' in: configuration.
	resource ifNil: [ ^ nil ].
	^ self declarativeResourceFrom: resource
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> configuredSamplerForResource: anOTResource [

	| configuration sampler tracerProvider |
	configuration := self configuredConfiguration.
	configuration ifNil: [ ^ nil ].
	tracerProvider := self dictionaryValueAt: 'tracer_provider' in: configuration.
	tracerProvider ifNil: [ ^ nil ].
	sampler := self dictionaryValueAt: 'sampler' in: tracerProvider.
	sampler ifNil: [ ^ nil ].
	^ self samplerFrom: sampler resource: anOTResource
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> configuredTraceExporters [

	| processors |
	processors := self configuredTraceProcessors.
	processors ifNil: [ ^ nil ].
	^ processors collect: [ :each | each exporter ]
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> configuredTraceProcessors [

	| configuration processors tracerProvider |
	configuration := self configuredConfiguration.
	configuration ifNil: [ ^ nil ].
	tracerProvider := self dictionaryValueAt: 'tracer_provider' in: configuration.
	tracerProvider ifNil: [ ^ nil ].
	processors := self sequenceValueAt: 'processors' in: tracerProvider.
	processors ifNil: [ ^ nil ].
	^ self traceProcessorsFrom: processors
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> configuredTracerConfigurator [

	| configuration tracerProvider node |
	configuration := self configuredConfiguration.
	configuration ifNil: [ ^ nil ].
	tracerProvider := self dictionaryValueAt: 'tracer_provider' in: configuration.
	node := self dictionaryValueAt: 'tracer_configurator/development' in: tracerProvider.
	node ifNil: [ ^ nil ].
	^ self tracerConfiguratorFrom: node
]

{ #category : 'private - projection' }
OTConfigurationSource class >> declarativeBooleanFrom: anObject [

	| value |
	(OTAttributeNormalizer isBoolean: anObject) ifTrue: [ ^ anObject ].
	(anObject isString or: [ anObject isSymbol ]) ifFalse: [ ^ nil ].
	value := anObject asString trimBoth asLowercase.
	value = 'true' ifTrue: [ ^ true ].
	value = 'false' ifTrue: [ ^ false ].
	^ nil
]

{ #category : 'private - projection' }
OTConfigurationSource class >> declarativeEnvironmentResource [

	| rawValue |
	rawValue := self rawEnvironmentValueAt: 'OTEL_RESOURCE_ATTRIBUTES'.
	rawValue ifNil: [ ^ OTResource empty ].
	^ [ OTResource attributes: (OTTracerProvider resourceAttributesFromEnvironment: rawValue) ]
		  on: Error
		  do: [ :error |
				  OTTracerProvider noteInvalidResourceAttributes: rawValue error: error.
				  OTResource empty ]
]

{ #category : 'private - projection' }
OTConfigurationSource class >> declarativeIntegerFrom: anObject [

	| stream value |
	anObject isInteger ifTrue: [ ^ anObject ].
	(anObject isString or: [ anObject isSymbol ]) ifFalse: [ ^ nil ].
	stream := anObject asString trimBoth readStream.
	stream atEnd ifTrue: [ ^ nil ].
	value := [ Integer readFrom: stream ]
		         on: Error
		         do: [ ^ nil ].
	stream atEnd ifFalse: [ ^ nil ].
	^ value
]

{ #category : 'private - projection' }
OTConfigurationSource class >> declarativeNumberFrom: anObject [

	| stream value |
	anObject isNumber ifTrue: [ ^ anObject asFloat ].
	(anObject isString or: [ anObject isSymbol ]) ifFalse: [ ^ nil ].
	stream := anObject asString trimBoth readStream.
	stream atEnd ifTrue: [ ^ nil ].
	value := [ Number readFrom: stream ]
		         on: Error
		         do: [ ^ nil ].
	stream atEnd ifFalse: [ ^ nil ].
	^ value asFloat
]

{ #category : 'private - projection' }
OTConfigurationSource class >> declarativeResourceAttributeFrom: aDictionary [

	| attributeName rawValue valueType |
	attributeName := self stringValueAt: 'name' in: aDictionary.
	attributeName ifNil: [ ^ nil ].
	(aDictionary includesKey: 'value') ifFalse: [ ^ nil ].
	rawValue := aDictionary at: 'value'.
	valueType := self stringValueAt: 'type' in: aDictionary.
	^ attributeName -> (self declarativeResourceAttributeValue: rawValue type: valueType)
]

{ #category : 'private - projection' }
OTConfigurationSource class >> declarativeResourceAttributeValue: anObject type: aStringOrNil [

	aStringOrNil ifNil: [ ^ anObject asString ].
	aStringOrNil = 'string' ifTrue: [
			(anObject isString or: [ anObject isSymbol ]) ifFalse: [
				Error signal: 'Declarative resource attribute value does not match type string: ' , anObject printString ].
			^ anObject asString ].
	aStringOrNil = 'bool' ifTrue: [ ^ self requiredDeclarativeBoolean: anObject type: aStringOrNil ].
	aStringOrNil = 'int' ifTrue: [ ^ self requiredDeclarativeInteger: anObject type: aStringOrNil ].
	aStringOrNil = 'double' ifTrue: [ ^ self requiredDeclarativeNumber: anObject type: aStringOrNil ].
	aStringOrNil = 'string_array' ifTrue: [
			^ self
				  declarativeResourceAttributeValues: anObject
				  validatedBy: [ :each | each isString or: [ each isSymbol ] ]
				  convertedBy: [ :each | each asString ]
				  type: aStringOrNil ].
	aStringOrNil = 'bool_array' ifTrue: [
			^ self
				  declarativeResourceAttributeValues: anObject
				  validatedBy: [ :each | (self declarativeBooleanFrom: each) notNil ]
				  convertedBy: [ :each | self declarativeBooleanFrom: each ]
				  type: aStringOrNil ].
	aStringOrNil = 'int_array' ifTrue: [
			^ self
				  declarativeResourceAttributeValues: anObject
				  validatedBy: [ :each | (self declarativeIntegerFrom: each) notNil ]
				  convertedBy: [ :each | self declarativeIntegerFrom: each ]
				  type: aStringOrNil ].
	aStringOrNil = 'double_array' ifTrue: [
			^ self
				  declarativeResourceAttributeValues: anObject
				  validatedBy: [ :each | (self declarativeNumberFrom: each) notNil ]
				  convertedBy: [ :each | self declarativeNumberFrom: each ]
				  type: aStringOrNil ].
	Error signal: 'Unsupported declarative resource attribute type: ' , aStringOrNil printString
]

{ #category : 'private - projection' }
OTConfigurationSource class >> declarativeResourceAttributeValues: anObject validatedBy: aValidationBlock convertedBy: aConversionBlock type: aString [

	| values |
	values := self declarativeSequenceFrom: anObject.
	values ifNil: [
		Error signal: 'Declarative resource attribute value does not match type ' , aString printString , ': ' , anObject printString ].
	^ values collect: [ :each |
			  (aValidationBlock value: each) ifFalse: [
				  Error signal:
					  'Declarative resource attribute value does not match type ' , aString printString , ': ' , anObject printString ].
			  aConversionBlock value: each ]
]

{ #category : 'private - projection' }
OTConfigurationSource class >> declarativeResourceAttributesFrom: aDictionary [

	| attributes explicitAttributes |
	attributes := OrderedDictionary new.
	attributes addAll: (self resourceAttributesFromListValue: (self stringValueAt: 'attributes_list' in: aDictionary)).
	explicitAttributes := self sequenceValueAt: 'attributes' in: aDictionary.
	explicitAttributes ifNotNil: [
			explicitAttributes do: [ :each |
				(self declarativeResourceAttributeFrom: each) ifNotNil: [ :attribute | attributes at: attribute key put: attribute value ] ] ].
	^ attributes
]

{ #category : 'private - projection' }
OTConfigurationSource class >> declarativeResourceDetectorFrom: aDictionary [

	| association detectorName |
	association := self singleAssociationFrom: aDictionary describedAs: 'resource detector'.
	detectorName := association key asString.
	^ self declarativeResourceDetectorNamed: detectorName
]

{ #category : 'private - projection' }
OTConfigurationSource class >> declarativeResourceDetectorNamed: detectorName [

	detectorName = 'sdk' ifTrue: [ ^ OTStaticResourceDetector named: 'sdk' resource: OTTracerProvider defaultResource ].
	detectorName = 'host' ifTrue: [ ^ OTHostResourceDetector new ].
	detectorName = 'os' ifTrue: [
			^ OTBlockResourceDetector
				  named: 'os'
				  detecting: [ self filteredResource: OTHostResourceDetector new detectResource included: #( 'os.*' ) excluded: nil ] ].
	detectorName = 'process' ifTrue: [ ^ OTProcessResourceDetector new ].
	(#( 'env' 'environment' ) includes: detectorName) ifTrue: [
		^ OTBlockResourceDetector named: 'env' detecting: [ self declarativeEnvironmentResource ] ].
	detectorName = 'service' ifTrue: [ ^ OTBlockResourceDetector named: 'service' detecting: [ self declarativeServiceResource ] ].
	detectorName = 'service_instance' ifTrue: [ ^ OTServiceInstanceResourceDetector new ].
	Error signal: 'Unsupported declarative resource detector: ' , detectorName printString
]

{ #category : 'private - projection' }
OTConfigurationSource class >> declarativeResourceDetectorsFrom: aDictionary [

	| detectors |
	detectors := self sequenceValueAt: 'detectors' in: aDictionary.
	detectors ifNil: [
		^ #( 'sdk' 'host' 'process' 'env' 'service' ) collect: [ :each | self declarativeResourceDetectorNamed: each ] ].
	^ detectors collect: [ :each | self declarativeResourceDetectorFrom: each ]
]

{ #category : 'private - projection' }
OTConfigurationSource class >> declarativeResourceFrom: aDictionary [

	| detected detection explicitAttributes explicitResource explicitSchemaUrl |
	detection := self dictionaryValueAt: 'detection/development' in: aDictionary.
	detected := detection ifNil: [ OTResource empty ] ifNotNil: [
			            self
				            filteredDeclarativeResourceDetection:
				            (OTTracerProvider resourceFromDetectors: (self declarativeResourceDetectorsFrom: detection))
				            with: detection ].
	explicitAttributes := self declarativeResourceAttributesFrom: aDictionary.
	explicitSchemaUrl := self stringValueAt: 'schema_url' in: aDictionary.
	explicitResource := (explicitAttributes isEmpty and: [ explicitSchemaUrl isNil ])
		                    ifTrue: [ OTResource empty ]
		                    ifFalse: [ OTResource attributes: explicitAttributes schemaUrl: (explicitSchemaUrl ifNil: [ '' ]) ].
	^ detected merge: explicitResource
]

{ #category : 'private - projection' }
OTConfigurationSource class >> declarativeSequenceFrom: anObject [

	| text |
	(anObject isSequenceable and: [ anObject isString not ]) ifTrue: [ ^ anObject ].
	(anObject isString or: [ anObject isSymbol ]) ifFalse: [ ^ nil ].
	text := anObject asString trimBoth.
	(text size >= 2 and: [ text first = $[ and: [ text last = $] ] ]) ifFalse: [ ^ nil ].
	text := (text copyFrom: 2 to: text size - 1) trimBoth.
	text isEmpty ifTrue: [ ^ #(  ) ].
	^ (text substrings: ',') collect: [ :each | each trimBoth ]
]

{ #category : 'private - projection' }
OTConfigurationSource class >> declarativeServiceResource [

	| attributes rawResourceAttributes serviceName |
	attributes := OrderedDictionary new.
	serviceName := self rawEnvironmentValueAt: 'OTEL_SERVICE_NAME'.
	serviceName ifNotNil: [ attributes at: 'service.name' put: serviceName ].
	rawResourceAttributes := self rawEnvironmentValueAt: 'OTEL_RESOURCE_ATTRIBUTES'.
	(rawResourceAttributes isNil or: [ (rawResourceAttributes includesSubstring: 'service.instance.id=') not ]) ifTrue: [
		attributes at: 'service.instance.id' put: OTTracerProvider defaultServiceInstanceId ].
	^ attributes
		  ifEmpty: [ OTResource empty ]
		  ifNotEmpty: [ OTResource attributes: attributes schemaUrl: OTTracerProvider semanticConventionsSchemaUrl ]
]

{ #category : 'private - projection' }
OTConfigurationSource class >> dictionaryValueAt: aKey in: aDictionary [

	| value |
	aDictionary ifNil: [ ^ nil ].
	value := aDictionary at: aKey ifAbsent: [ ^ nil ].
	^ value isDictionary
		  ifTrue: [ value ]
		  ifFalse: [ nil ]
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

{ #category : 'accessing' }
OTConfigurationSource class >> environmentValueAt: aString [

	| configuredValues trimmed value |
	configuredValues := self configuredEnvironmentValues.
	configuredValues ifNil: [ ^ self rawEnvironmentValueAt: aString ].
	value := configuredValues at: aString ifAbsent: [ ^ nil ].
	trimmed := value asString trimBoth.
	^ trimmed isEmpty
		  ifTrue: [ nil ]
		  ifFalse: [ trimmed ]
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> environmentValuesFromConfigurationFileAt: aString [

	| configuration |
	configuration := self parsedConfigurationFromConfigurationFileAt: aString.
	^ self projectedEnvironmentValuesFromConfiguration: configuration
]

{ #category : 'private - projection' }
OTConfigurationSource class >> explicitBucketHistogramAggregationParametersFrom: aDictionary [

	| boundaries parameters |
	parameters := OrderedDictionary new.
	boundaries := self sequenceValueAt: 'boundaries' in: aDictionary.
	boundaries ifNotNil: [
		parameters at: 'boundaries' put: (boundaries collect: [ :each | self requiredDeclarativeNumber: each type: 'double' ]) ].
	(self booleanValueAt: 'record_min_max' in: aDictionary) ifNotNil: [ :value | parameters at: 'record_min_max' put: value ].
	^ parameters isEmpty
		  ifTrue: [ nil ]
		  ifFalse: [ parameters ]
]

{ #category : 'private - projection' }
OTConfigurationSource class >> exportEnvironmentNameForSignalNamed: aString [

	^ 'OTEL_' , aString , '_EXPORTER'
]

{ #category : 'private - projection' }
OTConfigurationSource class >> exporterNodeFromProcessorNode: aDictionary [

	^ self dictionaryValueAt: 'exporter' in: aDictionary
]

{ #category : 'private - projection' }
OTConfigurationSource class >> filteredDeclarativeResourceDetection: anOTResource with: aDictionary [

	| attributesNode excluded included |
	attributesNode := self dictionaryValueAt: 'attributes' in: aDictionary.
	attributesNode ifNil: [ ^ anOTResource ].
	included := self stringCollectionValueAt: 'included' in: attributesNode.
	excluded := self stringCollectionValueAt: 'excluded' in: attributesNode.
	(included isNil and: [ excluded isNil ]) ifTrue: [ ^ anOTResource ].
	^ self filteredResource: anOTResource included: included excluded: excluded
]

{ #category : 'private - projection' }
OTConfigurationSource class >> filteredResource: anOTResource included: includedPatterns excluded: excludedPatterns [

	| attributes |
	attributes := OrderedDictionary new.
	anOTResource allAttributes associationsDo: [ :each |
			((includedPatterns isNil or: [ self attributeKey: each key matchesAnyPatternIn: includedPatterns ]) and: [
				 excludedPatterns isNil or: [ (self attributeKey: each key matchesAnyPatternIn: excludedPatterns) not ] ]) ifTrue: [
				attributes at: each key put: each value ] ].
	attributes isEmpty ifTrue: [ ^ OTResource empty ].
	^ OTResource attributes: attributes schemaUrl: anOTResource schemaUrl
]

{ #category : 'private - projection' }
OTConfigurationSource class >> firstNodeNamed: aKey inSequence: aCollection [

	aCollection ifNil: [ ^ nil ].
	aCollection do: [ :each | (self dictionaryValueAt: aKey in: each) ifNotNil: [ :value | ^ value ] ].
	^ nil
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> headersDictionaryFrom: aCollection [

	| headers |
	headers := OrderedDictionary new.
	aCollection ifNil: [ ^ headers ].
	aCollection do: [ :each |
			| key value |
			key := self stringValueAt: 'name' in: each.
			value := self stringValueAt: 'value' in: each.
			(key isNil or: [ value isNil ]) ifFalse: [ headers at: key put: value ] ].
	^ headers
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
OTConfigurationSource class >> integerValueAt: aKey in: aDictionary [

	| value |
	aDictionary ifNil: [ ^ nil ].
	value := aDictionary at: aKey ifAbsent: [ ^ nil ].
	^ self declarativeIntegerFrom: value
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> invalidDeclarativeOtlpExporterConfigurationAt: aKey value: aValue expected: aDescription [

	Error signal:
		'Invalid OTLP declarative configuration for ' , aKey printString , ': ' , aValue printString , '. Expected ' , aDescription
]

{ #category : 'private - projection' }
OTConfigurationSource class >> jaegerRemoteInitialSamplingRateFrom: aDictionary [

	| pair samplerName |
	aDictionary ifNil: [ Error signal: 'Declarative jaeger_remote sampler requires an initial_sampler' ].
	pair := self samplerEnvironmentPairFrom: aDictionary.
	samplerName := pair first.
	samplerName = 'always_off' ifTrue: [ ^ '0' ].
	samplerName = 'always_on' ifTrue: [ ^ '1' ].
	samplerName = 'traceidratio' ifTrue: [ ^ pair second ].
	Error signal: 'Declarative jaeger_remote initial_sampler is not representable via SDK environment variables'
]

{ #category : 'private - projection' }
OTConfigurationSource class >> jaegerRemoteSamplerArgumentFrom: aDictionary [

	| endpoint initialSampler interval |
	endpoint := self stringValueAt: 'endpoint' in: aDictionary.
	endpoint ifNil: [ Error signal: 'Declarative jaeger_remote sampler requires an endpoint' ].
	initialSampler := self jaegerRemoteInitialSamplingRateFrom: (self dictionaryValueAt: 'initial_sampler' in: aDictionary).
	interval := self stringValueAt: 'interval' in: aDictionary.
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'endpoint=';
				  nextPutAll: endpoint.
			  interval ifNotNil: [
					  stream
						  nextPutAll: ',pollingIntervalMs=';
						  nextPutAll: interval ].
			  stream
				  nextPutAll: ',initialSamplingRate=';
				  nextPutAll: initialSampler ]
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> jaegerRemoteSamplerFrom: aDictionary resource: anOTResource [

	^ self jaegerRemoteSamplerFrom: aDictionary resource: anOTResource requireInitialSampler: false
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> jaegerRemoteSamplerFrom: aDictionary resource: anOTResource requireInitialSampler: aBoolean [

	| endpoint sampler serviceName |
	OTJaegerRemoteSampler grpcDependenciesAvailable ifFalse: [
			OTTracerProvider noteMissingGrpcDependencyForSampler: 'jaeger_remote'.
			^ OTTracerProvider defaultSampler ].
	serviceName := anOTResource
		               ifNil: [ OTTracerProvider defaultServiceName ]
		               ifNotNil: [
		               anOTResource serviceName ifNil: [ OTTracerProvider defaultServiceName ] ifNotNil: [ anOTResource serviceName ] ].
	sampler := OTJaegerRemoteSampler serviceName: serviceName.
	endpoint := self stringValueAt: 'endpoint' in: aDictionary.
	(aBoolean and: [ endpoint isNil ]) ifTrue: [ Error signal: 'Declarative jaeger_remote/development sampler requires an endpoint' ].
	endpoint ifNotNil: [ sampler endpoint: endpoint ].
	sampler pollingIntervalMillis: (self positiveIntegerValueAt: 'interval' in: aDictionary default: sampler pollingIntervalMillis).
	(aBoolean and: [ (self dictionaryValueAt: 'initial_sampler' in: aDictionary) isNil ]) ifTrue: [
		Error signal: 'Declarative jaeger_remote/development sampler requires an initial_sampler' ].
	(self dictionaryValueAt: 'initial_sampler' in: aDictionary) ifNotNil: [ :value |
		sampler initialSampler: (self samplerFrom: value resource: anOTResource) ].
	^ sampler
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> logRecordExporterFromNode: aDictionary [

	| association exporterOptions exporterType |
	aDictionary ifNil: [ Error signal: 'Declarative configuration processors require an exporter' ].
	association := self singleAssociationFrom: aDictionary describedAs: 'exporter'.
	exporterType := association key.
	exporterOptions := association value ifNil: [ OrderedDictionary new ].
	exporterType = 'console' ifTrue: [ ^ OTConsoleLogRecordExporter new ].
	exporterType = 'otlp_grpc' ifTrue: [
			^ OTOtlpGrpcLogRecordExporter configuration:
				  (self otlpExporterConfigurationFrom: exporterOptions signalNamed: 'LOGS' protocol: 'grpc') ].
	exporterType = 'otlp_http' ifTrue: [
			^ OTOtlpHttpProtobufLogRecordExporter configuration:
				  (self otlpExporterConfigurationFrom: exporterOptions signalNamed: 'LOGS' protocol: 'http/protobuf') ].
	Error signal: 'Unsupported declarative exporter type: ' , exporterType printString
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> logRecordProcessorFrom: aDictionary [

	| exporter kind options processor processorAssociation |
	processorAssociation := self singleAssociationFrom: aDictionary describedAs: 'processor'.
	kind := self normalizedSamplerKind: processorAssociation key.
	options := processorAssociation value ifNil: [ OrderedDictionary new ].
	exporter := self logRecordExporterFromNode: (self exporterNodeFromProcessorNode: options).
	kind = 'simple' ifTrue: [
			^ OTSimpleLogRecordProcessor new
				  exporter: exporter;
				  yourself ].
	kind = 'batch' ifTrue: [
			processor := OTBatchLogRecordProcessor new
				             exporter: exporter;
				             yourself.
			^ self configureBatchLogRecordProcessor: processor from: options ].
	Error signal: 'Unsupported declarative processor type: ' , processorAssociation key printString
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> logRecordProcessorsFrom: aCollection [

	^ aCollection collect: [ :each | self logRecordProcessorFrom: each ]
]

{ #category : 'private - projection' }
OTConfigurationSource class >> loggerConfigFor: anInstrumentationScope rules: aCollection default: anOTLoggerConfig [

	^ self namedScopeConfigFor: anInstrumentationScope rules: aCollection default: anOTLoggerConfig
]

{ #category : 'private - projection' }
OTConfigurationSource class >> loggerConfigFrom: aDictionary [

	| config enabled |
	aDictionary ifNil: [ ^ OTLoggerConfig default ].
	config := OTLoggerConfig default.
	enabled := self enabledValueFrom: aDictionary.
	enabled ifNotNil: [ config enabled: enabled ].
	(self loggerSeverityValueAt: 'minimum_severity' in: aDictionary) ifNotNil: [ :value | config minimumSeverity: value ].
	(self booleanValueAt: 'trace_based' in: aDictionary) ifNotNil: [ :value | config traceBased: value ].
	^ config
]

{ #category : 'private - projection' }
OTConfigurationSource class >> loggerConfiguratorFrom: aDictionary [

	| defaultConfig rules |
	defaultConfig := self loggerConfigFrom: (self dictionaryValueAt: 'default_config' in: aDictionary).
	rules := self loggerConfiguratorRulesFrom: (self sequenceValueAt: 'loggers' in: aDictionary).
	^ [ :scope | self loggerConfigFor: scope rules: rules default: defaultConfig ]
]

{ #category : 'private - projection' }
OTConfigurationSource class >> loggerConfiguratorRuleFrom: aDictionary [

	^ self namedScopeRuleFrom: aDictionary configBlock: [ :configNode | self loggerConfigFrom: configNode ]
]

{ #category : 'private - projection' }
OTConfigurationSource class >> loggerConfiguratorRulesFrom: aCollection [

	aCollection ifNil: [ ^ #(  ) ].
	^ aCollection collect: [ :each | self loggerConfiguratorRuleFrom: each ]
]

{ #category : 'private - projection' }
OTConfigurationSource class >> loggerNamePattern: aPattern at: patternIndex matches: aString at: stringIndex [

	^ self
		  wildcardPattern: aPattern
		  at: patternIndex
		  matches: aString
		  at: stringIndex
]

{ #category : 'private - projection' }
OTConfigurationSource class >> loggerNamePattern: aPattern matches: aString [

	^ self wildcardPattern: aPattern matches: aString
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
OTConfigurationSource class >> mergeResourceAttributesFromListValue: aString into: anOrderedDictionary [

	aString ifNil: [ ^ anOrderedDictionary ].
	(aString substrings: ',') do: [ :each |
			| entry key separator value |
			entry := each trimBoth.
			entry ifNotEmpty: [
					separator := entry indexOf: $=.
					separator > 0 ifFalse: [ Error signal: 'Invalid format for resource.attributes_list entry' ].
					((entry copyFrom: separator + 1 to: entry size) includes: $=) ifTrue: [
						Error signal: 'Invalid format for resource.attributes_list entry' ].
					[
						key := (entry copyFrom: 1 to: separator - 1) urlDecoded.
						value := (entry copyFrom: separator + 1 to: entry size) urlDecoded ]
						on: Error
						do: [ Error signal: 'Failed to percent-decode resource.attributes_list entry ' , entry printString ].
					key isEmpty ifTrue: [ Error signal: 'Empty attribute name in resource.attributes_list entry' ].
					anOrderedDictionary at: key put: value ] ].
	^ anOrderedDictionary
]

{ #category : 'private - projection' }
OTConfigurationSource class >> meterConfigFrom: aDictionary [

	| enabled |
	enabled := self enabledValueFrom: aDictionary.
	^ OTMeterConfig enabled: (enabled ifNil: [ true ] ifNotNil: [ enabled ])
]

{ #category : 'private - projection' }
OTConfigurationSource class >> meterConfiguratorFrom: aDictionary [

	| defaultConfig rules |
	defaultConfig := self meterConfigFrom: (self dictionaryValueAt: 'default_config' in: aDictionary).
	rules := self
		         namedScopeRulesFrom: (self sequenceValueAt: 'meters' in: aDictionary)
		         configBlock: [ :configNode | self meterConfigFrom: configNode ].
	^ [ :scope | self namedScopeConfigFor: scope rules: rules default: defaultConfig ]
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> metricAggregationPreferenceFrom: aStringOrNil [

	| value |
	aStringOrNil ifNil: [ ^ #explicitBucketHistogram ].
	value := aStringOrNil asLowercase.
	value = 'explicit_bucket_histogram' ifTrue: [ ^ #explicitBucketHistogram ].
	value = 'base2_exponential_bucket_histogram' ifTrue: [ ^ #base2ExponentialBucketHistogram ].
	OTOtlpHttpJsonMetricExporter noteInvalidHistogramAggregationPreference: value.
	^ #explicitBucketHistogram
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> metricExporterFromNode: aDictionary [

	| association exporter exporterOptions exporterType |
	aDictionary ifNil: [ Error signal: 'Declarative configuration metric readers require an exporter' ].
	association := self singleAssociationFrom: aDictionary describedAs: 'exporter'.
	exporterType := association key.
	exporterOptions := association value ifNil: [ OrderedDictionary new ].
	exporterType = 'console' ifTrue: [ ^ OTConsoleMetricExporter new ].
	exporterType = 'otlp_grpc' ifTrue: [
			exporter := OTOtlpGrpcMetricExporter configuration:
				            (self otlpExporterConfigurationFrom: exporterOptions signalNamed: 'METRICS' protocol: 'grpc').
			^ self configureOtlpMetricExporter: exporter from: exporterOptions ].
	exporterType = 'otlp_http' ifTrue: [
			exporter := OTOtlpHttpProtobufMetricExporter configuration:
				            (self otlpExporterConfigurationFrom: exporterOptions signalNamed: 'METRICS' protocol: 'http/protobuf').
			^ self configureOtlpMetricExporter: exporter from: exporterOptions ].
	exporterType = 'prometheus' ifTrue: [
		Error signal: 'Declarative periodic metric readers are not representable for Prometheus exporters via SDK environment variables' ].
	Error signal: 'Unsupported declarative exporter type: ' , exporterType printString
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> metricReaderFrom: aDictionary [

	| exporter kind options reader readerAssociation |
	readerAssociation := self singleAssociationFrom: aDictionary describedAs: 'metric reader'.
	kind := self normalizedSamplerKind: readerAssociation key.
	options := readerAssociation value ifNil: [ OrderedDictionary new ].
	kind = 'periodic' ifTrue: [
			exporter := self metricExporterFromNode: (self exporterNodeFromProcessorNode: options).
			reader := OTPeriodicExportingMetricReader exporter: exporter.
			^ self configurePeriodicMetricReader: reader from: options ].
	kind = 'pull' ifTrue: [ ^ self pullMetricReaderFrom: options ].
	Error signal: 'Unsupported declarative metric reader type: ' , readerAssociation key printString
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> metricReadersFrom: aCollection [

	^ aCollection collect: [ :each | self metricReaderFrom: each ]
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> metricTemporalityPreferenceFrom: aStringOrNil [

	| value |
	aStringOrNil ifNil: [ ^ #cumulative ].
	value := aStringOrNil asLowercase.
	value = 'cumulative' ifTrue: [ ^ #cumulative ].
	value = 'delta' ifTrue: [ ^ #delta ].
	value = 'lowmemory' ifTrue: [ ^ #lowMemory ].
	OTOtlpHttpJsonMetricExporter noteInvalidTemporalityPreference: value.
	^ #cumulative
]

{ #category : 'private - projection' }
OTConfigurationSource class >> metricViewAggregationParametersFor: anAssociation [

	| kind options |
	kind := anAssociation key.
	options := anAssociation value ifNil: [ OrderedDictionary new ].
	(#( 'default' 'drop' 'last_value' 'sum' ) includes: kind) ifTrue: [ ^ nil ].
	kind = 'explicit_bucket_histogram' ifTrue: [ ^ self explicitBucketHistogramAggregationParametersFrom: options ].
	kind = 'base2_exponential_bucket_histogram' ifTrue: [ ^ self base2ExponentialHistogramAggregationParametersFrom: options ].
	Error signal: 'Unsupported declarative metric view aggregation: ' , kind printString
]

{ #category : 'private - projection' }
OTConfigurationSource class >> metricViewAttributeFilterFrom: aDictionary [

	| attributeKeys excluded filter included |
	attributeKeys := self dictionaryValueAt: 'attribute_keys' in: aDictionary.
	attributeKeys ifNil: [ ^ nil ].
	included := self stringCollectionValueAt: 'included' in: attributeKeys.
	excluded := self stringCollectionValueAt: 'excluded' in: attributeKeys.
	filter := OTMetricAttributeFilter included: included excluded: excluded.
	filter isAll ifTrue: [ ^ nil ].
	^ filter
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
OTConfigurationSource class >> namedScopeConfigFor: anInstrumentationScope rules: aCollection default: anObject [

	| scopeName |
	scopeName := anInstrumentationScope name.
	aCollection do: [ :each | (self loggerNamePattern: each key matches: scopeName) ifTrue: [ ^ each value ] ].
	^ anObject
]

{ #category : 'private - projection' }
OTConfigurationSource class >> namedScopeRuleFrom: aDictionary configBlock: aBlock [

	| configNode scopeName |
	scopeName := self stringValueAt: 'name' in: aDictionary.
	scopeName ifNil: [ Error signal: 'Declarative scope configurator entries require a name' ].
	configNode := self dictionaryValueAt: 'config' in: aDictionary.
	configNode ifNil: [ Error signal: 'Declarative scope configurator entries require a config' ].
	^ scopeName -> (aBlock value: configNode)
]

{ #category : 'private - projection' }
OTConfigurationSource class >> namedScopeRulesFrom: aCollection configBlock: aBlock [

	aCollection ifNil: [ ^ #(  ) ].
	^ aCollection collect: [ :each | self namedScopeRuleFrom: each configBlock: aBlock ]
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

{ #category : 'private - configuration file' }
OTConfigurationSource class >> nonNegativeIntegerValueAt: aKey in: aDictionary default: aDefaultValue [

	| value |
	value := self integerValueAt: aKey in: aDictionary.
	^ (value isInteger and: [ value >= 0 ])
		  ifTrue: [ value ]
		  ifFalse: [ aDefaultValue ]
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
OTConfigurationSource class >> noteInvalidDeclarativeResourceAttributesList: anError [

	OTTracerProvider resourceConfigurationWarningSink value:
		'OpenTelemetry declarative resource attributes_list was invalid and has been ignored: ' , anError messageText
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> optionalSamplerProbabilityFrom: aDictionary default: aNumber [

	| rawValue value |
	rawValue := aDictionary at: 'ratio' ifAbsent: [ ^ aNumber ].
	rawValue ifNil: [ ^ aNumber ].
	value := self declarativeNumberFrom: rawValue.
	value ifNil: [ Error signal: 'Declarative sampler ratio must be numeric' ].
	^ value
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> otlpBooleanValueAt: aKey in: aDictionary default: aDefaultValue [

	| rawValue value |
	aDictionary ifNil: [ ^ aDefaultValue ].
	(aDictionary includesKey: aKey) ifFalse: [ ^ aDefaultValue ].
	rawValue := aDictionary at: aKey.
	rawValue ifNil: [ ^ aDefaultValue ].
	value := self booleanValueAt: aKey in: aDictionary.
	value ifNotNil: [ ^ value ].
	self invalidDeclarativeOtlpExporterConfigurationAt: aKey value: rawValue expected: 'a boolean'
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> otlpCompressionValueAt: aKey in: aDictionary default: aDefaultValue [

	| compression rawValue |
	aDictionary ifNil: [ ^ aDefaultValue ].
	(aDictionary includesKey: aKey) ifFalse: [ ^ aDefaultValue ].
	rawValue := aDictionary at: aKey.
	rawValue ifNil: [ ^ aDefaultValue ].
	compression := self stringValueAt: aKey in: aDictionary.
	compression ifNil: [ self invalidDeclarativeOtlpExporterConfigurationAt: aKey value: rawValue expected: '''none'' or ''gzip''' ].
	compression := compression asLowercase.
	(#( 'none' 'gzip' ) includes: compression) ifTrue: [ ^ compression ].
	self invalidDeclarativeOtlpExporterConfigurationAt: aKey value: rawValue expected: '''none'' or ''gzip'''
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> otlpExporterConfigurationFrom: aDictionary signalNamed: aString protocol: aProtocolString [

	| certificateFile clientCertificateFile clientKeyFile configuration endpoint |
	configuration := OTOtlpExporterConfiguration new
		                 signalName: aString;
		                 relativePath: (OTOtlpExporterConfiguration defaultRelativePathForSignalNamed: aString);
		                 protocol: aProtocolString;
		                 headers: (self headersDictionaryFrom: (self sequenceValueAt: 'headers_list' in: aDictionary));
		                 userAgent: OTOtlpExporterConfiguration defaultUserAgent;
		                 yourself.
	configuration insecure: (self otlpBooleanValueAt: 'insecure' in: aDictionary default: false).
	endpoint := self stringValueAt: 'endpoint' in: aDictionary.
	endpoint := endpoint
		            ifNil: [
				            aProtocolString = 'grpc'
					            ifTrue: [
					            OTOtlpExporterConfiguration
						            normalizedGrpcEndpoint: OTOtlpExporterConfiguration defaultBaseGrpcEndpoint
						            insecure: false ]
					            ifFalse: [
							            OTOtlpExporterConfiguration
								            normalizedBaseEndpoint: OTOtlpExporterConfiguration defaultBaseHttpEndpoint
								            appendingRelativePath: configuration relativePath ] ]
		            ifNotNil: [
				            aProtocolString = 'grpc'
					            ifTrue: [ OTOtlpExporterConfiguration normalizedGrpcEndpoint: endpoint insecure: configuration insecure ]
					            ifFalse: [ OTOtlpExporterConfiguration normalizedSignalEndpoint: endpoint ] ].
	configuration endpoint: endpoint.
	certificateFile := self stringValueAt: 'certificate' in: aDictionary.
	configuration certificateFile: certificateFile.
	clientKeyFile := self stringValueAt: 'client_key' in: aDictionary.
	configuration clientKeyFile: clientKeyFile.
	clientCertificateFile := self stringValueAt: 'client_certificate' in: aDictionary.
	configuration clientCertificateFile: clientCertificateFile.
	configuration compression:
		(self otlpCompressionValueAt: 'compression' in: aDictionary default: OTOtlpExporterConfiguration defaultCompression).
	configuration timeoutMillis:
		(self otlpTimeoutMillisAt: 'timeout' in: aDictionary default: OTOtlpExporterConfiguration defaultTimeoutMillis).
	^ configuration
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> otlpTimeoutMillisAt: aKey in: aDictionary default: aDefaultValue [

	| rawValue value |
	aDictionary ifNil: [ ^ aDefaultValue ].
	(aDictionary includesKey: aKey) ifFalse: [ ^ aDefaultValue ].
	rawValue := aDictionary at: aKey.
	rawValue ifNil: [ ^ aDefaultValue ].
	value := self integerValueAt: aKey in: aDictionary.
	value ifNil: [
			self
				invalidDeclarativeOtlpExporterConfigurationAt: aKey
				value: rawValue
				expected: 'a non-negative integer timeout in milliseconds' ].
	value >= 0 ifFalse: [
			self
				invalidDeclarativeOtlpExporterConfigurationAt: aKey
				value: rawValue
				expected: 'a non-negative integer timeout in milliseconds' ].
	^ value = 0
		  ifTrue: [ OTOtlpExporterConfiguration noTimeoutMillis ]
		  ifFalse: [ value ]
]

{ #category : 'private - projection' }
OTConfigurationSource class >> parentBasedSamplerEnvironmentPairFrom: aDictionary [

	| root rootPair |
	root := self dictionaryValueAt: 'root' in: aDictionary.
	root ifNil: [ Error signal: 'Declarative parent_based sampler requires a root sampler' ].
	self validateParentBasedDelegateNamed: 'remote_parent_sampled' expectedSampler: 'always_on' in: aDictionary.
	self validateParentBasedDelegateNamed: 'remote_parent_not_sampled' expectedSampler: 'always_off' in: aDictionary.
	self validateParentBasedDelegateNamed: 'local_parent_sampled' expectedSampler: 'always_on' in: aDictionary.
	self validateParentBasedDelegateNamed: 'local_parent_not_sampled' expectedSampler: 'always_off' in: aDictionary.
	rootPair := self samplerEnvironmentPairFrom: root.
	rootPair first = 'always_on' ifTrue: [ ^ #( 'parentbased_always_on' nil ) ].
	rootPair first = 'always_off' ifTrue: [ ^ #( 'parentbased_always_off' nil ) ].
	rootPair first = 'traceidratio' ifTrue: [
			^ {
				  'parentbased_traceidratio'.
				  rootPair second } ].
	rootPair first = 'jaeger_remote' ifTrue: [
			^ {
				  'parentbased_jaeger_remote'.
				  rootPair second } ].
	Error signal: 'Declarative parent_based sampler root is not representable via SDK environment variables'
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> parentBasedSamplerFrom: aDictionary resource: anOTResource [

	| sampler |
	sampler := OTParentBasedSampler default.
	(self dictionaryValueAt: 'root' in: aDictionary) ifNotNil: [ :value |
		sampler rootSampler: (self samplerFrom: value resource: anOTResource) ].
	(self dictionaryValueAt: 'remote_parent_sampled' in: aDictionary) ifNotNil: [ :value |
		sampler remoteParentSampledSampler: (self samplerFrom: value resource: anOTResource) ].
	(self dictionaryValueAt: 'remote_parent_not_sampled' in: aDictionary) ifNotNil: [ :value |
		sampler remoteParentNotSampledSampler: (self samplerFrom: value resource: anOTResource) ].
	(self dictionaryValueAt: 'local_parent_sampled' in: aDictionary) ifNotNil: [ :value |
		sampler localParentSampledSampler: (self samplerFrom: value resource: anOTResource) ].
	(self dictionaryValueAt: 'local_parent_not_sampled' in: aDictionary) ifNotNil: [ :value |
		sampler localParentNotSampledSampler: (self samplerFrom: value resource: anOTResource) ].
	^ sampler
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> parsedConfigurationFromConfigurationFileAt: aString [

	| configurationContents |
	configurationContents := self readConfigurationFileAt: aString.
	^ OTDeclarativeConfigFileParser
		  parse: configurationContents
		  environmentLookup: [ :variableName | self rawEnvironmentValueAt: variableName ]
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> positiveIntegerValueAt: aKey in: aDictionary default: aDefaultValue [

	| value |
	value := self integerValueAt: aKey in: aDictionary.
	^ (value isInteger and: [ value > 0 ])
		  ifTrue: [ value ]
		  ifFalse: [ aDefaultValue ]
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
OTConfigurationSource class >> projectBatchProcessorEnvironmentSettings: aDictionary prefix: aString into: anEnvironment [

	aDictionary ifNil: [ ^ self ].
	self
		put: aString , '_SCHEDULE_DELAY'
		from: 'schedule_delay'
		in: aDictionary
		into: anEnvironment.
	self
		put: aString , '_EXPORT_TIMEOUT'
		from: 'export_timeout'
		in: aDictionary
		into: anEnvironment.
	self
		put: aString , '_MAX_QUEUE_SIZE'
		from: 'max_queue_size'
		in: aDictionary
		into: anEnvironment.
	self
		put: aString , '_MAX_EXPORT_BATCH_SIZE'
		from: 'max_export_batch_size'
		in: aDictionary
		into: anEnvironment.
	^ self
]

{ #category : 'private - projection' }
OTConfigurationSource class >> projectBatchProcessorNode: aDictionary prefix: aString into: anEnvironment [

	aDictionary ifNil: [ ^ self ].
	self
		put: aString , '_SCHEDULE_DELAY'
		from: 'schedule_delay'
		in: aDictionary
		into: anEnvironment.
	self
		put: aString , '_EXPORT_TIMEOUT'
		from: 'export_timeout'
		in: aDictionary
		into: anEnvironment.
	self
		put: aString , '_MAX_QUEUE_SIZE'
		from: 'max_queue_size'
		in: aDictionary
		into: anEnvironment.
	self
		put: aString , '_MAX_EXPORT_BATCH_SIZE'
		from: 'max_export_batch_size'
		in: aDictionary
		into: anEnvironment
]

{ #category : 'private - projection' }
OTConfigurationSource class >> projectCommonSettingsFrom: aConfiguration into: anEnvironment [

	self
		put: 'OTEL_SDK_DISABLED'
		from: 'disabled'
		in: aConfiguration
		into: anEnvironment.
	self
		put: 'OTEL_LOG_LEVEL'
		from: 'log_level'
		in: aConfiguration
		into: anEnvironment.
	self projectAttributeLimitsFrom: aConfiguration into: anEnvironment.
	self projectPropagatorsFrom: aConfiguration into: anEnvironment
]

{ #category : 'private - projection' }
OTConfigurationSource class >> projectExporterConfigurationNode: aDictionary signalNamed: aString into: anEnvironment [

	| endpoint exporterName exporterOptions exporterType headers signalPrefix tls |
	aDictionary ifNil: [ ^ self ].
	aDictionary associations size = 1 ifFalse: [
		Error signal: 'Declarative configuration exporter nodes must contain exactly one exporter' ].
	exporterType := aDictionary associations first key.
	exporterOptions := aDictionary associations first value ifNil: [ OrderedDictionary new ].
	signalPrefix := 'OTEL_EXPORTER_OTLP_' , aString , '_'.
	exporterType = 'console' ifTrue: [ ^ self ].
	exporterType = 'zipkin' ifTrue: [
			aString = 'TRACES' ifFalse: [ Error signal: 'Zipkin declarative configuration is only supported for traces' ].
			self
				put: 'OTEL_EXPORTER_ZIPKIN_ENDPOINT'
				from: 'endpoint'
				in: exporterOptions
				into: anEnvironment.
			self
				put: 'OTEL_EXPORTER_ZIPKIN_TIMEOUT'
				from: 'timeout'
				in: exporterOptions
				into: anEnvironment.
			^ self ].
	exporterType = 'prometheus' ifTrue: [
			aString = 'METRICS' ifFalse: [ Error signal: 'Prometheus declarative configuration is only supported for metrics' ].
			self
				put: 'OTEL_EXPORTER_PROMETHEUS_HOST'
				from: 'host'
				in: exporterOptions
				into: anEnvironment.
			self
				put: 'OTEL_EXPORTER_PROMETHEUS_PORT'
				from: 'port'
				in: exporterOptions
				into: anEnvironment.
			^ self ].
	exporterName := exporterType = 'otlp_grpc'
		                ifTrue: [ 'grpc' ]
		                ifFalse: [
				                exporterType = 'otlp_http'
					                ifTrue: [ 'http/protobuf' ]
					                ifFalse: [ Error signal: 'Unsupported declarative exporter type: ' , exporterType printString ] ].
	anEnvironment at: signalPrefix , 'PROTOCOL' put: exporterName.
	endpoint := self stringValueAt: 'endpoint' in: exporterOptions.
	endpoint ifNotNil: [ anEnvironment at: signalPrefix , 'ENDPOINT' put: endpoint ].
	self
		put: signalPrefix , 'COMPRESSION'
		from: 'compression'
		in: exporterOptions
		into: anEnvironment.
	self
		put: signalPrefix , 'TIMEOUT'
		from: 'timeout'
		in: exporterOptions
		into: anEnvironment.
	headers := self headersListStringFrom: (self sequenceValueAt: 'headers_list' in: exporterOptions).
	headers ifNotNil: [ anEnvironment at: signalPrefix , 'HEADERS' put: headers ].
	tls := self dictionaryValueAt: 'tls' in: exporterOptions.
	tls ifNil: [ ^ self ].
	self
		put: signalPrefix , 'CERTIFICATE'
		from: 'ca_file'
		in: tls
		into: anEnvironment.
	self
		put: signalPrefix , 'CLIENT_KEY'
		from: 'key_file'
		in: tls
		into: anEnvironment.
	self
		put: signalPrefix , 'CLIENT_CERTIFICATE'
		from: 'cert_file'
		in: tls
		into: anEnvironment
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
	self
		put: 'OTEL_METRICS_EXEMPLAR_FILTER'
		fromAnyOf: #( 'exemplar_filter' 'exemplar' )
		in: meterProvider
		into: anEnvironment.
	self projectMetricReadersFrom: meterProvider into: anEnvironment
]

{ #category : 'private - projection' }
OTConfigurationSource class >> projectMetricReadersFrom: aDictionary into: anEnvironment [

	| exporters metricExporterSettings periodicSettings readers |
	readers := self sequenceValueAt: 'readers' in: aDictionary.
	readers ifNil: [ ^ self ].
	readers ifEmpty: [
			anEnvironment at: 'OTEL_METRICS_EXPORTER' put: 'none'.
			^ self ].
	[
		exporters := self projectedMetricExporterNodesFromReaders: readers.
		periodicSettings := self sharedPeriodicMetricReaderSettingsFrom: readers.
		periodicSettings ifNotNil: [
				self
					put: 'OTEL_METRIC_EXPORT_INTERVAL'
					from: 'interval'
					in: periodicSettings
					into: anEnvironment.
				self
					put: 'OTEL_METRIC_EXPORT_TIMEOUT'
					from: 'timeout'
					in: periodicSettings
					into: anEnvironment ].
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
		anEnvironment at: 'OTEL_METRICS_EXPORTER' put: (self projectedExporterSelectionFrom: exporters).
		exporters values do: [ :each | self projectExporterConfigurationNode: each signalNamed: 'METRICS' into: anEnvironment ] ]
		on: Error
		do: [ :error | (self shouldIgnoreProjectionError: error) ifFalse: [ error pass ] ].
	^ self
]

{ #category : 'private - projection' }
OTConfigurationSource class >> projectProcessorSequenceFrom: aDictionary signalNamed: aString batchPrefix: anotherString into: anEnvironment [

	| batchSettings exporters processors |
	processors := self sequenceValueAt: 'processors' in: aDictionary.
	processors ifNil: [ ^ self ].
	processors ifEmpty: [
			anEnvironment at: (self exportEnvironmentNameForSignalNamed: aString) put: 'none'.
			^ self ].
	[
		exporters := self projectedExporterNodesFromProcessors: processors signalNamed: aString.
		batchSettings := self sharedBatchProcessorSettingsFrom: processors.
		batchSettings ifNotNil: [
			self projectBatchProcessorEnvironmentSettings: batchSettings prefix: anotherString into: anEnvironment ].
		anEnvironment at: (self exportEnvironmentNameForSignalNamed: aString) put: (self projectedExporterSelectionFrom: exporters).
		exporters values do: [ :each | self projectExporterConfigurationNode: each signalNamed: aString into: anEnvironment ] ]
		on: Error
		do: [ :error | (self shouldIgnoreProjectionError: error) ifFalse: [ error pass ] ].
	^ self
]

{ #category : 'private - projection' }
OTConfigurationSource class >> projectPropagatorsFrom: aConfiguration into: anEnvironment [

	| compositeNodes compositeList propagator |
	propagator := self dictionaryValueAt: 'propagator' in: aConfiguration.
	propagator ifNil: [ ^ self ].
	compositeNodes := self sequenceValueAt: 'composite' in: propagator.
	compositeList := self nodeKindsStringFrom: compositeNodes.
	compositeList ifNil: [ compositeList := self stringValueAt: 'composite' in: propagator ].
	compositeList ifNil: [ compositeList := self stringValueAt: 'composite_list' in: propagator ].
	compositeList ifNotNil: [ anEnvironment at: 'OTEL_PROPAGATORS' put: compositeList ]
]

{ #category : 'private - projection' }
OTConfigurationSource class >> projectResourceFrom: aConfiguration into: anEnvironment [

	| attributes explicitAttributes resource resourceString serviceName |
	resource := self dictionaryValueAt: 'resource' in: aConfiguration.
	resource ifNil: [ ^ self ].
	attributes := OrderedDictionary new.
	attributes addAll: (self resourceAttributesFromListValue: (self stringValueAt: 'attributes_list' in: resource)).
	explicitAttributes := self sequenceValueAt: 'attributes' in: resource.
	explicitAttributes ifNotNil: [
			explicitAttributes do: [ :each |
					| key value |
					key := self stringValueAt: 'name' in: each.
					value := self stringValueAt: 'value' in: each.
					(key isNil or: [ value isNil ]) ifFalse: [ attributes at: key put: value ] ] ].
	resourceString := self encodedResourceAttributesFrom: attributes.
	resourceString ifNotNil: [ anEnvironment at: 'OTEL_RESOURCE_ATTRIBUTES' put: resourceString ].
	serviceName := attributes at: 'service.name' ifAbsent: [ nil ].
	serviceName ifNotNil: [ anEnvironment at: 'OTEL_SERVICE_NAME' put: serviceName ]
]

{ #category : 'private - projection' }
OTConfigurationSource class >> projectSpanLimitsFrom: aDictionary into: anEnvironment [

	| limits |
	limits := self dictionaryValueAt: 'limits' in: aDictionary.
	limits ifNil: [ ^ self ].
	self
		put: 'OTEL_SPAN_ATTRIBUTE_COUNT_LIMIT'
		from: 'attribute_count_limit'
		in: limits
		into: anEnvironment.
	self
		put: 'OTEL_SPAN_ATTRIBUTE_VALUE_LENGTH_LIMIT'
		from: 'attribute_value_length_limit'
		in: limits
		into: anEnvironment.
	self
		put: 'OTEL_SPAN_EVENT_COUNT_LIMIT'
		from: 'event_count_limit'
		in: limits
		into: anEnvironment.
	self
		put: 'OTEL_SPAN_LINK_COUNT_LIMIT'
		from: 'link_count_limit'
		in: limits
		into: anEnvironment.
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
	[
		samplerPair := self samplerEnvironmentPairFrom: sampler.
		anEnvironment at: 'OTEL_TRACES_SAMPLER' put: samplerPair first.
		samplerPair second ifNotNil: [ anEnvironment at: 'OTEL_TRACES_SAMPLER_ARG' put: samplerPair second ] ]
		on: Error
		do: [ :error | (self shouldIgnoreProjectionError: error) ifFalse: [ error pass ] ].
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
OTConfigurationSource class >> projectedBatchProcessorSettingsFrom: aDictionary [

	| settings |
	settings := OrderedDictionary new.
	#( 'schedule_delay' 'export_timeout' 'max_queue_size' 'max_export_batch_size' ) do: [ :each |
		(self stringValueAt: each in: aDictionary) ifNotNil: [ :value | settings at: each put: value ] ].
	^ settings
]

{ #category : 'private - projection' }
OTConfigurationSource class >> projectedEnvironmentValuesFromConfiguration: aConfiguration [

	| projectedEnvironment fileFormat |
	projectedEnvironment := OrderedDictionary new.
	fileFormat := self stringValueAt: 'file_format' in: aConfiguration.
	(fileFormat notNil and: [ fileFormat ~= '1.0' and: [ fileFormat ~= '1.1' ] ]) ifTrue: [
		Error signal: 'Unsupported declarative configuration file_format: ' , fileFormat printString ].
	self projectCommonSettingsFrom: aConfiguration into: projectedEnvironment.
	self projectTracerProviderFrom: aConfiguration into: projectedEnvironment.
	self projectMeterProviderFrom: aConfiguration into: projectedEnvironment.
	self projectLoggerProviderFrom: aConfiguration into: projectedEnvironment.
	^ projectedEnvironment
]

{ #category : 'private - projection' }
OTConfigurationSource class >> projectedExporterEnvironmentNameFrom: aDictionary signalNamed: aString [

	| association exporterType |
	aDictionary ifNil: [ Error signal: 'Declarative configuration processors require an exporter' ].
	association := self samplerAssociationFrom: aDictionary.
	exporterType := association key.
	exporterType = 'console' ifTrue: [ ^ 'console' ].
	exporterType = 'zipkin' ifTrue: [
			aString = 'TRACES' ifFalse: [ Error signal: 'Zipkin declarative configuration is only supported for traces' ].
			^ 'zipkin' ].
	exporterType = 'prometheus' ifTrue: [
			aString = 'METRICS' ifFalse: [ Error signal: 'Prometheus declarative configuration is only supported for metrics' ].
			^ 'prometheus' ].
	(#( 'otlp_grpc' 'otlp_http' ) includes: exporterType) ifTrue: [ ^ 'otlp' ].
	Error signal: 'Unsupported declarative exporter type: ' , exporterType printString
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
			self validateProcessorKind: processorKind exporterName: exporterName node: each.
			batchSettings := self projectedBatchProcessorSettingsFrom: processorOptions.
			processorKind = 'simple' ifTrue: [
					batchSettings isEmpty ifFalse: [
						Error signal: 'Declarative simple processor settings are not representable via SDK environment variables' ] ].
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
			self validateMetricExporterSettingsIn: exporterNode exporterName: exporterName.
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
		(self stringValueAt: each in: exporterOptions) ifNotNil: [ :value | settings at: each put: value ] ].
	^ settings
]

{ #category : 'private - projection' }
OTConfigurationSource class >> projectedPeriodicMetricReaderSettingsFrom: aDictionary [

	| settings |
	settings := OrderedDictionary new.
	#( 'interval' 'timeout' ) do: [ :each |
		(self stringValueAt: each in: aDictionary) ifNotNil: [ :value | settings at: each put: value ] ].
	^ settings
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> pullMetricReaderFrom: aDictionary [

	| association exporterOptions exporterType reader |
	(self stringValueAt: 'interval' in: aDictionary) ifNotNil: [
			Error signal:
				'Declarative pull metric readers are not representable with interval or timeout settings via SDK environment variables' ].
	(self stringValueAt: 'timeout' in: aDictionary) ifNotNil: [
			Error signal:
				'Declarative pull metric readers are not representable with interval or timeout settings via SDK environment variables' ].
	association := self singleAssociationFrom: (self exporterNodeFromProcessorNode: aDictionary) describedAs: 'exporter'.
	exporterType := association key.
	exporterOptions := association value ifNil: [ OrderedDictionary new ].
	exporterType = 'prometheus' ifFalse: [
		Error signal: 'Declarative pull metric readers are only representable for Prometheus exporters via SDK environment variables' ].
	reader := OTPrometheusMetricReader new.
	(self stringValueAt: 'host' in: exporterOptions) ifNotNil: [ :value | reader host: value ].
	reader port: (self nonNegativeIntegerValueAt: 'port' in: exporterOptions default: reader port).
	^ reader
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

{ #category : 'accessing' }
OTConfigurationSource class >> rawEnvironmentValueAt: aString [

	| value |
	value := Smalltalk os environment at: aString ifAbsent: [ ^ nil ].
	value := value asString trimBoth.
	^ value isEmpty
		  ifTrue: [ nil ]
		  ifFalse: [ value ]
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> readConfigurationFileAt: aString [

	| fileReference |
	fileReference := aString asFileReference.
	fileReference exists ifFalse: [
		Error signal: 'OpenTelemetry declarative configuration file was not found: ' , aString printString ].
	^ fileReference contents
]

{ #category : 'private - projection' }
OTConfigurationSource class >> requiredDeclarativeBoolean: anObject type: aString [

	^ self requiredDeclarativeValue: (self declarativeBooleanFrom: anObject) original: anObject type: aString
]

{ #category : 'private - projection' }
OTConfigurationSource class >> requiredDeclarativeInteger: anObject type: aString [

	^ self requiredDeclarativeValue: (self declarativeIntegerFrom: anObject) original: anObject type: aString
]

{ #category : 'private - projection' }
OTConfigurationSource class >> requiredDeclarativeNumber: anObject type: aString [

	^ self requiredDeclarativeValue: (self declarativeNumberFrom: anObject) original: anObject type: aString
]

{ #category : 'private - projection' }
OTConfigurationSource class >> requiredDeclarativeValue: anObjectOrNil original: originalObject type: aString [

	anObjectOrNil ifNotNil: [ ^ anObjectOrNil ].
	Error signal: 'Declarative resource attribute value does not match type ' , aString , ': ' , originalObject printString
]

{ #category : 'class initialization' }
OTConfigurationSource class >> reset [

	self cachedConfigurationFilePath: nil.
	self cachedEnvironmentValues: nil.
	self cachedParsedConfiguration: nil
]

{ #category : 'private - projection' }
OTConfigurationSource class >> resourceAttributesFromListValue: aString [

	| attributes |
	aString ifNil: [ ^ OrderedDictionary new ].
	attributes := OrderedDictionary new.
	^ [ self mergeResourceAttributesFromListValue: aString into: attributes ]
		  on: Error
		  do: [ :error |
				  self noteInvalidDeclarativeResourceAttributesList: error.
				  OrderedDictionary new ]
]

{ #category : 'private - projection' }
OTConfigurationSource class >> samplerAssociationFrom: aDictionary [

	^ self singleAssociationFrom: aDictionary describedAs: 'sampler'
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> samplerAttributeStringValuesFrom: anObject [

	anObject ifNil: [ ^ #(  ) ].
	(anObject isCollection and: [ anObject isString not and: [ anObject isDictionary not ] ]) ifTrue: [
		^ anObject collect: [ :each | each asString ] as: Array ].
	^ { anObject asString }
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> samplerAttributeStringValuesNamed: aString in: attributes [

	| value |
	attributes ifNil: [ ^ #(  ) ].
	value := attributes isDictionary
		         ifTrue: [ attributes at: aString ifAbsent: [ nil ] ]
		         ifFalse: [
		         attributes
			         detect: [ :each | each isAssociation and: [ each key = aString ] ]
			         ifFound: [ :each | each value ]
			         ifNone: [ nil ] ].
	^ self samplerAttributeStringValuesFrom: value
]

{ #category : 'private - projection' }
OTConfigurationSource class >> samplerEnvironmentPairFrom: aDictionary [

	| association kind options ratio |
	association := self samplerAssociationFrom: aDictionary.
	kind := self normalizedSamplerKind: association key.
	options := association value ifNil: [ OrderedDictionary new ].
	kind = 'always_on' ifTrue: [ ^ #( 'always_on' nil ) ].
	kind = 'always_off' ifTrue: [ ^ #( 'always_off' nil ) ].
	kind = 'always_record' ifTrue: [
		Error signal: 'Declarative always_record sampler is not representable via SDK environment variables' ].
	kind = 'composite' ifTrue: [
		Error signal: 'Declarative composite/development sampler is not representable via SDK environment variables' ].
	association key = 'probability/development' ifTrue: [
		Error signal: 'Declarative probability/development sampler is not representable via SDK environment variables' ].
	kind = 'probability' ifTrue: [
		Error signal: 'Declarative probability sampler is not representable via SDK environment variables' ].
	kind = 'trace_id_ratio_based' ifTrue: [
			ratio := self stringValueAt: 'ratio' in: options.
			ratio ifNil: [ ratio := '1' ].
			^ {
				  'traceidratio'.
				  ratio } ].
	kind = 'parent_based' ifTrue: [ ^ self parentBasedSamplerEnvironmentPairFrom: options ].
	kind = 'jaeger_remote' ifTrue: [
			^ {
				  'jaeger_remote'.
				  (self jaegerRemoteSamplerArgumentFrom: options) } ].
	Error signal: 'Unsupported declarative sampler type: ' , association key printString
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> samplerFrom: aDictionary resource: anOTResource [

	| association kind options probability root |
	association := self samplerAssociationFrom: aDictionary.
	kind := self normalizedSamplerKind: association key.
	options := association value ifNil: [ OrderedDictionary new ].
	kind = 'always_on' ifTrue: [ ^ OTAlwaysOnSampler new ].
	kind = 'always_off' ifTrue: [ ^ OTAlwaysOffSampler new ].
	kind = 'always_record' ifTrue: [
			root := self dictionaryValueAt: 'root' in: options.
			root ifNil: [ Error signal: 'Declarative always_record sampler requires a root sampler' ].
			^ OTSampler alwaysRecord: (self samplerFrom: root resource: anOTResource) ].
	kind = 'composite' ifTrue: [ ^ OTSampler composite: (self composableSamplerFrom: options) ].
	association key = 'probability/development' ifTrue: [
			probability := self optionalSamplerProbabilityFrom: options default: 1.
			^ OTSampler probabilityOrAlwaysOff: probability ].
	kind = 'probability' ifTrue: [
			probability := self declarativeNumberFrom: (options at: 'ratio' ifAbsent: [ nil ]).
			probability ifNil: [ Error signal: 'Declarative configuration probability samplers require a ratio' ].
			^ OTSampler probability: probability ].
	kind = 'trace_id_ratio_based' ifTrue: [
			probability := self optionalSamplerProbabilityFrom: options default: 1.
			^ OTSampler traceIdRatioBased: probability ].
	kind = 'parent_based' ifTrue: [ ^ self parentBasedSamplerFrom: options resource: anOTResource ].
	association key = 'jaeger_remote/development' ifTrue: [
		^ self jaegerRemoteSamplerFrom: options resource: anOTResource requireInitialSampler: true ].
	kind = 'jaeger_remote' ifTrue: [ ^ self jaegerRemoteSamplerFrom: options resource: anOTResource ].
	Error signal: 'Unsupported declarative sampler type: ' , association key printString
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> samplerParentTypeForContext: aContext [

	| parentSpan spanContext |
	aContext ifNil: [ ^ #none ].
	parentSpan := aContext span.
	parentSpan ifNil: [ ^ #none ].
	spanContext := parentSpan spanContext.
	spanContext isValid ifFalse: [ ^ #none ].
	^ spanContext isRemote
		  ifTrue: [ #remote ]
		  ifFalse: [ #local ]
]

{ #category : 'private - projection' }
OTConfigurationSource class >> sequenceValueAt: aKey in: aDictionary [

	| value |
	aDictionary ifNil: [ ^ nil ].
	value := aDictionary at: aKey ifAbsent: [ ^ nil ].
	^ value isArray
		  ifTrue: [ value ]
		  ifFalse: [
				  (value isSequenceable and: [ value isString not ])
					  ifTrue: [ value asArray ]
					  ifFalse: [ nil ] ]
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
							foundSettings ifNil: [ foundSettings := settings ] ifNotNil: [
									foundSettings = settings ifFalse: [
										Error signal: 'Declarative processor sequence configures incompatible batch processor settings for one signal' ] ] ] ] ].
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
							foundSettings ifNil: [ foundSettings := settings ] ifNotNil: [
									foundSettings = settings ifFalse: [
										Error signal: 'Declarative metric readers configure incompatible OTLP reader settings for one signal' ] ] ] ] ].
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
							foundSettings ifNil: [ foundSettings := settings ] ifNotNil: [
									foundSettings = settings ifFalse: [
										Error signal: 'Declarative metric readers configure incompatible periodic reader settings for one signal' ] ] ] ] ].
	^ foundSettings
]

{ #category : 'private - projection' }
OTConfigurationSource class >> shouldIgnoreProjectionError: anError [

	| message |
	message := anError messageText.
	^ (message includesSubstring: 'not representable via SDK environment variables') or: [
			  (message includesSubstring: 'representable for ') or: [
					  (message includesSubstring: 'incompatible batch processor settings') or: [
							  (message includesSubstring: 'incompatible OTLP reader settings') or: [
								  message includesSubstring: 'incompatible periodic reader settings' ] ] ] ]
]

{ #category : 'private - projection' }
OTConfigurationSource class >> singleAssociationFrom: aDictionary describedAs: aString [

	aDictionary ifNil: [ Error signal: 'Declarative configuration ' , aString , ' nodes must not be nil' ].
	aDictionary associations size = 1 ifFalse: [
		Error signal: 'Declarative configuration ' , aString , ' nodes must contain exactly one entry' ].
	^ aDictionary associations first
]

{ #category : 'private - projection' }
OTConfigurationSource class >> stringCollectionValueAt: aKey in: aDictionary [

	| values |
	values := self sequenceValueAt: aKey in: aDictionary.
	values ifNil: [ ^ nil ].
	^ values collect: [ :each | each asString ]
]

{ #category : 'private - projection' }
OTConfigurationSource class >> stringValueAt: aKey in: aDictionary [

	| value |
	aDictionary ifNil: [ ^ nil ].
	value := aDictionary at: aKey ifAbsent: [ ^ nil ].
	value ifNil: [ ^ nil ].
	(value isString or: [ value isSymbol ]) ifFalse: [ ^ nil ].
	value := value asString trimBoth.
	^ value isEmpty
		  ifTrue: [ nil ]
		  ifFalse: [ value ]
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> traceExporterFromNode: aDictionary [

	| association endpoint exporter exporterOptions exporterType |
	aDictionary ifNil: [ Error signal: 'Declarative configuration processors require an exporter' ].
	association := self singleAssociationFrom: aDictionary describedAs: 'exporter'.
	exporterType := association key.
	exporterOptions := association value ifNil: [ OrderedDictionary new ].
	exporterType = 'console' ifTrue: [ ^ OTConsoleSpanExporter new ].
	exporterType = 'zipkin' ifTrue: [
			exporter := OTSpanExporter defaultZipkinExporter.
			endpoint := self stringValueAt: 'endpoint' in: exporterOptions.
			endpoint ifNotNil: [ exporter httpClient url: endpoint ].
			exporter httpClient timeout:
				(self zipkinTimeoutMillisAt: 'timeout' in: exporterOptions default: OTSpanExporter defaultZipkinTimeoutMillis).
			^ exporter ].
	exporterType = 'otlp_grpc' ifTrue: [
			^ OTOtlpGrpcSpanExporter configuration:
				  (self otlpExporterConfigurationFrom: exporterOptions signalNamed: 'TRACES' protocol: 'grpc') ].
	exporterType = 'otlp_http' ifTrue: [
			^ OTOtlpHttpProtobufSpanExporter configuration:
				  (self otlpExporterConfigurationFrom: exporterOptions signalNamed: 'TRACES' protocol: 'http/protobuf') ].
	Error signal: 'Unsupported declarative exporter type: ' , exporterType printString
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> traceProcessorFrom: aDictionary [

	| exporter kind options processor processorAssociation |
	processorAssociation := self singleAssociationFrom: aDictionary describedAs: 'processor'.
	kind := self normalizedSamplerKind: processorAssociation key.
	options := processorAssociation value ifNil: [ OrderedDictionary new ].
	exporter := self traceExporterFromNode: (self exporterNodeFromProcessorNode: options).
	kind = 'simple' ifTrue: [ ^ OTSimpleSpanProcessor new exporter: exporter ].
	kind = 'batch' ifTrue: [
			processor := OTBatchSpanProcessor new exporter: exporter.
			^ self configureBatchSpanProcessor: processor from: options ].
	Error signal: 'Unsupported declarative processor type: ' , processorAssociation key printString
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> traceProcessorsFrom: aCollection [

	^ aCollection collect: [ :each | self traceProcessorFrom: each ]
]

{ #category : 'private - projection' }
OTConfigurationSource class >> tracerConfiguratorFrom: aDictionary [

	| defaultConfig rules |
	defaultConfig := self tracerEnabledFrom: (self dictionaryValueAt: 'default_config' in: aDictionary).
	rules := self
		         namedScopeRulesFrom: (self sequenceValueAt: 'tracers' in: aDictionary)
		         configBlock: [ :configNode | self tracerEnabledFrom: configNode ].
	^ [ :scope | self namedScopeConfigFor: scope rules: rules default: defaultConfig ]
]

{ #category : 'private - projection' }
OTConfigurationSource class >> tracerEnabledFrom: aDictionary [

	^ self enabledValueFrom: aDictionary
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
			Error signal: 'Declarative pull metric readers are only representable for Prometheus exporters via SDK environment variables' ].
	Error signal: 'Unsupported declarative metric reader type: ' , (self samplerAssociationFrom: aDictionary) key printString
]

{ #category : 'private - projection' }
OTConfigurationSource class >> validateParentBasedDelegateNamed: aString expectedSampler: anotherString in: aDictionary [

	| delegate |
	delegate := self dictionaryValueAt: aString in: aDictionary.
	delegate ifNil: [ ^ self ].
	(self normalizedSamplerKind: (self samplerAssociationFrom: delegate) key) = anotherString ifFalse: [
			Error signal:
				'Declarative parent_based sampler delegate is not representable via SDK environment variables: ' , aString printString ].
	^ self
]

{ #category : 'private - projection' }
OTConfigurationSource class >> validateProcessorKind: aString exporterName: anotherString node: aDictionary [

	aString = 'simple' ifTrue: [
			anotherString = 'console' ifTrue: [ ^ self ].
			Error signal: 'Declarative simple processors are only representable for console exporters via SDK environment variables' ].
	aString = 'batch' ifTrue: [
			anotherString = 'console' ifTrue: [
				Error signal: 'Declarative batch processors are not representable for console exporters via SDK environment variables' ].
			^ self ].
	Error signal: 'Unsupported declarative processor type: ' , (self samplerAssociationFrom: aDictionary) key printString
]

{ #category : 'private - projection' }
OTConfigurationSource class >> wildcardPattern: aPattern at: patternIndex matches: aString at: stringIndex [

	| character |
	patternIndex > aPattern size ifTrue: [ ^ stringIndex > aString size ].
	character := aPattern at: patternIndex.
	character = $* ifTrue: [
			patternIndex = aPattern size ifTrue: [ ^ true ].
			stringIndex to: aString size + 1 do: [ :eachIndex |
					(self
						 wildcardPattern: aPattern
						 at: patternIndex + 1
						 matches: aString
						 at: eachIndex) ifTrue: [ ^ true ] ].
			^ false ].
	stringIndex > aString size ifTrue: [ ^ false ].
	(character = $? or: [ character = (aString at: stringIndex) ]) ifFalse: [ ^ false ].
	^ self
		  wildcardPattern: aPattern
		  at: patternIndex + 1
		  matches: aString
		  at: stringIndex + 1
]

{ #category : 'private - projection' }
OTConfigurationSource class >> wildcardPattern: aPattern matches: aString [

	aPattern = '*' ifTrue: [ ^ true ].
	((aPattern includes: $*) or: [ aPattern includes: $? ]) ifTrue: [
			^ self
				  wildcardPattern: aPattern
				  at: 1
				  matches: aString
				  at: 1 ].
	^ aPattern = aString
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> wildcardPatterns: patterns match: aString [

	^ patterns anySatisfy: [ :each | self wildcardPattern: each matches: aString ]
]

{ #category : 'private - configuration file' }
OTConfigurationSource class >> zipkinTimeoutMillisAt: aKey in: aDictionary default: aDefaultValue [

	| rawValue value |
	aDictionary ifNil: [ ^ aDefaultValue ].
	(aDictionary includesKey: aKey) ifFalse: [ ^ aDefaultValue ].
	rawValue := aDictionary at: aKey.
	rawValue ifNil: [ ^ aDefaultValue ].
	value := self integerValueAt: aKey in: aDictionary.
	value ifNil: [
			Error signal: 'Invalid Zipkin declarative configuration for ' , aKey printString , ': ' , rawValue printString
				, '. Expected a non-negative integer timeout in milliseconds' ].
	value >= 0 ifFalse: [
			Error signal: 'Invalid Zipkin declarative configuration for ' , aKey printString , ': ' , rawValue printString
				, '. Expected a non-negative integer timeout in milliseconds' ].
	^ value = 0
		  ifTrue: [ nil ]
		  ifFalse: [ value ]
]
