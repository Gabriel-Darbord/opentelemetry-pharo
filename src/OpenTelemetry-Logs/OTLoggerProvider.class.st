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
OTLoggerProvider class >> configuredExporterNames [

	| rawValue |
	rawValue := self environmentValueAt: 'OTEL_LOGS_EXPORTER'.
	rawValue ifNil: [ ^ #( 'otlp' ) ].
	^ (self exporterNamesFromConfigurationValue: rawValue)
		ifNil: [ #( 'otlp' ) ]
		ifNotNil: [ :names | names ]
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
		attributeCountLimit: (OTTracerProvider
			nonNegativeIntegerEnvironmentValueAt: 'OTEL_LOGRECORD_ATTRIBUTE_COUNT_LIMIT'
			default: generalAttributeCountLimit);
		attributeValueLengthLimit: (OTTracerProvider
			nonNegativeIntegerEnvironmentValueAt: 'OTEL_LOGRECORD_ATTRIBUTE_VALUE_LENGTH_LIMIT'
			default: generalValueLengthLimit).
	^ limits
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

	| value |
	value := Smalltalk os environment at: aString ifAbsent: [ ^ nil ].
	value := value asString trimBoth.
	^ value isEmpty ifTrue: [ nil ] ifFalse: [ value ]
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
				(#( 'otlp' 'console' 'none' ) includes: normalizedName)
					ifFalse: [
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
OTLoggerProvider class >> exporterNamed: aString [

	aString = 'console' ifTrue: [ ^ OTConsoleLogRecordExporter new ].
	aString = 'none' ifTrue: [ ^ OTNoopLogRecordExporter new ].
	aString = 'otlp' ifTrue: [
		self noteUnsupportedExporterName: aString.
		^ nil ].
	self noteUnknownExporterName: aString.
	^ nil
]

{ #category : 'private - logging' }
OTLoggerProvider class >> noteExporterNoneConflictIn: aString [

	self configurationWarningSink value:
		'OpenTelemetry logs exporter configuration mixes ''none'' with other exporters and has been ignored: '
			, aString printString
]

{ #category : 'private - logging' }
OTLoggerProvider class >> noteInvalidLoggerName: aValue [

	self configurationWarningSink value:
		'OpenTelemetry logger name was invalid and has been normalized to an empty string: '
			, (aValue ifNil: [ 'nil' ] ifNotNil: [ aValue printString ])
]

{ #category : 'private - logging' }
OTLoggerProvider class >> noteLogRecordProcessor: aProcessor failedDuring: anOperationName error: anError [

	self configurationWarningSink value:
		'OpenTelemetry log record processor callback failed during '
			, anOperationName
			, ' for '
			, aProcessor class name
			, ': '
			, anError messageText
]

{ #category : 'private - logging' }
OTLoggerProvider class >> noteUnknownExporterName: aString [

	self configurationWarningSink value:
		'OpenTelemetry logs exporter name was unrecognized and has been ignored: '
			, aString printString
]

{ #category : 'private - logging' }
OTLoggerProvider class >> noteUnsupportedExporterName: aString [

	self configurationWarningSink value:
		'OpenTelemetry logs exporter is not implemented yet and has been ignored: '
			, aString printString
]

{ #category : 'private' }
OTLoggerProvider class >> normalizedLoggerNameFrom: aValue [

	| name |
	aValue ifNil: [
		self noteInvalidLoggerName: aValue.
		^ '' ].
	name := aValue asString.
	name trimBoth isEmpty ifTrue: [
		self noteInvalidLoggerName: aValue.
		^ '' ].
	^ name
]

{ #category : 'instance creation' }
OTLoggerProvider class >> readConfiguration [

	| exporterNames provider |
	provider := self new.
	provider
		resource: OTTracerProvider configuredResource;
		logRecordLimits: self configuredLogRecordLimits.
	OTTracerProvider sdkDisabled ifTrue: [ ^ provider ].
	exporterNames := self configuredExporterNames.
	exporterNames do: [ :each |
		| exporter |
		exporter := self exporterNamed: each.
		exporter ifNotNil: [
			exporter class = OTNoopLogRecordExporter ifFalse: [
				provider addLogRecordProcessor: (OTSimpleLogRecordProcessor new exporter: exporter; yourself) ] ] ].
	^ provider
]

{ #category : 'class initialization' }
OTLoggerProvider class >> reset [

	Current ifNotNil: [ Current shutdown ].
	Current := nil
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
		ifNil: [
			OTClassStateStore
				removeValueAt: #otLoggerProviderConfigurationWarningSink
				forClass: self
				ifAbsent: [  ] ]
		ifNotNil: [
			OTClassStateStore
				valueAt: #otLoggerProviderConfigurationWarningSink
				forClass: self
				put: aBlock ].
	^ self configurationWarningSink
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

{ #category : 'private' }
OTLoggerProvider >> ensureOpen [

	self isShutdown ifTrue: [ Error signal: 'This logger provider has been shut down' ].
	self
]

{ #category : 'logging' }
OTLoggerProvider >> emitForLogger: anOTLogger timestamp: aTimestamp observedTimestamp: anObservedTimestamp context: anOTContext severityNumber: aSeverityNumber severityText: aSeverityText body: aBody attributes: someAttributes eventName: anEventName exception: anException [

	| config context logRecord |
	self isShutdown ifTrue: [ ^ false ].
	context := self effectiveContextFrom: anOTContext.
	config := self loggerConfigFor: anOTLogger instrumentationScope.
	(self shouldEmitInContext: context severityNumber: aSeverityNumber loggerConfig: config) ifFalse: [ ^ false ].
	(self processorsAllowInContext: context instrumentationScope: anOTLogger instrumentationScope severityNumber: aSeverityNumber eventName: anEventName)
		ifFalse: [ ^ false ].
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

{ #category : 'private' }
OTLoggerProvider >> loggerConfigFor: anInstrumentationScope [

	| configured |
	configured := [ loggerConfigurator value: anInstrumentationScope ]
		on: Error
		do: [ :error |
			self class configurationWarningSink value:
				'OpenTelemetry logger configurator failed and default configuration has been used: '
					, error messageText.
			nil ].
	configured ifNil: [ ^ self class defaultLoggerConfig ].
	configured class = OTLoggerConfig ifFalse: [
		Error signal: 'OpenTelemetry logger configurators must return OTLoggerConfig or nil' ].
	^ configured copy
]

{ #category : 'testing' }
OTLoggerProvider >> loggerEnabled: anOTLogger inContext: anOTContext severityNumber: aSeverityNumber eventName: aString [

	| config context processors |
	context := self effectiveContextFrom: anOTContext.
	processors := self logRecordProcessors.
	processors isEmpty ifTrue: [ ^ false ].
	config := self loggerConfigFor: anOTLogger instrumentationScope.
	(config enabled not
		or: [ (config allowsSeverityNumber: aSeverityNumber) not
		or: [ (config allowsContext: context) not ] ]) ifTrue: [ ^ false ].
	^ self processorsAllowInContext: context instrumentationScope: anOTLogger instrumentationScope severityNumber: aSeverityNumber eventName: aString
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

{ #category : 'logging' }
OTLoggerProvider >> loggerNamed: aString [

	^ self loggerNamed: aString version: '' schemaUrl: '' attributes: #()
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
	^ loggers
		at: scope
		ifAbsentPut: [ OTLogger forProvider: self instrumentationScope: scope ]
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
OTLoggerProvider >> mergedExceptionAttributesWith: someAttributes exception: anException [

	| merged |
	merged := OrderedDictionary new.
	anException ifNotNil: [
		merged
			at: 'exception.type' put: anException class name asString;
			at: 'exception.message' put: (anException messageText ifNil: [ anException description ]);
			at: 'exception.stacktrace' put: (([ anException signalerContext ]
				on: Error
				do: [ nil ])
					ifNil: [ '' ]
					ifNotNil: [ :aContext | aContext longStack ]) ].
	someAttributes ifNotNil: [
		(someAttributes isDictionary
			ifTrue: [ someAttributes associations ]
			ifFalse: [ someAttributes ]) do: [ :each |
				merged at: each key put: each value ] ].
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
			do: [ each onEmit: anOTLogRecord context: anOTContext.
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

	^ anOTLoggerConfig enabled
		and: [ (anOTLoggerConfig allowsSeverityNumber: aSeverityNumber)
		and: [ anOTLoggerConfig allowsContext: anOTContext ] ]
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
