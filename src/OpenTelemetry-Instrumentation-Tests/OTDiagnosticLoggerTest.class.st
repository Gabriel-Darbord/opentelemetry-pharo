Class {
	#name : 'OTDiagnosticLoggerTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'private' }
OTDiagnosticLoggerTest >> setEnvironmentValue: aValue forKey: aKey [

	| currentValue environment |
	environment := Smalltalk os environment.
	currentValue := environment at: aKey ifAbsent: [ nil ].
	aValue
		ifNil: [ currentValue ifNotNil: [ environment removeKey: aKey ] ]
		ifNotNil: [ environment at: aKey put: aValue ]
]

{ #category : 'running' }
OTDiagnosticLoggerTest >> tearDown [

	[
		self setEnvironmentValue: nil forKey: 'OTEL_LOG_LEVEL'.
		OTFakeTinyLogger reset.
		OTDiagnosticLogger reset ]
		ensure: [ super tearDown ]
]

{ #category : 'tests' }
OTDiagnosticLoggerTest >> testBuildDefaultLoggerUsesConfigurableTinyLoggerResolver [

	| logger tinyLogger |
	OTDiagnosticLogger tinyLoggerClassResolver: [ OTFakeTinyLogger ].
	logger := OTDiagnosticLogger buildDefaultLogger.
	logger warning: 'resolver warning'.
	tinyLogger := OTFakeTinyLogger lastInstance.
	self assert: tinyLogger notNil.
	self assert: tinyLogger ensureStdoutLoggerCount equals: 1.
	self
		assert: tinyLogger recordedMessages asArray
		equals: #( 'OpenTelemetry warning: resolver warning' )
]

{ #category : 'tests' }
OTDiagnosticLoggerTest >> testConfiguredMinimumSeverityDefaultsToInfo [

	self setEnvironmentValue: nil forKey: 'OTEL_LOG_LEVEL'.
	self assert: OTDiagnosticLogger configuredMinimumSeverity equals: OTDiagnosticLogger infoSeverity
]

{ #category : 'tests' }
OTDiagnosticLoggerTest >> testConfiguredMinimumSeverityReadsEnvironmentCaseInsensitively [

	self setEnvironmentValue: 'debug' forKey: 'OTEL_LOG_LEVEL'.
	self assert: OTDiagnosticLogger configuredMinimumSeverity equals: OTDiagnosticLogger debugSeverity
]

{ #category : 'tests' }
OTDiagnosticLoggerTest >> testExporterDefaultWarningSinkUsesCurrentDiagnosticLogger [

	| warnings |
	warnings := OrderedCollection new.
	OTDiagnosticLogger current:
		(OTDiagnosticLogger onWarningDo: [ :message | warnings add: message ]).

	OTSpanExporter defaultWarningSink value: 'exporter warning'.

	self
		assert: warnings asArray
		equals: #( 'exporter warning' )
]

{ #category : 'tests' }
OTDiagnosticLoggerTest >> testLoggerFactoryOverridesDefaultBackendSelection [

	| warnings |
	warnings := OrderedCollection new.
	OTDiagnosticLogger loggerFactory: [
		(OTDiagnosticLogger onWarningDo: [ :message | warnings add: message ])
			minimumSeverity: OTDiagnosticLogger warningSeverity;
			yourself ].
	OTDiagnosticLogger current warning: 'factory warning'.
	self assert: warnings asArray equals: #( 'factory warning' )
]

{ #category : 'tests' }
OTDiagnosticLoggerTest >> testHandleSuppressedErrorUsesCustomErrorHandler [

	| handled logger |
	handled := OrderedCollection new.
	logger := OTDiagnosticLogger new.
	logger errorHandler: [ :error :message |
		handled add: { error messageText. message } ].

	logger
		handleSuppressedError: (Error new messageText: 'boom'; yourself)
		message: 'suppressed failure'
		fallback: [ self fail ].

	self
		assert: handled asArray
		equals: { { 'boom'. 'suppressed failure' } }
]

{ #category : 'tests' }
OTDiagnosticLoggerTest >> testInstrumentationDefaultWarningSinkUsesCurrentDiagnosticLogger [

	| warnings |
	warnings := OrderedCollection new.
	OTDiagnosticLogger current:
		(OTDiagnosticLogger onWarningDo: [ :message | warnings add: message ]).

	OTTracerProvider defaultSamplerConfigurationWarningSink value: 'sampler warning'.
	OTSpan defaultLimitWarningSink value: 'limit warning'.

	self
		assert: warnings asArray
		equals: #( 'sampler warning' 'limit warning' )
]

{ #category : 'tests' }
OTDiagnosticLoggerTest >> testMinimumSeverityFiltersMessages [

	| logger recorded |
	recorded := OrderedCollection new.
	logger := OTDiagnosticLogger onMessageDo: [ :severity :message |
		recorded add: { severity. message } ].
	logger minimumSeverity: OTDiagnosticLogger errorSeverity.

	logger warning: 'warning'.
	logger error: 'error'.

	self
		assert: recorded asArray
		equals: { { OTDiagnosticLogger errorSeverity. 'error' } }
]
