Class {
	#name : 'OTTracerProviderTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'private' }
OTTracerProviderTest >> sampleAttributes [

	^ OrderedDictionary new
		at: 'scope.answer' put: 42;
		yourself
]

{ #category : 'private' }
OTTracerProviderTest >> setEnvironmentValue: aValue forKey: aKey [

	| currentValue environment |
	environment := Smalltalk os environment.
	currentValue := environment at: aKey ifAbsent: [ nil ].
	aValue
		ifNil: [ currentValue ifNotNil: [ environment removeKey: aKey ] ]
		ifNotNil: [ environment at: aKey put: aValue ]
]

{ #category : 'running' }
OTTracerProviderTest >> setUp [

	super setUp.
	OTTracerProvider current: nil.
	OTSpanProcessor current: nil.
	OTSpanExporter current: nil.
	OTSpan reset
]

{ #category : 'running' }
OTTracerProviderTest >> tearDown [

	[
		OTDiagnosticLogger reset.
		OTTracerProvider current: nil.
		OTTracerProvider tracerConfigurationWarningSink: nil.
		OTTracerProvider resourceConfigurationWarningSink: nil.
		OTTracerProvider resourceDetectors: nil.
		OTTracerProvider spanProcessorWarningSink: nil.
		OTTracerProvider tracerNameWarningSink: nil.
		OTSpanProcessor current: nil.
		OTSpanExporter current: nil.
		OTSpan reset ]
		ensure: [ super tearDown ]
]

{ #category : 'private' }
OTTracerProviderTest >> withTracerConfigurationWarningsDo: aBlock [

	| warnings |
	warnings := OrderedCollection new.
	OTTracerProvider tracerConfigurationWarningSink: [ :message | warnings add: message ].
	[
		^ aBlock value: warnings ]
		ensure: [ OTTracerProvider tracerConfigurationWarningSink: nil ]
]

{ #category : 'private' }
OTTracerProviderTest >> withTracerNameWarningsDo: aBlock [

	| warnings |
	warnings := OrderedCollection new.
	OTTracerProvider tracerNameWarningSink: [ :message | warnings add: message ].
	[
		^ aBlock value: warnings ]
		ensure: [ OTTracerProvider tracerNameWarningSink: nil ]
]

{ #category : 'private' }
OTTracerProviderTest >> withSpanProcessorWarningsDo: aBlock [

	| warnings |
	warnings := OrderedCollection new.
	OTTracerProvider spanProcessorWarningSink: [ :message | warnings add: message ].
	[
		^ aBlock value: warnings ]
		ensure: [ OTTracerProvider spanProcessorWarningSink: nil ]
]

{ #category : 'private' }
OTTracerProviderTest >> withResourceConfigurationWarningsDo: aBlock [

	| warnings |
	warnings := OrderedCollection new.
	OTTracerProvider resourceConfigurationWarningSink: [ :message | warnings add: message ].
	[
		^ aBlock value: warnings ]
		ensure: [ OTTracerProvider resourceConfigurationWarningSink: nil ]
]

{ #category : 'private' }
OTTracerProviderTest >> withEnvironmentValues: aDictionary during: aBlock [

	| absent effectiveValues environment managedKeys snapshot |
	absent := Object new.
	environment := Smalltalk os environment.
	effectiveValues := aDictionary copy.
	managedKeys := (environment keys
		select: [ :each | each beginsWith: 'OTEL_' ])
		asOrderedCollection.
	effectiveValues keysDo: [ :each |
		(managedKeys includes: each) ifFalse: [ managedKeys add: each ] ].
	snapshot := Dictionary new.
	managedKeys do: [ :key |
		| value |
		value := effectiveValues at: key ifAbsent: [ nil ].
		snapshot at: key put: (environment at: key ifAbsent: [ absent ]).
		self setEnvironmentValue: value forKey: key ].
	[
		^ aBlock value ]
		ensure: [
			managedKeys do: [ :key |
				| value |
				value := snapshot at: key.
				self
					setEnvironmentValue: (value == absent ifTrue: [ nil ] ifFalse: [ value ])
					forKey: key ] ]
]

{ #category : 'tests' }
OTTracerProviderTest >> testRecordingSpanInheritsProviderResourceAndScope [

	| provider tracer span resource |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	resource := OTResource attributes: (OrderedDictionary new
		at: 'service.name' put: 'spec-service';
		yourself).
	provider resource: resource.
	tracer := provider
		tracerNamed: 'demo.scope'
		version: '1.2.3'
		schemaUrl: 'https://opentelemetry.io/schemas/1.0.0'
		attributes: self sampleAttributes.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	self assert: span resource equals: resource.
	self assert: span instrumentationScope name equals: 'demo.scope'.
	self assert: span instrumentationScope version equals: '1.2.3'.
	self assert: span instrumentationScope schemaUrl equals: 'https://opentelemetry.io/schemas/1.0.0'.
	self assert: (span instrumentationScope attributeAt: 'scope.answer') equals: 42
]

{ #category : 'tests' }
OTTracerProviderTest >> testCustomIdGeneratorControlsNonRecordingSpanIds [

	| generator provider span tracer |
	provider := OTTracerProvider new.
	provider
		spanProcessor: OTSimpleSpanProcessor new;
		sampler: OTAlwaysOffSampler new;
		idGenerator: (generator := OTFixedIdGenerator
			traceIdHex: '00112233445566778899aabbccddeeff'
			spanIdHex: '1122334455667788'
			random: false).
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	self assert: span class identicalTo: OTNonRecordingSpan.
	self assert: span traceId equals: generator generateTraceIdHex.
	self assert: span spanId equals: generator generateSpanIdHex.
	self assert: span spanContext traceFlags equals: '00'
]

{ #category : 'tests' }
OTTracerProviderTest >> testCustomTracerProviderCanCustomizeRecordingAndNonRecordingSpanClasses [

	| provider recordedSpan sampledOffSpan tracer |
	provider := OTCustomTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	recordedSpan := (tracer spanBuilderNamed: 'recorded') startSpan.
	provider sampler: OTAlwaysOffSampler new.
	sampledOffSpan := (tracer spanBuilderNamed: 'dropped') startSpan.
	self assert: recordedSpan class identicalTo: OTCustomRecordingSpan.
	self assert: sampledOffSpan class identicalTo: OTCustomNonRecordingSpan
]

{ #category : 'tests' }
OTTracerProviderTest >> testCustomTracerProviderCanCustomizeTracerClass [

	| firstTracer provider secondTracer |
	provider := OTCustomTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	firstTracer := provider tracerNamed: 'demo.scope'.
	secondTracer := provider tracerNamed: 'demo.scope'.
	self assert: firstTracer class identicalTo: OTCustomTracer.
	self assert: secondTracer identicalTo: firstTracer
]

{ #category : 'tests' }
OTTracerProviderTest >> testSpanProcessorFailureInvokesDiagnosticErrorHandler [

	| handled provider |
	handled := OrderedCollection new.
	OTDiagnosticLogger current: (OTDiagnosticLogger new
		errorHandler: [ :error :message | handled add: { error messageText. message } ];
		yourself).
	provider := OTTracerProvider new.
	provider addSpanProcessor: (OTFailingSpanProcessor failingOperations: { 'onStart' }).

	provider processStartedSpan: (OTSpan rootIn: OTContext new) parentContext: OTContext new.

	self
		assert: handled asArray
		equals: {
			{ 'processor failure'. 'OpenTelemetry span processor callback failed during onStart for OTFailingSpanProcessor: processor failure' } }
]

{ #category : 'tests' }
OTTracerProviderTest >> testCustomIdGeneratorControlsRootTraceAndSpanIds [

	| generator provider span tracer |
	provider := OTTracerProvider new.
	provider
		spanProcessor: OTSimpleSpanProcessor new;
		idGenerator: (generator := OTFixedIdGenerator
			traceIdHex: '00112233445566778899aabbccddeeff'
			spanIdHex: '1122334455667788'
			random: false).
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	self assert: span traceId equals: generator generateTraceIdHex.
	self assert: span spanId equals: generator generateSpanIdHex.
	self assert: span spanContext traceFlags equals: '01'.
	self deny: span spanContext isRandom
]

{ #category : 'tests' }
OTTracerProviderTest >> testCurrentRebuildsAfterGlobalSpanExporterChange [

	self
		withEnvironmentValues: Dictionary new
		during: [
			| exporter firstProvider secondProvider |
			OTSpanExporter current: OTNoopSpanExporter new.
			firstProvider := OTTracerProvider current.
			self assert: firstProvider spanProcessors isEmpty.
			exporter := OTConsoleSpanExporter new.
			exporter beCurrent.
			secondProvider := OTTracerProvider current.
			self deny: secondProvider identicalTo: firstProvider.
			self assert: secondProvider spanProcessors size equals: 1.
			self assert: secondProvider spanProcessors first exporter identicalTo: exporter ]
]

{ #category : 'tests' }
OTTracerProviderTest >> testCurrentUsesExplicitGlobalSpanProcessorEvenAfterNoopExporterProviderWasBuilt [

	self
		withEnvironmentValues: Dictionary new
		during: [
			| firstProvider processor secondProvider |
			OTSpanExporter current: OTNoopSpanExporter new.
			firstProvider := OTTracerProvider current.
			self assert: firstProvider spanProcessors isEmpty.
			processor := OTSimpleSpanProcessor new
				exporter: OTConsoleSpanExporter new;
				yourself.
			processor beCurrent.
			secondProvider := OTTracerProvider current.
			self deny: secondProvider identicalTo: firstProvider.
			self assert: secondProvider spanProcessors asArray equals: { processor } ]
]

{ #category : 'tests' }
OTTracerProviderTest >> testExistingTracerPicksUpLaterDisablementWithoutReacquiring [

	| disabledSpan provider tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	self assert: tracer enabled.
	provider tracerConfigurator: [ :scope | false ].
	self deny: tracer enabled.
	disabledSpan := (tracer spanBuilderNamed: 'operation') startSpan.
	self assert: disabledSpan class identicalTo: OTNonRecordingSpan.
	self deny: disabledSpan spanContext isValid
]

{ #category : 'tests' }
OTTracerProviderTest >> testExistingScopeOnlyTracerConfiguratorStillDisablesTracer [

	| provider tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	provider tracerConfigurator: [ :scope | false ].
	self deny: tracer enabled
]

{ #category : 'tests' }
OTTracerProviderTest >> testDisabledTracerPreservesParentSpanContext [

	| disabledSpan parentSpan provider tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	parentSpan := (tracer spanBuilderNamed: 'parent') startSpan.
	provider tracerConfigurator: [ :scope | false ].
	disabledSpan := ((tracer spanBuilderNamed: 'child')
		inContext: (parentSpan inContext: OTContext new);
		startSpan).
	self assert: disabledSpan class identicalTo: OTNonRecordingSpan.
	self deny: disabledSpan identicalTo: parentSpan.
	self assert: disabledSpan traceId equals: parentSpan traceId.
	self assert: disabledSpan spanId equals: parentSpan spanId.
	self assert: disabledSpan traceFlags equals: parentSpan traceFlags.
	self assert: disabledSpan traceState equals: parentSpan traceState
]

{ #category : 'tests' }
OTTracerProviderTest >> testFailingTracerConfiguratorFallsBackToEnabledAndLogsWarning [

	self
		withTracerConfigurationWarningsDo: [ :warnings |
			| provider tracer |
			provider := OTTracerProvider new.
			provider spanProcessor: OTSimpleSpanProcessor new.
			tracer := provider tracerNamed: 'demo.scope'.
			provider tracerConfigurator: [ :scope | Error signal: 'boom' ].
			self assert: tracer enabled.
			self assert: warnings asArray equals:
				{ 'OpenTelemetry tracer configuration callback failed during enabled: boom' } ]
]

{ #category : 'tests' }
OTTracerProviderTest >> testTracerConfiguratorCanUseSpanCreationArgumentsToDisableSpecificSpanNames [

	| blockedSpan provider tracer unblockedSpan |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	provider tracerConfigurator: [ :scope :spanName :kind :context :attributes :links |
		spanName = 'blocked' ifTrue: [ false ] ifFalse: [ nil ] ].
	blockedSpan := (tracer spanBuilderNamed: 'blocked') startSpan.
	unblockedSpan := (tracer spanBuilderNamed: 'allowed') startSpan.
	self assert: blockedSpan class identicalTo: OTNonRecordingSpan.
	self deny: blockedSpan spanContext isValid.
	self assert: unblockedSpan isRecording
]

{ #category : 'tests' }
OTTracerProviderTest >> testExistingTracerPicksUpLaterResourceChangesForNewSpans [

	| provider resource span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	resource := OTResource attributes: (OrderedDictionary new
		at: 'service.name' put: 'updated-service';
		at: 'deployment.environment.name' put: 'staging';
		yourself).
	provider resource: resource.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	self assert: span resource equals: resource.
	self assert: (span resource attributeAt: 'deployment.environment.name') equals: 'staging'
]

{ #category : 'tests' }
OTTracerProviderTest >> testInstrumenterEndNotifiesSpanProcessorOnlyOnce [

	| instrumenter processor provider span |
	provider := OTTracerProvider new.
	processor := OTRecordingSpanProcessor new.
	provider spanProcessor: processor.
	OTTracerProvider current: provider.
	instrumenter := OTInstrumenter forInstrumentationNamed: 'demo.scope'.
	span := instrumenter startRequest: 'request'.
	instrumenter end: span.
	self assert: processor endingSpans asArray equals: { span }.
	self assert: processor endedSpans asArray equals: { span }
]

{ #category : 'tests' }
OTTracerProviderTest >> testCustomTracerProviderWrapsNoopSpanContextsWithCustomSpanClass [

	| parentSpan provider returnedSpan tracer |
	provider := OTCustomTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	parentSpan := (tracer spanBuilderNamed: 'parent') startSpan.
	provider tracerConfigurator: [ :scope | false ].
	returnedSpan := ((tracer spanBuilderNamed: 'operation')
		inContext: (OTContext new withSpan: parentSpan);
		startSpan).
	self assert: returnedSpan class identicalTo: OTCustomNonRecordingSpan.
	self assert: returnedSpan traceId equals: parentSpan traceId.
	self assert: returnedSpan spanId equals: parentSpan spanId
]

{ #category : 'tests' }
OTTracerProviderTest >> testInstrumenterUsesInjectedTracerProvider [

	| instrumenter processor provider span |
	provider := OTTracerProvider new.
	processor := OTRecordingSpanProcessor new.
	provider spanProcessor: processor.
	instrumenter := OTInstrumenter forInstrumentationNamed: 'demo.scope'.
	instrumenter tracerProvider: provider.
	span := instrumenter startRequest: 'request'.
	instrumenter end: span.
	self assert: processor startedSpans asArray equals: { span }.
	self assert: processor endingSpans asArray equals: { span }.
	self assert: processor endedSpans asArray equals: { span }
]

{ #category : 'tests' }
OTTracerProviderTest >> testInstrumenterIgnoresGlobalCurrentWhenTracerProviderIsInjected [

	| globalProcessor globalProvider injectedProcessor injectedProvider instrumenter span |
	injectedProvider := OTTracerProvider new.
	injectedProcessor := OTRecordingSpanProcessor new.
	injectedProvider spanProcessor: injectedProcessor.
	globalProvider := OTTracerProvider new.
	globalProcessor := OTRecordingSpanProcessor new.
	globalProvider spanProcessor: globalProcessor.
	OTTracerProvider current: globalProvider.
	instrumenter := OTInstrumenter forInstrumentationNamed: 'demo.scope'.
	instrumenter tracerProvider: injectedProvider.
	span := instrumenter startRequest: 'request'.
	instrumenter end: span.
	self assert: injectedProcessor startedSpans asArray equals: { span }.
	self assert: injectedProcessor endingSpans asArray equals: { span }.
	self assert: injectedProcessor endedSpans asArray equals: { span }.
	self assert: globalProcessor startedSpans isEmpty.
	self assert: globalProcessor endingSpans isEmpty.
	self assert: globalProcessor endedSpans isEmpty
]

{ #category : 'tests' }
OTTracerProviderTest >> testForceFlushSuppressesProcessorErrorsAndContinues [

	self withSpanProcessorWarningsDo: [ :warnings |
		| failingProcessor provider succeedingProcessor |
		provider := OTTracerProvider new.
		failingProcessor := OTFailingSpanProcessor failingOperations: { 'forceFlush' }.
		succeedingProcessor := OTFailingSpanProcessor new.
		provider
			spanProcessor: failingProcessor;
			addSpanProcessor: succeedingProcessor.
		self deny: provider forceFlush.
		self assert: succeedingProcessor forceFlushCount equals: 1.
		self assert: warnings asArray equals: {
			'OpenTelemetry span processor callback failed during forceFlush for OTFailingSpanProcessor: processor failure' } ]
]

{ #category : 'tests' }
OTTracerProviderTest >> testProcessorErrorsDuringSpanLifecycleAreSuppressedAndLaterProcessorsStillRun [

	self withSpanProcessorWarningsDo: [ :warnings |
		| failingProcessor provider succeedingProcessor span tracer |
		provider := OTTracerProvider new.
		failingProcessor := OTFailingSpanProcessor failingOperations: { 'onStart'. 'onEnding'. 'onEnd' }.
		succeedingProcessor := OTFailingSpanProcessor new.
		provider
			spanProcessor: failingProcessor;
			addSpanProcessor: succeedingProcessor.
		tracer := provider tracerNamed: 'demo.scope'.
		span := (tracer spanBuilderNamed: 'operation') startSpan.
		span end.
		self assert: succeedingProcessor startedSpans asArray equals: { span }.
		self assert: succeedingProcessor endingSpans asArray equals: { span }.
		self assert: succeedingProcessor endedSpans asArray equals: { span }.
		self assert: warnings asArray equals: {
			'OpenTelemetry span processor callback failed during onStart for OTFailingSpanProcessor: processor failure'.
			'OpenTelemetry span processor callback failed during onEnding for OTFailingSpanProcessor: processor failure'.
			'OpenTelemetry span processor callback failed during onEnd for OTFailingSpanProcessor: processor failure' } ]
]

{ #category : 'tests' }
OTTracerProviderTest >> testSpanEndUsesSpanProcessorOnEndLifecycle [

	| processor provider span tracer |
	provider := OTTracerProvider new.
	processor := OTRecordingSpanProcessor new.
	provider spanProcessor: processor.
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	span end.
	self assert: processor endingSpans asArray equals: { span }.
	self assert: processor endedSpans asArray equals: { span }.
	self assert: span isEnded.
	self assert: (span attributes at: 'processor.onEnding') equals: true
]

{ #category : 'tests' }
OTTracerProviderTest >> testRecordingSpanNotifiesSpanProcessorOnStartWithResolvedParentContext [

	| parentContext parentSpan processor provider span tracer |
	provider := OTTracerProvider new.
	processor := OTRecordingSpanProcessor new.
	provider spanProcessor: processor.
	tracer := provider tracerNamed: 'demo.scope'.
	parentSpan := (OTSpanContext
		traceId: '00112233445566778899aabbccddeeff'
		spanId: '1122334455667788'
		traceFlags: '03'
		traceState: nil
		remote: true) asNonRecordingSpan.
	parentContext := OTContext new withSpan: parentSpan.
	span := ((tracer spanBuilderNamed: 'child')
		inContext: parentContext;
		startSpan).
	self assert: processor startedSpans asArray equals: { span }.
	self assert: processor startedParentContexts asArray equals: { parentContext }.
	self assert: processor endedSpans isEmpty
]

{ #category : 'tests' }
OTTracerProviderTest >> testTracerNamedEmptyStringReturnsWorkingTracerWithEmptyNameAndWarning [

	self
		withTracerNameWarningsDo: [ :warnings |
			| provider tracer |
			provider := OTTracerProvider new.
			provider spanProcessor: OTSimpleSpanProcessor new.
			tracer := provider tracerNamed: ''.
			self assert: tracer instrumentationName equals: ''.
			self assert: warnings size equals: 1.
			self assert: warnings first equals:
				'OpenTelemetry tracer name was invalid and has been normalized to an empty string: ''''' ]
]

{ #category : 'tests' }
OTTracerProviderTest >> testTracerNamedNilReturnsWorkingTracerWithEmptyNameAndWarning [

	self
		withTracerNameWarningsDo: [ :warnings |
			| provider tracer |
			provider := OTTracerProvider new.
			provider spanProcessor: OTSimpleSpanProcessor new.
			tracer := provider tracerNamed: nil.
			self assert: tracer instrumentationName equals: ''.
			self assert: warnings size equals: 1.
			self assert: warnings first equals:
				'OpenTelemetry tracer name was invalid and has been normalized to an empty string: nil' ]
]

{ #category : 'tests' }
OTTracerProviderTest >> testTracerNamedWhitespaceOnlyStringNormalizesToEmptyName [

	self
		withTracerNameWarningsDo: [ :warnings |
			| provider tracer |
			provider := OTTracerProvider new.
			provider spanProcessor: OTSimpleSpanProcessor new.
			tracer := provider tracerNamed: '   '.
			self assert: tracer instrumentationName equals: ''.
			self assert: warnings size equals: 1 ]
]

{ #category : 'tests' }
OTTracerProviderTest >> testRecordingSpanSamplerCanExplicitlyClearParentTraceState [

	| parentContext provider sampler span |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	sampler := OTSamplingResultSampler result: (OTSamplingResult
		decision: #recordAndSample
		attributes: #()
		traceState: OTTraceState empty).
	provider sampler: sampler.
	parentContext := OTContext new
		withSpan: ((OTSpanContext
			traceId: '00112233445566778899aabbccddeeff'
			spanId: '1122334455667788'
			traceFlags: '03'
			traceState: 'vendor=value'
			remote: true) asNonRecordingSpan).
	span := (((provider tracerNamed: 'demo.scope') spanBuilderNamed: 'child')
		inContext: parentContext;
		startSpan).
	self assert: span spanContext traceState class identicalTo: OTTraceState.
	self assert: span spanContext traceState isEmpty
]

{ #category : 'tests' }
OTTracerProviderTest >> testRootSpanMarksGeneratedTraceIdsAsRandom [

	| provider tracer span |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	self assert: span spanContext traceFlags equals: '03'.
	self assert: span spanContext isRandom
]

{ #category : 'tests' }
OTTracerProviderTest >> testShutdownMakesReturnedTracerBehaveAsNoop [

	| provider span |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	self assert: provider shutdown.
	span := (provider tracerNamed: 'demo.scope')
		startSpanNamed: 'operation'
		in: OTContext new.
	self assert: span class identicalTo: OTNonRecordingSpan.
	self deny: span spanContext isValid
]

{ #category : 'tests' }
OTTracerProviderTest >> testShutdownShutsDownLifecycleManagedAlwaysRecordWrappedSampler [

	| provider rootSampler |
	provider := OTTracerProvider new.
	rootSampler := OTLifecycleTrackingSampler new.
	provider sampler: (OTSampler alwaysRecord: rootSampler).
	self assert: provider shutdown.
	self assert: rootSampler startCount equals: 1.
	self assert: rootSampler shutdownCount equals: 1
]

{ #category : 'tests' }
OTTracerProviderTest >> testShutdownShutsDownLifecycleManagedSampler [

	| provider rootSampler |
	provider := OTTracerProvider new.
	rootSampler := OTLifecycleTrackingSampler new.
	provider sampler: (OTParentBasedSampler root: rootSampler).
	self assert: provider shutdown.
	self assert: rootSampler startCount equals: 1.
	self assert: rootSampler shutdownCount equals: 1
]

{ #category : 'tests' }
OTTracerProviderTest >> testShutdownSuppressesProcessorErrorsAndContinues [

	self withSpanProcessorWarningsDo: [ :warnings |
		| failingProcessor provider succeedingProcessor |
		provider := OTTracerProvider new.
		failingProcessor := OTFailingSpanProcessor failingOperations: { 'shutdown' }.
		succeedingProcessor := OTFailingSpanProcessor new.
		provider
			spanProcessor: failingProcessor;
			addSpanProcessor: succeedingProcessor.
		self deny: provider shutdown.
		self assert: provider isShutdown.
		self assert: succeedingProcessor shutdownCount equals: 1.
		self assert: warnings asArray equals: {
			'OpenTelemetry span processor callback failed during shutdown for OTFailingSpanProcessor: processor failure' } ]
]

{ #category : 'tests' }
OTTracerProviderTest >> testNonRecordingSpanSamplerCanExplicitlyClearParentTraceState [

	| parentContext provider sampler span |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	sampler := OTSamplingResultSampler result: (OTSamplingResult
		decision: #drop
		attributes: #()
		traceState: OTTraceState empty).
	provider sampler: sampler.
	parentContext := OTContext new
		withSpan: ((OTSpanContext
			traceId: '00112233445566778899aabbccddeeff'
			spanId: '1122334455667788'
			traceFlags: '03'
			traceState: 'vendor=value'
			remote: true) asNonRecordingSpan).
	span := (((provider tracerNamed: 'demo.scope') spanBuilderNamed: 'child')
		inContext: parentContext;
		startSpan).
	self assert: span class identicalTo: OTNonRecordingSpan.
	self assert: span spanContext traceState class identicalTo: OTTraceState.
	self assert: span spanContext traceState isEmpty
]

{ #category : 'tests' }
OTTracerProviderTest >> testParentBasedSamplerErasesInconsistentInheritedParentThreshold [

	| parentContext provider span |
	provider := OTTracerProvider new.
	provider
		spanProcessor: OTSimpleSpanProcessor new;
		sampler: OTSampler parentBased.
	parentContext := OTContext new
		withSpan: ((OTSpanContext
			traceId: '00112233445566778899aabbccddeeff'
			spanId: '1122334455667788'
			traceFlags: '01'
			traceState: 'ot=rv:7fffffffffffff;th:8'
			remote: true) asNonRecordingSpan).
	span := ((provider tracerNamed: 'demo.scope') spanBuilderNamed: 'child')
		inContext: parentContext;
		startSpan.
	self assert: span isRecording.
	self assert: (span spanContext traceState otelValueAt: 'rv') equals: '7fffffffffffff'.
	self assert: (span spanContext traceState otelValueAt: 'th') equals: nil
]

{ #category : 'tests' }
OTTracerProviderTest >> testParentBasedSamplerPreservesConsistentInheritedParentThreshold [

	| parentContext provider span |
	provider := OTTracerProvider new.
	provider
		spanProcessor: OTSimpleSpanProcessor new;
		sampler: OTSampler parentBased.
	parentContext := OTContext new
		withSpan: ((OTSpanContext
			traceId: '00112233445566778899aabbccddeeff'
			spanId: '1122334455667788'
			traceFlags: '01'
			traceState: 'ot=rv:80000000000000;th:8'
			remote: true) asNonRecordingSpan).
	span := ((provider tracerNamed: 'demo.scope') spanBuilderNamed: 'child')
		inContext: parentContext;
		startSpan.
	self assert: span isRecording.
	self assert: (span spanContext traceState otelValueAt: 'rv') equals: '80000000000000'.
	self assert: (span spanContext traceState otelValueAt: 'th') equals: '8'
]

{ #category : 'tests' }
OTTracerProviderTest >> testParentBasedSamplerRemovesInheritedThresholdForUnsampledChild [

	| parentContext provider span |
	provider := OTTracerProvider new.
	provider
		spanProcessor: OTSimpleSpanProcessor new;
		sampler: OTSampler parentBased.
	parentContext := OTContext new
		withSpan: ((OTSpanContext
			traceId: '00112233445566778899aabbccddeeff'
			spanId: '1122334455667788'
			traceFlags: '00'
			traceState: 'ot=rv:80000000000000;th:8'
			remote: true) asNonRecordingSpan).
	span := ((provider tracerNamed: 'demo.scope') spanBuilderNamed: 'child')
		inContext: parentContext;
		startSpan.
	self assert: span class identicalTo: OTNonRecordingSpan.
	self assert: (span spanContext traceState otelValueAt: 'rv') equals: '80000000000000'.
	self assert: (span spanContext traceState otelValueAt: 'th') equals: nil
]

{ #category : 'tests' }
OTTracerProviderTest >> testUnsampledChildSpanPreservesParentRandomFlag [

	| provider tracer parentContext span |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	parentContext := OTContext new
		withSpan: ((OTSpanContext
			traceId: '00112233445566778899aabbccddeeff'
			spanId: '1122334455667788'
			traceFlags: '02'
			traceState: nil
			remote: true) asNonRecordingSpan).
	span := ((tracer spanBuilderNamed: 'child')
		inContext: parentContext;
		startSpan).
	self assert: span class identicalTo: OTNonRecordingSpan.
	self assert: span spanContext traceFlags equals: '02'.
	self assert: span spanContext isRandom
]

{ #category : 'tests' }
OTTracerProviderTest >> testReplacingSamplerShutsDownPreviousLifecycleManagedSampler [

	| firstProviderSampler provider secondProviderSampler |
	provider := OTTracerProvider new.
	firstProviderSampler := OTLifecycleTrackingSampler new.
	secondProviderSampler := OTLifecycleTrackingSampler new.
	provider sampler: (OTParentBasedSampler root: firstProviderSampler).
	provider sampler: (OTParentBasedSampler root: secondProviderSampler).
	self assert: firstProviderSampler startCount equals: 1.
	self assert: firstProviderSampler shutdownCount equals: 1.
	self assert: secondProviderSampler startCount equals: 1.
	self assert: secondProviderSampler shutdownCount equals: 0
]

{ #category : 'tests' }
OTTracerProviderTest >> testReplacingSamplerShutsDownPreviousAlwaysRecordWrappedSampler [

	| firstProviderSampler provider secondProviderSampler |
	provider := OTTracerProvider new.
	firstProviderSampler := OTLifecycleTrackingSampler new.
	secondProviderSampler := OTLifecycleTrackingSampler new.
	provider sampler: (OTSampler alwaysRecord: firstProviderSampler).
	provider sampler: (OTSampler alwaysRecord: secondProviderSampler).
	self assert: firstProviderSampler startCount equals: 1.
	self assert: firstProviderSampler shutdownCount equals: 1.
	self assert: secondProviderSampler startCount equals: 1.
	self assert: secondProviderSampler shutdownCount equals: 0
]

{ #category : 'tests' }
OTTracerProviderTest >> testTracerCachesByFullInstrumentationScope [

	| provider first second third |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	first := provider
		tracerNamed: 'demo.scope'
		version: '1.2.3'
		schemaUrl: 'https://opentelemetry.io/schemas/1.0.0'
		attributes: self sampleAttributes.
	second := provider
		tracerNamed: 'demo.scope'
		version: '1.2.3'
		schemaUrl: 'https://opentelemetry.io/schemas/1.0.0'
		attributes: self sampleAttributes.
	third := provider
		tracerNamed: 'demo.scope'
		version: '2.0.0'
		schemaUrl: 'https://opentelemetry.io/schemas/1.0.0'
		attributes: self sampleAttributes.
	self assert: first identicalTo: second.
	self deny: first identicalTo: third
]

{ #category : 'tests' }
OTTracerProviderTest >> testConfiguredResourceMergesConfiguredDetectorsInOrder [

	| resource |
	OTTracerProvider resourceDetectors: {
		(OTStaticResourceDetector
			named: 'first'
			resource: (OTResource attributes: {
				'service.name' -> 'first'.
				'deployment.environment.name' -> 'dev' })).
		(OTStaticResourceDetector
			named: 'second'
			resource: (OTResource attributes: {
				'service.name' -> 'second'.
				'host.name' -> 'pharo-host' })) }.
	resource := OTTracerProvider configuredResource.
	self assert: resource serviceName equals: 'second'.
	self assert: (resource attributeAt: 'deployment.environment.name') equals: 'dev'.
	self assert: (resource attributeAt: 'host.name') equals: 'pharo-host'
]

{ #category : 'tests' }
OTTracerProviderTest >> testConfiguredResourceSkipsFailingDetectorAndLogsWarning [

	self withResourceConfigurationWarningsDo: [ :warnings |
		| resource |
		OTTracerProvider resourceDetectors: {
			(OTStaticResourceDetector
				named: 'base'
				resource: (OTResource attributes: { 'service.name' -> 'base' })).
			(OTBlockResourceDetector
				named: 'broken'
				detecting: [ Error signal: 'boom' ]).
			(OTStaticResourceDetector
				named: 'after'
				resource: (OTResource attributes: { 'host.name' -> 'pharo-host' })) }.
		resource := OTTracerProvider configuredResource.
		self assert: resource serviceName equals: 'base'.
		self assert: (resource attributeAt: 'host.name') equals: 'pharo-host'.
		self assert: warnings asArray equals:
			{ 'OpenTelemetry resource detector failed during resource detection for OTBlockResourceDetector (''broken''): boom' } ]
]

{ #category : 'tests' }
OTTracerProviderTest >> testConfiguredResourceWarnsAboutDuplicateDetectorNames [

	self withResourceConfigurationWarningsDo: [ :warnings |
		OTTracerProvider resourceDetectors: {
			(OTStaticResourceDetector named: 'duplicate' resource: OTResource empty).
			(OTStaticResourceDetector named: 'duplicate' resource: OTResource empty) }.
		OTTracerProvider configuredResource.
		self assert: warnings asArray equals:
			{ 'OpenTelemetry resource detector name was registered more than once: ''duplicate''' } ]
]

{ #category : 'tests' }
OTTracerProviderTest >> testTracerWithoutProcessorsReturnsNonRecordingSpan [

	| provider span |
	provider := OTTracerProvider new.
	span := (provider tracerNamed: 'demo.scope')
		startSpanNamed: 'operation'
		in: OTContext new.
	self assert: span class identicalTo: OTNonRecordingSpan.
	self deny: span spanContext isValid
]
