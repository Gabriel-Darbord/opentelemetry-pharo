Class {
	#name : 'OTLoggerProviderTest',
	#superclass : 'TestCase',
	#instVars : [
		'provider',
		'exporter',
		'processor'
	],
	#category : 'OpenTelemetry-Logs-Tests',
	#package : 'OpenTelemetry-Logs-Tests'
}

{ #category : 'running' }
OTLoggerProviderTest >> setUp [

	super setUp.
	provider := OTLoggerProvider new.
	exporter := OTRecordingLogRecordExporter new.
	processor := OTSimpleLogRecordProcessor new
		             exporter: exporter;
		             yourself.
	OpenTelemetry loggerProvider: provider.
	OpenTelemetry resetCurrentContext
]

{ #category : 'running' }
OTLoggerProviderTest >> tearDown [

	[
		OpenTelemetry loggerProvider: nil.
		OpenTelemetry resetCurrentContext.
		provider ifNotNil: [ provider shutdown ] ] ensure: [ super tearDown ]
]

{ #category : 'tests' }
OTLoggerProviderTest >> testConcurrentLoggerCreationReturnsIdenticalLogger [

	| done gate lock results workerCount |
	results := OrderedCollection new.
	lock := Semaphore forMutualExclusion.
	gate := Semaphore new.
	done := Semaphore new.
	workerCount := 8.
	workerCount timesRepeat: [
			[
				gate wait.
				lock critical: [ results add: (provider loggerNamed: 'spec.logs') ].
				done signal ] forkAt: Processor userBackgroundPriority ].
	workerCount timesRepeat: [ gate signal ].
	workerCount timesRepeat: [ self assert: (done waitTimeoutMilliseconds: 1000) not ].
	self assert: results notEmpty.
	self assert: results asSet size equals: 1.
	self assert: results first class identicalTo: OTLogger
]

{ #category : 'tests' }
OTLoggerProviderTest >> testConcurrentShutdownReturnsTrueOnce [

	| done gate lock results workerCount |
	provider addLogRecordProcessor: processor.
	results := OrderedCollection new.
	lock := Semaphore forMutualExclusion.
	gate := Semaphore new.
	done := Semaphore new.
	workerCount := 8.
	workerCount timesRepeat: [
			[
				gate wait.
				lock critical: [ results add: provider shutdown ].
				done signal ] forkAt: Processor userBackgroundPriority ].
	workerCount timesRepeat: [ gate signal ].
	workerCount timesRepeat: [ self assert: (done waitTimeoutMilliseconds: 1000) not ].
	self assert: (results count: [ :each | each = true ]) equals: 1.
	self assert: (results count: [ :each | each = false ]) equals: workerCount - 1.
	self assert: provider isShutdown.
	self assert: exporter shutdownCount equals: 1
]

{ #category : 'tests' }
OTLoggerProviderTest >> testEmitAddsExceptionAttributesWithoutOverwritingUserAttributes [

	| logger |
	provider addLogRecordProcessor: processor.
	logger := provider loggerNamed: 'spec.logs'.
	logger
		emitTimestamp: nil
		observedTimestamp: nil
		in: nil
		severityNumber: OTSeverity error
		severityText: 'ERROR'
		body: 'boom'
		attributes: {
				('exception.message' -> 'user message').
				('custom' -> 42) }
		eventName: 'exception'
		exception: (Error new
				 messageText: 'actual message';
				 yourself).
	self assert: exporter exportedRecords size equals: 1.
	self assert: (exporter exportedRecords first attributeNamed: 'exception.message') equals: 'user message'.
	self assert: (exporter exportedRecords first attributeNamed: 'custom') equals: 42.
	self assert: (exporter exportedRecords first attributeNamed: 'exception.type') equals: 'Error'
]

{ #category : 'tests' }
OTLoggerProviderTest >> testEmitPopulatesObservedTimestampAndTraceContextFromCurrentContext [

	| context logger spanContext |
	provider addLogRecordProcessor: processor.
	spanContext := OTSpanContext
		               traceId: '0123456789abcdef0123456789abcdef'
		               spanId: '0123456789abcdef'
		               traceFlags: '01'
		               traceState: nil
		               remote: false.
	context := OTContext new withSpan: spanContext asNonRecordingSpan.
	OpenTelemetry currentContext: context.
	logger := provider loggerNamed: 'spec.logs'.
	self assert: (logger emitBody: 'hello').
	self assert: exporter exportedRecords size equals: 1.
	self assert: exporter exportedRecords first observedTimestamp notNil.
	self assert: exporter exportedRecords first traceId equals: spanContext traceId.
	self assert: exporter exportedRecords first spanId equals: spanContext spanId.
	self assert: exporter exportedRecords first traceFlags equals: spanContext traceFlags
]

{ #category : 'tests' }
OTLoggerProviderTest >> testExistingLoggerSeesUpdatedConfigurator [

	| config logger |
	logger := provider loggerNamed: 'spec.logs'.
	self deny: logger enabled.
	provider addLogRecordProcessor: processor.
	self assert: logger enabled.
	config := OTLoggerConfig default.
	config enabled: false.
	provider loggerConfigurator: [ :scope | config ].
	self deny: logger enabled
]

{ #category : 'tests' }
OTLoggerProviderTest >> testForceFlushReturnsFalseAfterShutdown [

	self assert: provider shutdown.
	self deny: provider forceFlush
]

{ #category : 'tests' }
OTLoggerProviderTest >> testForceFlushSucceedsWithoutProcessors [

	self assert: provider forceFlush
]

{ #category : 'tests' }
OTLoggerProviderTest >> testLoggerEnabledIsFalseWithoutProcessors [

	| logger |
	logger := provider loggerNamed: 'spec.logs'.
	self deny: logger enabled.
	self deny: (logger emitBody: 'hello')
]

{ #category : 'tests' }
OTLoggerProviderTest >> testNoopProviderReturnsDisabledNoopLogger [

	| logger noopProvider |
	noopProvider := OTNoopLoggerProvider new.
	logger := noopProvider loggerNamed: 'spec.logs'.
	self assert: logger class identicalTo: OTNoopLogger.
	self deny: logger enabled.
	self deny: (logger emitBody: 'hello')
]

{ #category : 'tests' }
OTLoggerProviderTest >> testNoopTypesDoNotDeclareInstanceState [

	self assert: OTNoopLogger allInstVarNames isEmpty.
	self assert: OTNoopLoggerProvider allInstVarNames isEmpty
]

{ #category : 'tests' }
OTLoggerProviderTest >> testMinimumSeverityFilteringDropsBelowThreshold [

	| config logger |
	provider addLogRecordProcessor: processor.
	config := OTLoggerConfig default.
	config minimumSeverity: OTSeverity error.
	provider loggerConfigurator: [ :scope | config ].
	logger := provider loggerNamed: 'spec.logs'.
	self deny: (logger enabledIn: nil severityNumber: OTSeverity warn eventName: nil).
	self assert: (logger enabledIn: nil severityNumber: OTSeverity error eventName: nil).
	self deny: (logger
			 emitTimestamp: nil
			 observedTimestamp: nil
			 in: nil
			 severityNumber: OTSeverity warn
			 severityText: 'WARN'
			 body: 'skip'
			 attributes: #(  )
			 eventName: nil
			 exception: nil).
	self assert: exporter exportedRecords isEmpty
]

{ #category : 'tests' }
OTLoggerProviderTest >> testShutdownReturnsNoopLogger [

	| logger |
	provider addLogRecordProcessor: processor.
	self assert: provider shutdown.
	logger := provider loggerNamed: 'spec.logs'.
	self assert: logger class identicalTo: OTNoopLogger.
	self deny: logger enabled.
	self deny: (logger emitBody: 'after shutdown')
]

{ #category : 'tests' }
OTLoggerProviderTest >> testTraceBasedFilteringDropsUnsampledTrace [

	| config context logger spanContext |
	provider addLogRecordProcessor: processor.
	config := OTLoggerConfig default.
	config traceBased: true.
	provider loggerConfigurator: [ :scope | config ].
	spanContext := OTSpanContext
		               traceId: '0123456789abcdef0123456789abcdef'
		               spanId: '0123456789abcdef'
		               traceFlags: '00'
		               traceState: nil
		               remote: false.
	context := OTContext new withSpan: spanContext asNonRecordingSpan.
	logger := provider loggerNamed: 'spec.logs'.
	self deny: (logger enabledIn: context severityNumber: OTSeverity info eventName: nil).
	self deny: (logger
			 emitTimestamp: nil
			 observedTimestamp: nil
			 in: context
			 severityNumber: OTSeverity info
			 severityText: 'INFO'
			 body: 'skip'
			 attributes: #(  )
			 eventName: nil
			 exception: nil).
	self assert: exporter exportedRecords isEmpty
]
