"
A backend-agnostic entry point to the OpenTelemetry logs API and SDK.
"
Class {
	#name : 'OTLoggerProvider',
	#superclass : 'Object',
	#instVars : [
		'loggers',
		'resource',
		'logRecordProcessors',
		'logRecordLimits',
		'loggerConfigurator',
		'shutdown'
	],
	#classVars : [
		'Current'
	],
	#category : 'OpenTelemetry-Logs',
	#package : 'OpenTelemetry-Logs'
}

{ #category : 'private - configuration' }
OTLoggerProvider class >> batchLogRecordProcessorExportTimeoutMillis [

	^ self
		  nonNegativeIntegerEnvironmentValueAt: 'OTEL_BLRP_EXPORT_TIMEOUT'
		  default: OTBatchLogRecordProcessor new exportTimeoutMillis
]

{ #category : 'private - configuration' }
OTLoggerProvider class >> batchLogRecordProcessorMaxExportBatchSizeForQueueSize: maxQueueSize [

	| rawValue parsed |
	rawValue := self environmentValueAt: 'OTEL_BLRP_MAX_EXPORT_BATCH_SIZE'.
	parsed := rawValue ifNil: [ OTBatchLogRecordProcessor new maxExportBatchSize ] ifNotNil: [
			          (self strictPositiveIntegerFrom: rawValue)
				          ifNil: [
						          self noteInvalidBatchProcessorEnvironmentValue: rawValue forVariable: 'OTEL_BLRP_MAX_EXPORT_BATCH_SIZE'.
						          OTBatchLogRecordProcessor new maxExportBatchSize ]
				          ifNotNil: [ :value | value ] ].
	^ parsed min: maxQueueSize
]

{ #category : 'private - configuration' }
OTLoggerProvider class >> batchLogRecordProcessorMaxQueueSize [

	^ self positiveIntegerEnvironmentValueAt: 'OTEL_BLRP_MAX_QUEUE_SIZE' default: OTBatchLogRecordProcessor new maxQueueSize
]

{ #category : 'private - configuration' }
OTLoggerProvider class >> batchLogRecordProcessorScheduledDelayMillis [

	^ self
		  nonNegativeIntegerEnvironmentValueAt: 'OTEL_BLRP_SCHEDULE_DELAY'
		  default: OTBatchLogRecordProcessor new scheduledDelayMillis
]

{ #category : 'private - configuration' }
OTLoggerProvider class >> batchLogRecordProcessorWithExporter: anExporter [

	| maxExportBatchSize maxQueueSize processor |
	processor := OTBatchLogRecordProcessor new
		             exporter: anExporter;
		             yourself.
	maxQueueSize := self batchLogRecordProcessorMaxQueueSize.
	maxExportBatchSize := self batchLogRecordProcessorMaxExportBatchSizeForQueueSize: maxQueueSize.
	processor
		maxQueueSize: maxQueueSize;
		maxExportBatchSize: maxExportBatchSize;
		scheduledDelayMillis: self batchLogRecordProcessorScheduledDelayMillis;
		exportTimeoutMillis: self batchLogRecordProcessorExportTimeoutMillis.
	^ processor
]

{ #category : 'private' }
OTLoggerProvider class >> configurationSourceClass [

	^ OpenTelemetry dependencyClassNamed: #OTConfigurationSource ifAbsent: [ nil ]
]

{ #category : 'private - logging' }
OTLoggerProvider class >> configurationWarningSink [

	^ OTClassStateStore
		  valueAt: #otLoggerProviderConfigurationWarningSink
		  forClass: self
		  ifAbsent: [ self defaultConfigurationWarningSink ]
]

{ #category : 'private - logging' }
OTLoggerProvider class >> configurationWarningSink: aBlock [

	aBlock
		ifNil: [ OTClassStateStore removeValueAt: #otLoggerProviderConfigurationWarningSink forClass: self ifAbsent: [ ] ]
		ifNotNil: [ OTClassStateStore valueAt: #otLoggerProviderConfigurationWarningSink forClass: self put: aBlock ].
	^ self configurationWarningSink
]

{ #category : 'private - configuration' }
OTLoggerProvider class >> configuredExporterNames [

	| rawValue |
	rawValue := self environmentValueAt: 'OTEL_LOGS_EXPORTER'.
	rawValue ifNil: [ ^ #( 'otlp' ) ].
	^ (self exporterNamesFromConfigurationValue: rawValue) ifNil: [ #( 'otlp' ) ] ifNotNil: [ :names | names ]
]

{ #category : 'instance creation' }
OTLoggerProvider class >> configuredLogRecordLimits [

	| defaultLimits generalAttributeCountLimit generalValueLengthLimit limits |
	defaultLimits := OTLogRecordLimits default.
	generalAttributeCountLimit := OTTracerProvider
		                              nonNegativeIntegerEnvironmentValueAt: 'OTEL_ATTRIBUTE_COUNT_LIMIT'
		                              default: defaultLimits attributeCountLimit.
	generalValueLengthLimit := OTTracerProvider
		                           nonNegativeIntegerEnvironmentValueAt: 'OTEL_ATTRIBUTE_VALUE_LENGTH_LIMIT'
		                           default: defaultLimits attributeValueLengthLimit.
	limits := OTLogRecordLimits default.
	limits
		attributeCountLimit:
			(OTTracerProvider
				 nonNegativeIntegerEnvironmentValueAt: 'OTEL_LOGRECORD_ATTRIBUTE_COUNT_LIMIT'
				 default: generalAttributeCountLimit);
		attributeValueLengthLimit: (OTTracerProvider
				 nonNegativeIntegerEnvironmentValueAt: 'OTEL_LOGRECORD_ATTRIBUTE_VALUE_LENGTH_LIMIT'
				 default: generalValueLengthLimit).
	^ limits
]

{ #category : 'instance creation' }
OTLoggerProvider class >> configuredOtlpExporter [

	| configuration |
	configuration := OTOtlpExporterConfiguration forSignalNamed: 'LOGS'.
	configuration protocol = OTOtlpGrpcLogRecordExporter supportedProtocol ifTrue: [
		^ OTOtlpGrpcLogRecordExporter configuration: configuration ].
	configuration protocol = OTOtlpHttpJsonLogRecordExporter supportedProtocol ifTrue: [
		^ OTOtlpHttpJsonLogRecordExporter configuration: configuration ].
	configuration protocol = OTOtlpHttpProtobufLogRecordExporter supportedProtocol ifTrue: [
		^ OTOtlpHttpProtobufLogRecordExporter configuration: configuration ].
	self noteUnsupportedOtlpProtocol: configuration protocol.
	^ OTOtlpHttpProtobufLogRecordExporter configuration: configuration
]

{ #category : 'accessing' }
OTLoggerProvider class >> current [

	^ Current ifNil: [ Current := self readConfiguration ]
]

{ #category : 'accessing' }
OTLoggerProvider class >> current: anOTLoggerProvider [

	Current := anOTLoggerProvider
]

{ #category : 'private - logging' }
OTLoggerProvider class >> defaultConfigurationWarningSink [

	^ OTDiagnosticLogger defaultWarningSink
]

{ #category : 'instance creation' }
OTLoggerProvider class >> defaultLoggerConfig [

	^ OTLoggerConfig default
]

{ #category : 'private' }
OTLoggerProvider class >> environmentValueAt: aString [

	| configurationSourceClass |
	configurationSourceClass := self configurationSourceClass.
	^ configurationSourceClass ifNotNil: [ configurationSourceClass environmentValueAt: aString ]
]

{ #category : 'private' }
OTLoggerProvider class >> exporterNamed: aString [

	aString = 'console' ifTrue: [ ^ OTConsoleLogRecordExporter new ].
	aString = 'logging' ifTrue: [ ^ OTConsoleLogRecordExporter new ].
	aString = 'none' ifTrue: [ ^ OTNoopLogRecordExporter new ].
	aString = 'otlp' ifTrue: [ ^ self configuredOtlpExporter ].
	aString = 'otlp/stdout' ifTrue: [ ^ OTOtlpStdoutLogRecordExporter new ].
	self noteUnknownExporterName: aString.
	^ nil
]

{ #category : 'private' }
OTLoggerProvider class >> exporterNamesFromConfigurationValue: aString [

	| names seen |
	names := OrderedCollection new.
	seen := Set new.
	(aString substrings: ',') do: [ :each |
			| exporterName normalizedName |
			exporterName := each trimBoth.
			exporterName isEmpty ifFalse: [
					normalizedName := exporterName asLowercase.
					(seen includes: normalizedName) ifFalse: [
							(#( 'otlp' 'otlp/stdout' 'console' 'logging' 'none' ) includes: normalizedName) ifFalse: [
									self noteUnknownExporterName: exporterName.
									^ nil ].
							seen add: normalizedName.
							names add: normalizedName ] ] ].
	names isEmpty ifTrue: [ ^ nil ].
	((names includes: 'none') and: [ names size > 1 ]) ifTrue: [
			self noteExporterNoneConflictIn: aString.
			^ nil ].
	^ names asArray
]

{ #category : 'private' }
OTLoggerProvider class >> nonNegativeIntegerEnvironmentValueAt: aString default: aDefaultValue [

	| rawValue parsed |
	rawValue := self environmentValueAt: aString.
	rawValue ifNil: [ ^ aDefaultValue ].
	parsed := self strictNonNegativeIntegerFrom: rawValue.
	parsed ifNil: [
			self noteInvalidBatchProcessorEnvironmentValue: rawValue forVariable: aString.
			^ aDefaultValue ].
	^ parsed
]

{ #category : 'private' }
OTLoggerProvider class >> normalizedLoggerNameFrom: aValue [

	| loggerName |
	aValue ifNil: [
			self noteInvalidLoggerName: aValue.
			^ '' ].
	loggerName := aValue asString.
	loggerName trimBoth isEmpty ifTrue: [
			self noteInvalidLoggerName: aValue.
			^ '' ].
	^ loggerName
]

{ #category : 'private - logging' }
OTLoggerProvider class >> noteExporterNoneConflictIn: aString [

	self configurationWarningSink value:
		'OpenTelemetry logs exporter configuration mixes ''none'' with other exporters and has been ignored: ' , aString printString
]

{ #category : 'private - logging' }
OTLoggerProvider class >> noteInvalidBatchProcessorEnvironmentValue: aValue forVariable: aString [

	self configurationWarningSink value:
		'OpenTelemetry batch log record processor configuration was invalid and has been ignored for ' , aString printString , ': '
		, aValue printString
]

{ #category : 'private - logging' }
OTLoggerProvider class >> noteInvalidLoggerName: aValue [

	self configurationWarningSink value: 'OpenTelemetry logger name was invalid and has been normalized to an empty string: '
		, (aValue ifNil: [ 'nil' ] ifNotNil: [ aValue printString ])
]

{ #category : 'private - logging' }
OTLoggerProvider class >> noteLogRecordProcessor: aProcessor failedDuring: anOperationName error: anError [

	self configurationWarningSink value:
		'OpenTelemetry log record processor callback failed during ' , anOperationName , ' for ' , aProcessor class name , ': '
		, anError messageText
]

{ #category : 'private - logging' }
OTLoggerProvider class >> noteUnknownExporterName: aString [

	self configurationWarningSink value:
		'OpenTelemetry logs exporter name was unrecognized and has been ignored: ' , aString printString
]

{ #category : 'private - logging' }
OTLoggerProvider class >> noteUnsupportedOtlpProtocol: aString [

	self configurationWarningSink value:
		'OpenTelemetry OTLP logs exporter protocol was unsupported and defaulted to http/protobuf: ' , aString printString
]

{ #category : 'private' }
OTLoggerProvider class >> positiveIntegerEnvironmentValueAt: aString default: aDefaultValue [

	| rawValue parsed |
	rawValue := self environmentValueAt: aString.
	rawValue ifNil: [ ^ aDefaultValue ].
	parsed := self strictPositiveIntegerFrom: rawValue.
	parsed ifNil: [
			self noteInvalidBatchProcessorEnvironmentValue: rawValue forVariable: aString.
			^ aDefaultValue ].
	^ parsed
]

{ #category : 'private' }
OTLoggerProvider class >> processorForExporter: anExporter [

	anExporter class == OTConsoleLogRecordExporter ifTrue: [
			^ OTSimpleLogRecordProcessor new
				  exporter: anExporter;
				  yourself ].
	^ self batchLogRecordProcessorWithExporter: anExporter
]

{ #category : 'instance creation' }
OTLoggerProvider class >> readConfiguration [

	| configurationSourceClass exporterNames processors provider |
	provider := self new.
	configurationSourceClass := self configurationSourceClass.
	provider
		resource: OTTracerProvider configuredResource;
		logRecordLimits: self configuredLogRecordLimits;
		loggerConfigurator: (configurationSourceClass ifNotNil: [ configurationSourceClass configuredLoggerConfigurator ]).
	OTTracerProvider sdkDisabled ifTrue: [ ^ provider ].
	processors := configurationSourceClass ifNotNil: [ configurationSourceClass configuredLogRecordProcessors ].
	processors ifNotNil: [
			provider logRecordProcessors: processors.
			^ provider ].
	exporterNames := self configuredExporterNames.
	exporterNames do: [ :each |
			| exporter |
			exporter := self exporterNamed: each.
			exporter ifNotNil: [
				exporter class = OTNoopLogRecordExporter ifFalse: [ provider addLogRecordProcessor: (self processorForExporter: exporter) ] ] ].
	^ provider
]

{ #category : 'class initialization' }
OTLoggerProvider class >> reset [

	| configurationSourceClass |
	Current ifNotNil: [ Current shutdown ].
	configurationSourceClass := self configurationSourceClass.
	configurationSourceClass ifNotNil: [ configurationSourceClass reset ].
	Current := nil
]

{ #category : 'private' }
OTLoggerProvider class >> strictNonNegativeIntegerFrom: aString [

	| stream value |
	stream := aString trimBoth readStream.
	stream atEnd ifTrue: [ ^ nil ].
	value := [ Integer readFrom: stream ]
		         on: Error
		         do: [ ^ nil ].
	stream atEnd ifFalse: [ ^ nil ].
	value >= 0 ifFalse: [ ^ nil ].
	^ value
]

{ #category : 'private' }
OTLoggerProvider class >> strictPositiveIntegerFrom: aString [

	| stream value |
	stream := aString trimBoth readStream.
	stream atEnd ifTrue: [ ^ nil ].
	value := [ Integer readFrom: stream ]
		         on: Error
		         do: [ ^ nil ].
	stream atEnd ifFalse: [ ^ nil ].
	value > 0 ifFalse: [ ^ nil ].
	^ value
]

{ #category : 'accessing' }
OTLoggerProvider >> addLogRecordProcessor: anOTLogRecordProcessor [

	self ensureOpen.
	self logRecordProcessors add: anOTLogRecordProcessor.
	^ anOTLogRecordProcessor
]

{ #category : 'private' }
OTLoggerProvider >> effectiveContextFrom: anOTContext [

	^ anOTContext ifNil: [ OpenTelemetry currentContext ]
]

{ #category : 'logging' }
OTLoggerProvider >> emitForLogger: anOTLogger timestamp: aTimestamp observedTimestamp: anObservedTimestamp context: anOTContext severityNumber: aSeverityNumber severityText: aSeverityText body: aBody attributes: someAttributes eventName: anEventName exception: anException [

	| config context logRecord |
	self isShutdown ifTrue: [ ^ false ].
	context := self effectiveContextFrom: anOTContext.
	config := self loggerConfigFor: anOTLogger instrumentationScope.
	(self shouldEmitInContext: context severityNumber: aSeverityNumber loggerConfig: config) ifFalse: [ ^ false ].
	(self
		 processorsAllowInContext: context
		 instrumentationScope: anOTLogger instrumentationScope
		 severityNumber: aSeverityNumber
		 eventName: anEventName) ifFalse: [ ^ false ].
	logRecord := self
		             newLogRecordForLogger: anOTLogger
		             timestamp: aTimestamp
		             observedTimestamp: anObservedTimestamp
		             context: context
		             severityNumber: aSeverityNumber
		             severityText: aSeverityText
		             body: aBody
		             attributes: someAttributes
		             eventName: anEventName
		             exception: anException.
	^ self processEmittedLogRecord: logRecord context: context
]

{ #category : 'private' }
OTLoggerProvider >> ensureOpen [

	self isShutdown ifTrue: [ Error signal: 'This logger provider has been shut down' ].
	self
]

{ #category : 'processing' }
OTLoggerProvider >> forceFlush [

	| processors allFlushed |
	processors := self logRecordProcessors.
	processors isEmpty ifTrue: [ ^ false ].
	allFlushed := true.
	processors do: [ :each |
			allFlushed := (self
				               withLogRecordProcessor: each
				               operationNamed: 'forceFlush'
				               default: false
				               do: [ each forceFlush ]) & allFlushed ].
	^ allFlushed
]

{ #category : 'initialization' }
OTLoggerProvider >> initialize [

	super initialize.
	loggers := Dictionary new.
	resource := OTResource empty.
	logRecordProcessors := OrderedCollection new.
	logRecordLimits := OTLogRecordLimits default.
	loggerConfigurator := [ :scope | nil ].
	shutdown := false
]

{ #category : 'testing' }
OTLoggerProvider >> isShutdown [

	^ shutdown = true
]

{ #category : 'accessing' }
OTLoggerProvider >> logRecordLimits [

	^ logRecordLimits copy
]

{ #category : 'accessing' }
OTLoggerProvider >> logRecordLimits: anOTLogRecordLimits [

	self ensureOpen.
	logRecordLimits := (anOTLogRecordLimits ifNil: [ OTLogRecordLimits default ] ifNotNil: [ anOTLogRecordLimits ]) copy.
	^ self logRecordLimits
]

{ #category : 'accessing' }
OTLoggerProvider >> logRecordProcessors [

	^ logRecordProcessors ifNil: [ OrderedCollection new ]
]

{ #category : 'accessing' }
OTLoggerProvider >> logRecordProcessors: aCollection [

	self ensureOpen.
	logRecordProcessors := OrderedCollection new.
	aCollection ifNotNil: [ aCollection do: [ :each | logRecordProcessors add: each ] ].
	^ self logRecordProcessors
]

{ #category : 'private' }
OTLoggerProvider >> loggerConfigFor: anInstrumentationScope [

	| configured |
	configured := [ loggerConfigurator value: anInstrumentationScope ]
		              on: Error
		              do: [ :error |
				              self class configurationWarningSink value:
					              'OpenTelemetry logger configurator failed and default configuration has been used: ' , error messageText.
				              nil ].
	configured ifNil: [ ^ self class defaultLoggerConfig ].
	configured class = OTLoggerConfig ifFalse: [
		Error signal: 'OpenTelemetry logger configurators must return OTLoggerConfig or nil' ].
	^ configured copy
]

{ #category : 'accessing' }
OTLoggerProvider >> loggerConfigurator [

	^ loggerConfigurator
]

{ #category : 'accessing' }
OTLoggerProvider >> loggerConfigurator: aBlock [

	self ensureOpen.
	loggerConfigurator := aBlock ifNil: [ [ :scope | nil ] ] ifNotNil: [ aBlock ].
	^ loggerConfigurator
]

{ #category : 'testing' }
OTLoggerProvider >> loggerEnabled: anOTLogger inContext: anOTContext severityNumber: aSeverityNumber eventName: aString [

	| config context processors |
	context := self effectiveContextFrom: anOTContext.
	processors := self logRecordProcessors.
	processors isEmpty ifTrue: [ ^ false ].
	config := self loggerConfigFor: anOTLogger instrumentationScope.
	(config enabled not or: [ (config allowsSeverityNumber: aSeverityNumber) not or: [ (config allowsContext: context) not ] ])
		ifTrue: [ ^ false ].
	^ self
		  processorsAllowInContext: context
		  instrumentationScope: anOTLogger instrumentationScope
		  severityNumber: aSeverityNumber
		  eventName: aString
]

{ #category : 'logging' }
OTLoggerProvider >> loggerNamed: aString [

	^ self
		  loggerNamed: aString
		  version: ''
		  schemaUrl: ''
		  attributes: #(  )
]

{ #category : 'logging' }
OTLoggerProvider >> loggerNamed: aString version: aVersionString schemaUrl: aSchemaUrlString attributes: aCollection [

	| scope |
	self isShutdown ifTrue: [
			scope := OTInstrumentationScope
				         named: (self class normalizedLoggerNameFrom: aString)
				         version: (aVersionString ifNil: [ '' ] ifNotNil: [ aVersionString asString ])
				         schemaUrl: (aSchemaUrlString ifNil: [ '' ] ifNotNil: [ aSchemaUrlString asString ])
				         attributes: aCollection.
			^ OTLogger forProvider: nil instrumentationScope: scope ].
	scope := OTInstrumentationScope
		         named: (self class normalizedLoggerNameFrom: aString)
		         version: (aVersionString ifNil: [ '' ] ifNotNil: [ aVersionString asString ])
		         schemaUrl: (aSchemaUrlString ifNil: [ '' ] ifNotNil: [ aSchemaUrlString asString ])
		         attributes: aCollection.
	^ loggers at: scope ifAbsentPut: [ OTLogger forProvider: self instrumentationScope: scope ]
]

{ #category : 'private' }
OTLoggerProvider >> mergedExceptionAttributesWith: someAttributes exception: anException [

	| merged |
	merged := OrderedDictionary new.
	anException ifNotNil: [
			merged
				at: 'exception.type' put: anException class name asString;
				at: 'exception.message' put: (anException messageText ifNil: [ anException description ]);
				at: 'exception.stacktrace' put: (([ anException signalerContext ]
						  on: Error
						  do: [ nil ]) ifNil: [ '' ] ifNotNil: [ :aContext | aContext longStack ]) ].
	someAttributes ifNotNil: [
			(someAttributes isDictionary
				 ifTrue: [ someAttributes associations ]
				 ifFalse: [ someAttributes ]) do: [ :each | merged at: each key put: each value ] ].
	^ merged
]

{ #category : 'private' }
OTLoggerProvider >> newLogRecordForLogger: anOTLogger timestamp: aTimestamp observedTimestamp: anObservedTimestamp context: anOTContext severityNumber: aSeverityNumber severityText: aSeverityText body: aBody attributes: someAttributes eventName: anEventName exception: anException [

	| logRecord |
	logRecord := OTLogRecord new.
	logRecord
		resource: self resource;
		instrumentationScope: anOTLogger instrumentationScope;
		limits: self logRecordLimits;
		timestamp: aTimestamp;
		observedTimestamp: anObservedTimestamp;
		context: anOTContext;
		severityNumber: aSeverityNumber;
		severityText: aSeverityText;
		body: aBody;
		attributes: (self mergedExceptionAttributesWith: someAttributes exception: anException);
		eventName: anEventName.
	logRecord observedTimestampIfAbsentSetToNow.
	^ logRecord
]

{ #category : 'private' }
OTLoggerProvider >> processEmittedLogRecord: anOTLogRecord context: anOTContext [

	| processors allProcessed |
	processors := self logRecordProcessors.
	processors isEmpty ifTrue: [ ^ false ].
	allProcessed := true.
	processors do: [ :each |
			allProcessed := (self
				                 withLogRecordProcessor: each
				                 operationNamed: 'onEmit'
				                 default: false
				                 do: [
						                 each onEmit: anOTLogRecord context: anOTContext.
						                 true ]) & allProcessed ].
	^ allProcessed
]

{ #category : 'private' }
OTLoggerProvider >> processorsAllowInContext: anOTContext instrumentationScope: anInstrumentationScope severityNumber: aSeverityNumber eventName: aString [

	| processors |
	processors := self logRecordProcessors.
	processors isEmpty ifTrue: [ ^ false ].
	^ processors anySatisfy: [ :each |
			  self
				  withLogRecordProcessor: each
				  operationNamed: 'enabled'
				  default: true
				  do: [
						  each
							  enabledIn: anOTContext
							  instrumentationScope: anInstrumentationScope
							  severityNumber: aSeverityNumber
							  eventName: aString ] ]
]

{ #category : 'accessing' }
OTLoggerProvider >> resource [

	^ resource ifNil: [ OTResource empty ]
]

{ #category : 'accessing' }
OTLoggerProvider >> resource: anOTResource [

	self ensureOpen.
	resource := anOTResource ifNil: [ OTResource empty ] ifNotNil: [ anOTResource ].
	^ self resource
]

{ #category : 'private' }
OTLoggerProvider >> shouldEmitInContext: anOTContext severityNumber: aSeverityNumber loggerConfig: anOTLoggerConfig [

	^ anOTLoggerConfig enabled and: [
		  (anOTLoggerConfig allowsSeverityNumber: aSeverityNumber) and: [ anOTLoggerConfig allowsContext: anOTContext ] ]
]

{ #category : 'processing' }
OTLoggerProvider >> shutdown [

	| processors allShutdown |
	self isShutdown ifTrue: [ ^ false ].
	processors := self logRecordProcessors.
	allShutdown := true.
	processors do: [ :each |
			allShutdown := (self
				                withLogRecordProcessor: each
				                operationNamed: 'shutdown'
				                default: false
				                do: [ each shutdown ]) & allShutdown ].
	shutdown := true.
	^ allShutdown
]

{ #category : 'private - error handling' }
OTLoggerProvider >> withLogRecordProcessor: anOTLogRecordProcessor operationNamed: anOperationName default: aDefaultValue do: aBlock [

	^ [ aBlock value ]
		  on: Error
		  do: [ :error |
				  self class noteLogRecordProcessor: anOTLogRecordProcessor failedDuring: anOperationName error: error.
				  aDefaultValue ]
]
