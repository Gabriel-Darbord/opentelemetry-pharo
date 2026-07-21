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
		OTLifecycleObservingSpanProcessor resetRecordedLifecycle.
		OTTracerProvider current: nil.
		OTTracerProvider tracerConfigurationWarningSink: nil.
		OTTracerProvider resourceConfigurationWarningSink: nil.
		OTTracerProvider resourceDetectors: nil.
		OTTracerProvider spanProcessorWarningSink: nil.
		OTTracerProvider tracerNameWarningSink: nil.
		OTSpanProcessor current: nil.
		OTSpanExporter current: nil.
		OTSpan reset ] ensure: [
			OTBlockingShutdownSpanProcessor allInstancesDo: [ :each | each allowShutdown ].
			OTBlockingOnEndingSpanProcessor allInstancesDo: [ :each | each allowOnEnding ].
			super tearDown ]
]

{ #category : 'tests' }
OTTracerProviderTest >> testAllOnEndingCallbacksRunBeforeAnyOnEndCallback [

	| endingIndexes firstOnEndIndex processorOne processorTwo provider span timeline tracer |
	OTLifecycleObservingSpanProcessor resetRecordedLifecycle.
	provider := OTTracerProvider new.
	processorOne := OTLifecycleObservingSpanProcessor new.
	processorTwo := OTLifecycleObservingSpanProcessor new.
	provider
		spanProcessor: processorOne;
		addSpanProcessor: processorTwo.
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	span end.
	timeline := OTLifecycleObservingSpanProcessor timeline asArray.
	self assert: timeline size equals: 6.
	self assert: timeline first asArray equals: {
			processorOne.
			#onStart.
			true.
			false }.
	self assert: timeline second asArray equals: {
			processorTwo.
			#onStart.
			true.
			false }.
	self assert: timeline third asArray equals: {
			processorOne.
			#onEnding.
			true.
			true }.
	self assert: timeline fourth asArray equals: {
			processorTwo.
			#onEnding.
			true.
			true }.
	self assert: timeline fifth asArray equals: {
			processorOne.
			#onEnd.
			false.
			true.
			true }.
	self assert: timeline sixth asArray equals: {
			processorTwo.
			#onEnd.
			false.
			true.
			true }.
	endingIndexes := OrderedCollection new.
	1 to: timeline size do: [ :index | (timeline at: index) second = #onEnding ifTrue: [ endingIndexes add: index ] ].
	firstOnEndIndex := (1 to: timeline size) detect: [ :index | (timeline at: index) second = #onEnd ].
	self assert: (endingIndexes allSatisfy: [ :index | index < firstOnEndIndex ])
]

{ #category : 'tests' }
OTTracerProviderTest >> testConcurrentCurrentReturnsSingleProviderInstance [

	| done errors firstProvider lock providers start providerCount |
	OTTracerProvider current: nil.
	OTSpanExporter current: OTRecordingSpanExporter new.
	providers := OrderedCollection new.
	errors := OrderedCollection new.
	lock := Semaphore forMutualExclusion.
	start := Semaphore new.
	done := Semaphore new.
	providerCount := 8.
	providerCount timesRepeat: [
			[
				| provider |
				start wait.
				[
					provider := OTTracerProvider current.
					lock critical: [ providers add: provider ] ]
					on: Error
					do: [ :error | lock critical: [ errors add: error ] ].
				done signal ] forkAt: Processor userBackgroundPriority ].
	providerCount timesRepeat: [ start signal ].
	providerCount timesRepeat: [ self assert: (done waitTimeoutMilliseconds: 500) not ].
	self assert: errors isEmpty.
	self assert: providers size equals: providerCount.
	self assert: providers asSet size equals: 1.
	firstProvider := providers first.
	self assert: firstProvider identicalTo: OTTracerProvider current
]

{ #category : 'tests' }
OTTracerProviderTest >> testConcurrentShutdownIsIdempotent [

	| firstDone firstResult processor provider secondDone secondResult |
	provider := OTTracerProvider new.
	processor := OTBlockingShutdownSpanProcessor new.
	provider spanProcessor: processor.
	firstDone := Semaphore new.
	secondDone := Semaphore new.
	[
		firstResult := provider shutdown.
		firstDone signal ] forkAt: Processor userBackgroundPriority.
	self assert: (processor waitForShutdownTimeoutMillis: 200).
	[
		secondResult := provider shutdown.
		secondDone signal ] forkAt: Processor userBackgroundPriority.
	self assert: (secondDone waitTimeoutMilliseconds: 200) not.
	self deny: secondResult.
	processor allowShutdown.
	self assert: (firstDone waitTimeoutMilliseconds: 200) not.
	self assert: firstResult.
	self assert: provider isShutdown.
	self assert: processor shutdownCount equals: 1
]

{ #category : 'tests' }
OTTracerProviderTest >> testConcurrentTracerLookupReturnsSingleTracerInstance [

	| done errors lock provider results start tracerCount |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	results := OrderedCollection new.
	errors := OrderedCollection new.
	lock := Semaphore forMutualExclusion.
	start := Semaphore new.
	done := Semaphore new.
	tracerCount := 8.
	tracerCount timesRepeat: [
			[
				| tracer |
				start wait.
				[
					tracer := provider tracerNamed: 'demo.scope'.
					lock critical: [ results add: tracer ] ]
					on: Error
					do: [ :error | lock critical: [ errors add: error ] ].
				done signal ] forkAt: Processor userBackgroundPriority ].
	tracerCount timesRepeat: [ start signal ].
	tracerCount timesRepeat: [ self assert: (done waitTimeoutMilliseconds: 500) not ].
	self assert: errors isEmpty.
	self assert: results size equals: tracerCount.
	self assert: results asSet size equals: 1
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
OTTracerProviderTest >> testCustomIdGeneratorControlsNonRecordingSpanIds [

	| generator provider span tracer |
	provider := OTTracerProvider new.
	provider
		spanProcessor: OTSimpleSpanProcessor new;
		sampler: OTAlwaysOffSampler new;
		idGenerator:
			(generator := OTFixedIdGenerator traceIdHex: '00112233445566778899aabbccddeeff' spanIdHex: '1122334455667788' random: false).
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	self assert: span class identicalTo: OTNonRecordingSpan.
	self assert: span spanContext traceId equals: generator generateTraceIdHex.
	self assert: span spanContext spanId equals: generator generateSpanIdHex.
	self assert: span spanContext traceFlags equals: '00'
]

{ #category : 'tests' }
OTTracerProviderTest >> testCustomIdGeneratorControlsRootTraceAndSpanIds [

	| generator provider span tracer |
	provider := OTTracerProvider new.
	provider
		spanProcessor: OTSimpleSpanProcessor new;
		idGenerator:
			(generator := OTFixedIdGenerator traceIdHex: '00112233445566778899aabbccddeeff' spanIdHex: '1122334455667788' random: false).
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	self assert: span spanContext traceId equals: generator generateTraceIdHex.
	self assert: span spanContext spanId equals: generator generateSpanIdHex.
	self assert: span spanContext traceFlags equals: '01'.
	self deny: span spanContext isRandom
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
OTTracerProviderTest >> testCustomTracerProviderUsesStandardNoopWrappedSpanClass [

	| parentSpan provider returnedSpan tracer |
	provider := OTCustomTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	parentSpan := (tracer spanBuilderNamed: 'parent') startSpan.
	provider tracerConfigurator: [ :scope | false ].
	returnedSpan := (tracer spanBuilderNamed: 'operation')
		                inContext: (OTContext new withSpan: parentSpan);
		                startSpan.
	self assert: returnedSpan class identicalTo: OTNonRecordingSpan.
	self assert: returnedSpan spanContext traceId equals: parentSpan spanContext traceId.
	self assert: returnedSpan spanContext spanId equals: parentSpan spanContext spanId
]

{ #category : 'tests' }
OTTracerProviderTest >> testDisabledTracerNonRecordingSpanPreservesInstrumentationScope [

	| provider span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider
		          tracerNamed: 'demo.scope'
		          version: '1.2.3'
		          schemaUrl: 'https://opentelemetry.io/schemas/1.0.0'
		          attributes: self sampleAttributes.
	provider tracerConfigurator: [ :scope | false ].
	span := (tracer spanBuilderNamed: 'child') startSpan.
	self assert: span class identicalTo: OTNonRecordingSpan.
	self assert: span instrumentationScope equals: tracer instrumentationScope
]

{ #category : 'tests' }
OTTracerProviderTest >> testDisabledTracerPreservesParentSpanContext [

	| disabledSpan parentSpan provider tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	parentSpan := (tracer spanBuilderNamed: 'parent') startSpan.
	provider tracerConfigurator: [ :scope | false ].
	disabledSpan := (tracer spanBuilderNamed: 'child')
		                inContext: (OTContext new withSpan: parentSpan);
		                startSpan.
	self assert: disabledSpan class identicalTo: OTNonRecordingSpan.
	self deny: disabledSpan identicalTo: parentSpan.
	self assert: disabledSpan spanContext traceId equals: parentSpan spanContext traceId.
	self assert: disabledSpan spanContext spanId equals: parentSpan spanContext spanId.
	self assert: disabledSpan spanContext traceFlags equals: parentSpan spanContext traceFlags.
	self assert: disabledSpan spanContext traceState equals: parentSpan spanContext traceState
]

{ #category : 'tests' }
OTTracerProviderTest >> testDisabledTracerReturnsExistingNonRecordingParentSpan [

	| disabledSpan parentSpan provider tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider
		          tracerNamed: 'demo.scope'
		          version: '1.2.3'
		          schemaUrl: 'https://opentelemetry.io/schemas/1.0.0'
		          attributes: self sampleAttributes.
	parentSpan := (OTSpanContext
		               traceId: '00112233445566778899aabbccddeeff'
		               spanId: '1122334455667788'
		               traceFlags: '03'
		               traceState: 'vendor=value'
		               remote: true) asNonRecordingSpan.
	provider tracerConfigurator: [ :scope | false ].
	disabledSpan := (tracer spanBuilderNamed: 'child')
		                inContext: (OTContext new withSpan: parentSpan);
		                startSpan.
	self assert: disabledSpan identicalTo: parentSpan
]

{ #category : 'tests' }
OTTracerProviderTest >> testDisabledTracerWithoutParentReturnsInvalidNonRecordingSpan [

	| disabledSpan provider tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	provider tracerConfigurator: [ :scope | false ].
	disabledSpan := (tracer spanBuilderNamed: 'child') startSpan.
	self assert: disabledSpan class identicalTo: OTNonRecordingSpan.
	self deny: disabledSpan isRecording.
	self deny: disabledSpan spanContext isValid
]

{ #category : 'tests' }
OTTracerProviderTest >> testEndingSpanDuringShutdownDoesNotNotifySpanProcessor [

	| blockingProcessor done provider recordingProcessor shutdownResult span tracer |
	provider := OTTracerProvider new.
	blockingProcessor := OTBlockingShutdownSpanProcessor new.
	recordingProcessor := OTRecordingSpanProcessor new.
	provider
		spanProcessor: blockingProcessor;
		addSpanProcessor: recordingProcessor.
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	done := Semaphore new.
	[
		shutdownResult := provider shutdown.
		done signal ] forkAt: Processor userBackgroundPriority.
	self assert: (blockingProcessor waitForShutdownTimeoutMillis: 200).
	span end.
	self assert: recordingProcessor startedSpans asArray equals: { span }.
	self assert: recordingProcessor endingSpans isEmpty.
	self assert: recordingProcessor endedSpans isEmpty.
	blockingProcessor allowShutdown.
	self assert: (done waitTimeoutMilliseconds: 200) not.
	self assert: shutdownResult
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
OTTracerProviderTest >> testExistingTracerBehavesAsNoopAfterShutdown [

	| parentSpan processor provider span tracer |
	provider := OTTracerProvider new.
	processor := OTRecordingSpanProcessor new.
	provider spanProcessor: processor.
	tracer := provider tracerNamed: 'demo.scope'.
	parentSpan := (tracer spanBuilderNamed: 'parent') startSpan.
	self assert: tracer enabled.
	self assert: provider shutdown.
	self deny: tracer enabled.
	self assert: (tracer spanBuilderNamed: 'child') class identicalTo: OTNoopSpanBuilder.
	span := (tracer spanBuilderNamed: 'child')
		        inContext: (OTContext new withSpan: parentSpan);
		        startSpan.
	self assert: span class identicalTo: OTNonRecordingSpan.
	self deny: span isRecording.
	self assert: span spanContext traceId equals: parentSpan spanContext traceId.
	self assert: processor startedSpans asArray equals: { parentSpan }
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
OTTracerProviderTest >> testExistingTracerPicksUpLaterIdGeneratorChangesWithoutReacquiring [

	| generator provider span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	provider idGenerator:
		(generator := OTFixedIdGenerator traceIdHex: '00112233445566778899aabbccddeeff' spanIdHex: '1122334455667788' random: false).
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	self assert: span spanContext traceId equals: generator generateTraceIdHex.
	self assert: span spanContext spanId equals: generator generateSpanIdHex.
	self deny: span spanContext isRandom
]

{ #category : 'tests' }
OTTracerProviderTest >> testExistingTracerPicksUpLaterResourceChangesForNewSpans [

	| exportRecord provider resource span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	resource := OTResource attributes: (OrderedDictionary new
			             at: 'service.name' put: 'updated-service';
			             at: 'deployment.environment.name' put: 'staging';
			             yourself).
	provider resource: resource.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	exportRecord := span asExportRecord.
	self assert: (exportRecord at: #resource) equals: resource.
	self assert: ((exportRecord at: #resource) attributeAt: 'deployment.environment.name') equals: 'staging'
]

{ #category : 'tests' }
OTTracerProviderTest >> testExistingTracerPicksUpLaterSamplerChangesWithoutReacquiring [

	| provider span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	provider sampler: OTAlwaysOffSampler new.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	self assert: span class identicalTo: OTNonRecordingSpan.
	self assert: span spanContext isValid.
	self deny: span spanContext isSampled.
	self assert: span spanContext isRandom
]

{ #category : 'tests' }
OTTracerProviderTest >> testExistingTracerPicksUpLaterSpanLimitChangesWithoutReacquiring [

	| exportRecord limits provider span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	limits := OTSpanLimits new.
	limits attributeCountLimit: 0.
	provider spanLimits: limits.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	span attributeAt: 'late.attribute' put: 42.
	exportRecord := span asExportRecord.
	self deny: (exportRecord includesKey: #attributes).
	self assert: (exportRecord at: #droppedAttributesCount) equals: 1
]

{ #category : 'tests' }
OTTracerProviderTest >> testExistingTracerPicksUpLaterSpanProcessorRegistrationWithoutReacquiring [

	| processor provider span tracer |
	provider := OTTracerProvider new.
	tracer := provider tracerNamed: 'demo.scope'.
	self deny: tracer enabled.
	span := (tracer spanBuilderNamed: 'before') startSpan.
	self assert: span class identicalTo: OTNonRecordingSpan.
	self deny: span isRecording.
	self deny: span spanContext isValid.
	span end.
	processor := OTRecordingSpanProcessor new.
	provider spanProcessor: processor.
	self assert: tracer enabled.
	span := (tracer spanBuilderNamed: 'after') startSpan.
	self assert: span isRecording.
	span end.
	self assert: processor startedSpans asArray equals: { span }.
	self assert: processor endingSpans asArray equals: { span }.
	self assert: processor endedSpans asArray equals: { span }
]

{ #category : 'tests' }
OTTracerProviderTest >> testExistingTracerPicksUpLaterSpanProcessorRemovalWithoutReacquiring [

	| processor provider span tracer |
	provider := OTTracerProvider new.
	processor := OTFailingSpanProcessor new.
	provider spanProcessor: processor.
	tracer := provider tracerNamed: 'demo.scope'.
	provider spanProcessors: #(  ).
	self deny: tracer enabled.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	self assert: processor shutdownCount equals: 1.
	self assert: span class identicalTo: OTNonRecordingSpan.
	self deny: span isRecording.
	self deny: span spanContext isValid.
	self assert: processor startedSpans isEmpty.
	self assert: processor endingSpans isEmpty.
	self assert: processor endedSpans isEmpty
]

{ #category : 'tests' }
OTTracerProviderTest >> testExistingTracerUsesReplacementSpanProcessorWithoutReacquiring [

	| firstProcessor provider secondProcessor span tracer |
	provider := OTTracerProvider new.
	firstProcessor := OTRecordingSpanProcessor new.
	provider spanProcessor: firstProcessor.
	tracer := provider tracerNamed: 'demo.scope'.
	secondProcessor := OTRecordingSpanProcessor new.
	provider spanProcessor: secondProcessor.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	span end.
	self assert: firstProcessor startedSpans isEmpty.
	self assert: firstProcessor endingSpans isEmpty.
	self assert: firstProcessor endedSpans isEmpty.
	self assert: secondProcessor startedSpans asArray equals: { span }.
	self assert: secondProcessor endingSpans asArray equals: { span }.
	self assert: secondProcessor endedSpans asArray equals: { span }
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
OTTracerProviderTest >> testForceFlushExportsPendingBatchProcessorSpans [

	| exporter provider span tracer |
	exporter := OTRecordingSpanExporter new.
	OTSpanExporter current: exporter.
	provider := OTTracerProvider new.
	provider spanProcessor: (OTBatchSpanProcessor new
			 exporter: exporter;
			 batchSize: 10;
			 scheduledDelayMillis: 1000;
			 yourself).
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	span end.
	self assert: provider forceFlush.
	self assert: exporter exportedBatches size equals: 1.
	self assert: exporter exportedBatches first size equals: 1.
	self assert: exporter forceFlushCount equals: 1.
	self assert: exporter shutdownCount equals: 0
]

{ #category : 'tests' }
OTTracerProviderTest >> testForceFlushReturnsFalseWhileShutdownIsInProgress [

	| done processor provider shutdownResult |
	provider := OTTracerProvider new.
	processor := OTBlockingShutdownSpanProcessor new.
	provider spanProcessor: processor.
	done := Semaphore new.
	[
		shutdownResult := provider shutdown.
		done signal ] forkAt: Processor userBackgroundPriority.
	self assert: (processor waitForShutdownTimeoutMillis: 200).
	self deny: provider forceFlush.
	processor allowShutdown.
	self assert: (done waitTimeoutMilliseconds: 200) not.
	self assert: shutdownResult
]

{ #category : 'tests' }
OTTracerProviderTest >> testForceFlushSucceedsWhenNoProcessorsAreRegistered [

	| provider |
	provider := OTTracerProvider new.
	self assert: provider forceFlush
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
OTTracerProviderTest >> testOnEndingRejectsConcurrentMutationsFromOtherThreads [

	| endDone exportRecord mutationDone mutationResult processor provider span tracer |
	provider := OTTracerProvider new.
	processor := OTBlockingOnEndingSpanProcessor new.
	provider spanProcessor: processor.
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	endDone := Semaphore new.
	[
		span end.
		endDone signal ] forkAt: Processor userBackgroundPriority.
	self assert: (processor waitForOnEndingTimeoutMillis: 200).
	self assert: span isRecording.
	mutationDone := Semaphore new.
	[
		mutationResult := span attributeAt: 'outside.thread' put: true.
		mutationDone signal ] forkAt: Processor userBackgroundPriority.
	self assert: (mutationDone waitTimeoutMilliseconds: 200) not.
	self assert: mutationResult identicalTo: span.
	processor allowOnEnding.
	self assert: (endDone waitTimeoutMilliseconds: 200) not.
	exportRecord := span asExportRecord.
	self deny: span isRecording.
	self assert: ((exportRecord at: #attributes) at: 'processor.onEnding') equals: true.
	self deny: ((exportRecord at: #attributes) includesKey: 'outside.thread')
]

{ #category : 'tests' }
OTTracerProviderTest >> testOnEndingSeesComputedEndTimestampAndCanStillMutateSpan [

	| endEntry endTimestamp exportRecord onEndingEntry processor provider span tracer |
	OTLifecycleObservingSpanProcessor resetRecordedLifecycle.
	provider := OTTracerProvider new.
	processor := OTLifecycleObservingSpanProcessor new.
	provider spanProcessor: processor.
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	endTimestamp := DateAndTime unixEpoch + (Duration milliSeconds: 123).
	span end: endTimestamp.
	exportRecord := span asExportRecord.
	onEndingEntry := processor timeline second.
	endEntry := processor timeline third.
	self assert: onEndingEntry asArray equals: {
			processor.
			#onEnding.
			true.
			true }.
	self assert: endEntry asArray equals: {
			processor.
			#onEnd.
			false.
			true.
			true }.
	self assert: (exportRecord at: #endTime) equals: endTimestamp.
	self assert: ((exportRecord at: #attributes) at: 'processor.onEnding.order') equals: processor identityHash asString.
	self assert:
		((exportRecord at: #events) anySatisfy: [ :each | each name = ('processor.onEnding.' , processor identityHash asString) ])
]

{ #category : 'tests' }
OTTracerProviderTest >> testOnStartProcessorCanObserveLaterSpanUpdatesThroughCapturedSpanReference [

	| capturedSpan exportRecord processor provider span tracer |
	provider := OTTracerProvider new.
	processor := OTRecordingSpanProcessor new.
	provider spanProcessor: processor.
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	capturedSpan := processor startedSpans first.
	self assert: capturedSpan identicalTo: span.
	span
		attributeAt: 'later.attribute' put: 42;
		addEventNamed: 'later.event';
		setStatus: OTSpan error description: 'boom'.
	exportRecord := capturedSpan asExportRecord.
	self assert: ((exportRecord at: #attributes) at: 'later.attribute') equals: 42.
	self assert: ((exportRecord at: #events) anySatisfy: [ :each | each name = 'later.event' ]).
	self assert: (exportRecord at: #status) equals: OTSpan error.
	self assert: (exportRecord at: #statusDescription) equals: 'boom'
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
OTTracerProviderTest >> testReadableSpanHasEndedTurnsTrueOnlyAfterOnEndingCompletes [

	| done processor provider snapshot span tracer |
	provider := OTTracerProvider new.
	processor := OTBlockingOnEndingSpanProcessor new.
	provider spanProcessor: processor.
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	done := Semaphore new.
	[ [ span end ] ensure: [ done signal ] ] forkAt: Processor userBackgroundPriority.
	self assert: (processor waitForOnEndingTimeoutMillis: 1000).
	self assert: span endTime notNil.
	self deny: span hasEnded.
	processor allowOnEnding.
	self assert: (done waitTimeoutMilliseconds: 1000) not.
	self assert: span hasEnded.
	self deny: span isRecording.
	snapshot := OTSpanSnapshot fromSpan: span.
	self assert: snapshot hasEnded.
	self assert: snapshot endTime equals: span endTime
]

{ #category : 'tests' }
OTTracerProviderTest >> testRecordOnlySpanReachesProcessorsButNotExporter [

	| exporter provider recordingProcessor span tracer |
	exporter := OTRecordingSpanExporter new.
	OTSpanExporter current: exporter.
	recordingProcessor := OTRecordingSpanProcessor new.
	provider := OTTracerProvider new.
	provider
		spanProcessor: recordingProcessor;
		addSpanProcessor: OTSimpleSpanProcessor new;
		sampler: (OTSamplingResultSampler result: OTSamplingResult recordOnly).
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	self assert: span isRecording.
	self deny: span spanContext isSampled.
	self assert: recordingProcessor startedSpans asArray equals: { span }.
	self assert: recordingProcessor endingSpans isEmpty.
	self assert: recordingProcessor endedSpans isEmpty.
	span end.
	self assert: recordingProcessor endingSpans asArray equals: { span }.
	self assert: recordingProcessor endedSpans asArray equals: { span }.
	self assert: exporter exportedBatches isEmpty
]

{ #category : 'tests' }
OTTracerProviderTest >> testRecordingSpanExportRecordUsesParentSpanContextWithoutLegacyParentId [

	| exportRecord parentSpanContext provider snapshot snapshotRecord span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider
		          tracerNamed: 'demo.scope'
		          version: '1.2.3'
		          schemaUrl: 'https://opentelemetry.io/schemas/1.0.0'
		          attributes: self sampleAttributes.
	parentSpanContext := OTSpanContext
		                     traceId: '12345678876543211234567887654321'
		                     spanId: 'bbbbbbbbbbbbbbbb'
		                     traceFlags: '01'
		                     traceState: 'vendor=value'
		                     remote: true.
	span := (tracer spanBuilderNamed: 'operation')
		        inContext: (OTContext new withSpan: parentSpanContext asNonRecordingSpan);
		        startSpan.
	exportRecord := span asExportRecord.
	snapshot := OTSpanSnapshot fromSpan: span.
	snapshotRecord := snapshot asExportRecord.
	self assert: (exportRecord at: #parentSpanContext) equals: parentSpanContext.
	self assert: (exportRecord at: #instrumentationScope) equals: tracer instrumentationScope.
	self deny: (exportRecord includesKey: #parentId).
	self deny: (exportRecord includesKey: #instrumentationName).
	self assert: (snapshotRecord at: #parentSpanContext) equals: parentSpanContext.
	self assert: (snapshotRecord at: #instrumentationScope) equals: tracer instrumentationScope.
	self deny: (snapshotRecord includesKey: #parentId).
	self deny: (snapshotRecord includesKey: #instrumentationName)
]

{ #category : 'tests' }
OTTracerProviderTest >> testRecordingSpanExposesReadableSpanSurface [

	| linkContext parentSpanContext provider resource snapshot span startTimestamp tracer |
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
	parentSpanContext := OTSpanContext
		                     traceId: '12345678876543211234567887654321'
		                     spanId: 'bbbbbbbbbbbbbbbb'
		                     traceFlags: '01'
		                     traceState: 'vendor=value'
		                     remote: true.
	linkContext := OTSpanContext
		               traceId: '11111111111111111111111111111111'
		               spanId: '2222222222222222'
		               traceFlags: '01'
		               traceState: 'link=value'
		               remote: true.
	startTimestamp := DateAndTime unixEpoch + (Duration milliSeconds: 1).
	span := (tracer spanBuilderNamed: 'operation')
		        kind: OTSpan client;
		        inContext: (OTContext new withSpan: parentSpanContext asNonRecordingSpan);
		        startTimestamp: startTimestamp;
		        startSpan.
	span
		attributeAt: 'db.system' put: 'sqlite';
		addEventNamed: 'tick';
		addLinkSpanContext: linkContext;
		setStatus: OTSpan error description: 'boom'.
	snapshot := OTSpanSnapshot fromSpan: span.
	self assert: span name equals: 'operation'.
	self assert: span kind equals: OTSpan client.
	self assert: span startTime equals: startTimestamp.
	self assert: span endTime equals: nil.
	self deny: span hasEnded.
	self assert: span traceId equals: parentSpanContext traceId.
	self assert: span spanId equals: span spanContext spanId.
	self assert: span traceFlags equals: span spanContext traceFlags.
	self assert: span traceState equals: span spanContext traceState.
	self assert: span parentSpanContext equals: parentSpanContext.
	self assert: (span attributes at: 'db.system') equals: 'sqlite'.
	self assert: span events size equals: 1.
	self assert: span events first name equals: 'tick'.
	self assert: span links size equals: 1.
	self assert: span links first spanContext equals: linkContext.
	self assert: span status equals: OTSpan error.
	self assert: span statusDescription equals: 'boom'.
	self assert: span droppedAttributesCount equals: 0.
	self assert: span droppedEventsCount equals: 0.
	self assert: span droppedLinksCount equals: 0.
	self assert: span resource equals: resource.
	self assert: span instrumentationName equals: 'demo.scope'.
	self assert: span instrumentationVersion equals: '1.2.3'.
	self assert: span instrumentationScope equals: tracer instrumentationScope.
	self should: [ span instrumentationLibrary ] raise: MessageNotUnderstood.
	self assert: snapshot name equals: span name.
	self assert: snapshot kind equals: span kind.
	self assert: snapshot startTime equals: span startTime.
	self assert: snapshot endTime equals: span endTime.
	self deny: snapshot hasEnded.
	self assert: snapshot parentSpanContext equals: parentSpanContext.
	self assert: (snapshot attributes at: 'db.system') equals: 'sqlite'.
	self assert: snapshot events size equals: 1.
	self assert: snapshot links size equals: 1.
	self assert: snapshot status equals: OTSpan error.
	self assert: snapshot statusDescription equals: 'boom'.
	self assert: snapshot resource equals: resource.
	self assert: snapshot instrumentationName equals: 'demo.scope'.
	self assert: snapshot instrumentationVersion equals: '1.2.3'.
	self assert: snapshot instrumentationScope equals: span instrumentationScope.
	self should: [ snapshot instrumentationLibrary ] raise: MessageNotUnderstood
]

{ #category : 'tests' }
OTTracerProviderTest >> testRecordingSpanInheritsProviderResourceAndScope [

	| exportRecord provider resource scope snapshot span tracer |
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
	exportRecord := span asExportRecord.
	scope := exportRecord at: #instrumentationScope.
	snapshot := OTSpanSnapshot fromSpan: span.
	self assert: span resource equals: resource.
	self assert: span instrumentationScope equals: scope.
	self assert: span instrumentationName equals: 'demo.scope'.
	self assert: span instrumentationVersion equals: '1.2.3'.
	self assert: snapshot resource equals: resource.
	self assert: snapshot instrumentationScope equals: scope.
	self assert: snapshot instrumentationName equals: 'demo.scope'.
	self assert: snapshot instrumentationVersion equals: '1.2.3'.
	self assert: (exportRecord at: #resource) equals: resource.
	self assert: scope name equals: 'demo.scope'.
	self assert: scope version equals: '1.2.3'.
	self assert: scope schemaUrl equals: 'https://opentelemetry.io/schemas/1.0.0'.
	self assert: (scope attributeAt: 'scope.answer') equals: 42
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
OTTracerProviderTest >> testReplacingSpanProcessorsShutsDownRemovedProcessors [

	| firstProcessor provider retainedProcessor secondProcessor span tracer |
	provider := OTTracerProvider new.
	firstProcessor := OTFailingSpanProcessor new.
	retainedProcessor := OTFailingSpanProcessor new.
	provider spanProcessors: {
			firstProcessor.
			retainedProcessor }.
	tracer := provider tracerNamed: 'demo.scope'.
	secondProcessor := OTFailingSpanProcessor new.
	provider spanProcessors: {
			retainedProcessor.
			secondProcessor }.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	span end.
	self assert: firstProcessor shutdownCount equals: 1.
	self assert: retainedProcessor shutdownCount equals: 0.
	self assert: secondProcessor shutdownCount equals: 0.
	self assert: firstProcessor startedSpans isEmpty.
	self assert: firstProcessor endingSpans isEmpty.
	self assert: firstProcessor endedSpans isEmpty.
	self assert: retainedProcessor startedSpans asArray equals: { span }.
	self assert: retainedProcessor endingSpans asArray equals: { span }.
	self assert: retainedProcessor endedSpans asArray equals: { span }.
	self assert: secondProcessor startedSpans asArray equals: { span }.
	self assert: secondProcessor endingSpans asArray equals: { span }.
	self assert: secondProcessor endedSpans asArray equals: { span }
]

{ #category : 'tests' }
OTTracerProviderTest >> testReplacingSpanProcessorsSuppressesShutdownFailureAndStillUsesReplacement [

	self withSpanProcessorWarningsDo: [ :warnings |
			| failingProcessor provider replacementProcessor span tracer |
			provider := OTTracerProvider new.
			failingProcessor := OTFailingSpanProcessor failingOperations: { 'shutdown' }.
			provider spanProcessor: failingProcessor.
			tracer := provider tracerNamed: 'demo.scope'.
			replacementProcessor := OTFailingSpanProcessor new.
			provider spanProcessor: replacementProcessor.
			span := (tracer spanBuilderNamed: 'operation') startSpan.
			span end.
			self assert: replacementProcessor startedSpans asArray equals: { span }.
			self assert: replacementProcessor endingSpans asArray equals: { span }.
			self assert: replacementProcessor endedSpans asArray equals: { span }.
			self
				assert: warnings asArray
				equals: { 'OpenTelemetry span processor callback failed during shutdown for OTFailingSpanProcessor: processor failure' } ]
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
OTTracerProviderTest >> testShutdownFlushesPendingBatchProcessorSpans [

	| exporter provider span tracer |
	exporter := OTRecordingSpanExporter new.
	OTSpanExporter current: exporter.
	provider := OTTracerProvider new.
	provider spanProcessor: (OTBatchSpanProcessor new
			 exporter: exporter;
			 batchSize: 10;
			 scheduledDelayMillis: 1000;
			 yourself).
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	span end.
	self assert: provider shutdown.
	self assert: exporter exportedBatches size equals: 1.
	self assert: exporter exportedBatches first size equals: 1.
	self assert: exporter forceFlushCount equals: 1.
	self assert: exporter shutdownCount equals: 1
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
OTTracerProviderTest >> testSpanEndUsesSpanProcessorOnEndLifecycle [

	| exportRecord processor provider span tracer |
	provider := OTTracerProvider new.
	processor := OTRecordingSpanProcessor new.
	provider spanProcessor: processor.
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	span end.
	exportRecord := span asExportRecord.
	self assert: processor endingSpans asArray equals: { span }.
	self assert: processor endedSpans asArray equals: { span }.
	self deny: span isRecording.
	self assert: ((exportRecord at: #attributes) at: 'processor.onEnding') equals: true
]

{ #category : 'tests' }
OTTracerProviderTest >> testSpanProcessorFailureInvokesDiagnosticErrorHandler [

	| handled provider span |
	handled := OrderedCollection new.
	OTDiagnosticLogger current: (OTDiagnosticLogger new
			 errorHandler: [ :error :message |
					 handled add: {
								 error messageText.
								 message } ];
			 yourself).
	provider := OTTracerProvider new.
	provider addSpanProcessor: (OTFailingSpanProcessor failingOperations: { 'onStart' }).
	span := provider recordingSpanIn: OTContext new parent: nil instrumentationScope: (OTInstrumentationScope named: 'demo.scope').
	provider processStartedSpan: span parentContext: OTContext new.

	self
		assert: handled asArray
		equals:
		{ { 'processor failure'. 'OpenTelemetry span processor callback failed during onStart for OTFailingSpanProcessor: processor failure' } }
]

{ #category : 'tests' }
OTTracerProviderTest >> testSpanProcessorsDoNotReceiveNonRecordingSpans [

	| processor provider span tracer |
	provider := OTTracerProvider new.
	processor := OTRecordingSpanProcessor new.
	provider
		spanProcessor: processor;
		sampler: OTAlwaysOffSampler new.
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	self assert: span class identicalTo: OTNonRecordingSpan.
	self assert: processor startedSpans isEmpty.
	self assert: processor endingSpans isEmpty.
	self assert: processor endedSpans isEmpty.
	span end.
	self assert: processor startedSpans isEmpty.
	self assert: processor endingSpans isEmpty.
	self assert: processor endedSpans isEmpty
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
OTTracerProviderTest >> testTracerEnabledIsFalseWithoutProcessors [

	| provider tracer |
	provider := OTTracerProvider new.
	tracer := provider tracerNamed: 'demo.scope'.
	self deny: tracer enabled
]

{ #category : 'tests' }
OTTracerProviderTest >> testTracerLookupDuringShutdownBehavesAsNoop [

	| done processor provider shutdownResult span |
	provider := OTTracerProvider new.
	processor := OTBlockingShutdownSpanProcessor new.
	provider spanProcessor: processor.
	done := Semaphore new.
	[
		shutdownResult := provider shutdown.
		done signal ] forkAt: Processor userBackgroundPriority.
	self assert: (processor waitForShutdownTimeoutMillis: 200).
	span := (provider tracerNamed: 'demo.scope') startSpanNamed: 'operation' in: OTContext new.
	self assert: span class identicalTo: OTNonRecordingSpan.
	self deny: span spanContext isValid.
	processor allowShutdown.
	self assert: (done waitTimeoutMilliseconds: 200) not.
	self assert: shutdownResult
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
OTTracerProviderTest >> testTracerNamedInvalidScopeAttributesReturnWorkingTracerWithWarning [

	self withTracerConfigurationWarningsDo: [ :warnings |
		| provider tracer |
		provider := OTTracerProvider new.
		provider spanProcessor: OTSimpleSpanProcessor new.
		tracer := nil.
		self
			shouldnt: [
				tracer := provider
					          tracerNamed: 'demo.scope'
					          version: 42
					          schemaUrl: 7
					          attributes: 42 ]
			raise: Error.
		self assert: tracer instrumentationName equals: 'demo.scope'.
		self assert: tracer instrumentationVersion equals: '42'.
		self assert: tracer schemaUrl equals: '7'.
		self assert: tracer scopeAttributes isEmpty.
		self assert: warnings size equals: 1.
		self assert: warnings first equals:
			'OpenTelemetry tracer scope attributes were invalid and have been ignored: 42 (OpenTelemetry attributes must be provided as a dictionary or a collection of associations)' ]
]

{ #category : 'tests' }
OTTracerProviderTest >> testTracerRetrievedAfterShutdownBehavesAsNoopTracer [

	| parentSpan processor provider span tracer tracerAfterShutdown |
	provider := OTTracerProvider new.
	processor := OTRecordingSpanProcessor new.
	provider spanProcessor: processor.
	tracer := provider tracerNamed: 'demo.scope'.
	parentSpan := (tracer spanBuilderNamed: 'parent') startSpan.
	self assert: provider shutdown.
	tracerAfterShutdown := provider tracerNamed: 'after.shutdown'.
	self assert: tracerAfterShutdown class identicalTo: OTNoopTracer.
	self assert: (tracerAfterShutdown spanBuilderNamed: 'child') class identicalTo: OTNoopSpanBuilder.
	self deny: tracerAfterShutdown enabled.
	span := (tracerAfterShutdown spanBuilderNamed: 'child')
		        inContext: (OTContext new withSpan: parentSpan);
		        startSpan.
	self assert: span class identicalTo: OTNonRecordingSpan.
	self deny: span isRecording.
	self assert: span spanContext traceId equals: parentSpan spanContext traceId.
	self assert: processor startedSpans asArray equals: { parentSpan }
]

{ #category : 'tests' }
OTTracerProviderTest >> testTracerRetrievedAfterShutdownCanIgnoreImplicitParentWithNoParent [

	| parentSpan provider rootSpan tracer tracerAfterShutdown |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	parentSpan := (tracer spanBuilderNamed: 'parent') startSpan.
	self assert: provider shutdown.
	tracerAfterShutdown := provider tracerNamed: 'after.shutdown'.
	OpenTelemetry useSpan: parentSpan during: [
			rootSpan := (tracerAfterShutdown spanBuilderNamed: 'root')
				            noParent;
				            startSpan ].
	self assert: rootSpan class identicalTo: OTNonRecordingSpan.
	self deny: rootSpan spanContext isValid
]

{ #category : 'tests' }
OTTracerProviderTest >> testTracerRetrievedAfterShutdownNoopSpanPreservesInstrumentationScope [

	| provider span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	self assert: provider shutdown.
	tracer := provider
		          tracerNamed: 'after.shutdown'
		          version: '1.2.3'
		          schemaUrl: 'https://opentelemetry.io/schemas/1.0.0'
		          attributes: self sampleAttributes.
	span := (tracer spanBuilderNamed: 'child') startSpan.
	self assert: span class identicalTo: OTNonRecordingSpan.
	self assert: span instrumentationScope equals: tracer instrumentationScope
]

{ #category : 'tests' }
OTTracerProviderTest >> testTracerRetrievedAfterShutdownWithNonRecordingParentPreservesScopeAndReturnsFreshSpan [

	| parentSpan provider span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	self assert: provider shutdown.
	tracer := provider
		          tracerNamed: 'after.shutdown'
		          version: '1.2.3'
		          schemaUrl: 'https://opentelemetry.io/schemas/1.0.0'
		          attributes: self sampleAttributes.
	parentSpan := (OTSpanContext
		               traceId: '00112233445566778899aabbccddeeff'
		               spanId: '1122334455667788'
		               traceFlags: '03'
		               traceState: 'vendor=value'
		               remote: true) asNonRecordingSpan.
	span := (tracer spanBuilderNamed: 'child')
		        inContext: (OTContext new withSpan: parentSpan);
		        startSpan.
	self assert: span identicalTo: parentSpan
]

{ #category : 'tests' }
OTTracerProviderTest >> testTracerWithoutProcessorsStartsNonRecordingSpan [

	| provider span tracer |
	provider := OTTracerProvider new.
	tracer := provider tracerNamed: 'demo.scope'.
	self deny: tracer enabled.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	self assert: span class identicalTo: OTNonRecordingSpan.
	self deny: span isRecording.
	self deny: span spanContext isValid
]

{ #category : 'tests' }
OTTracerProviderTest >> testTracerWithoutProcessorsStillReturnsRecordingSpan [

	| provider span |
	provider := OTTracerProvider new.
	span := (provider tracerNamed: 'demo.scope') startSpanNamed: 'operation' in: OTContext new.
	self assert: span class identicalTo: OTNonRecordingSpan.
	self deny: span isRecording.
	self deny: span spanContext isValid.
	self assert: span instrumentationName equals: 'demo.scope'
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
OTTracerProviderTest >> withSpanProcessorWarningsDo: aBlock [

	| warnings |
	warnings := OrderedCollection new.
	OTTracerProvider spanProcessorWarningSink: [ :message | warnings add: message ].
	[
		^ aBlock value: warnings ]
		ensure: [ OTTracerProvider spanProcessorWarningSink: nil ]
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
