Class {
	#name : 'OTBatchSpanProcessorTest',
	#superclass : 'TestCase',
	#instVars : [
		'exporter',
		'processor'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'private' }
OTBatchSpanProcessorTest >> sampledSpanWithSuffix: anInteger [

	| suffix |
	suffix := (anInteger printStringBase: 16 length: 2 padded: true) asLowercase.
	^ (OTSpanContext
		traceId: '00112233445566778899aabbccddee' , suffix
		spanId: '11223344556677' , suffix
		traceFlags: '01'
		traceState: nil
		remote: false) asNonRecordingSpan
]

{ #category : 'running' }
OTBatchSpanProcessorTest >> setUp [

	super setUp.
	OTSpanProcessor current: nil.
	OTSpanExporter current: nil
]

{ #category : 'running' }
OTBatchSpanProcessorTest >> tearDown [

	[
		(exporter isKindOf: OTBlockingSpanExporter) ifTrue: [ exporter allowBlockedExport ].
		(exporter isKindOf: OTBlockingForceFlushSpanExporter) ifTrue: [ exporter allowForceFlush ].
		(exporter isKindOf: OTBlockingShutdownSpanExporter) ifTrue: [ exporter allowShutdown ].
		processor ifNotNil: [ processor shutdown ].
		exporter ifNotNil: [ exporter shutdown ].
		OTSpanProcessor current: nil.
		OTSpanExporter current: nil ] ensure: [ super tearDown ]
]

{ #category : 'tests' }
OTBatchSpanProcessorTest >> testBeCurrentHandlesMissingCurrentProcessor [

	processor := OTBatchSpanProcessor beCurrent.
	self assert: processor class identicalTo: OTBatchSpanProcessor
]

{ #category : 'tests' }
OTBatchSpanProcessorTest >> testConcurrentShutdownIsIdempotent [

	| firstDone firstResult secondDone secondResult |
	exporter := OTBlockingShutdownSpanExporter new.
	OTSpanExporter current: exporter.
	processor := OTBatchSpanProcessor new.
	firstDone := Semaphore new.
	secondDone := Semaphore new.
	[
		firstResult := processor shutdown.
		firstDone signal ] forkAt: Processor userBackgroundPriority.
	self assert: (exporter waitForShutdownTimeoutMillis: 200).
	[
		secondResult := processor shutdown.
		secondDone signal ] forkAt: Processor userBackgroundPriority.
	self assert: (secondDone waitTimeoutMilliseconds: 200) not.
	self deny: secondResult.
	exporter allowShutdown.
	self assert: (firstDone waitTimeoutMilliseconds: 200) not.
	self assert: firstResult.
	self assert: processor isShutdown
]

{ #category : 'tests' }
OTBatchSpanProcessorTest >> testForceFlushExportsPendingBatchAndForwardsToExporter [

	exporter := OTRecordingSpanExporter new.
	OTSpanExporter current: exporter.
	processor := OTBatchSpanProcessor new.
	processor
		batchSize: 10;
		scheduledDelayMillis: 1000.
	self assert: (processor onEnd: (self sampledSpanWithSuffix: 1)).
	self assert: processor forceFlush.
	self assert: exporter exportedBatches size equals: 1.
	self assert: exporter forceFlushCount equals: 1.
	self assert: exporter exportedBatches first size equals: 1.
	self assert: exporter exportedBatches first first class identicalTo: OTSpanSnapshot
]

{ #category : 'tests' }
OTBatchSpanProcessorTest >> testForceFlushHonorsExportTimeoutWhenExporterForceFlushIsBlocked [

	| elapsed startedAt |
	exporter := OTBlockingForceFlushSpanExporter new.
	OTSpanExporter current: exporter.
	processor := OTBatchSpanProcessor new.
	processor exportTimeoutMillis: 25.
	startedAt := Time millisecondClockValue.
	self deny: processor forceFlush.
	elapsed := Time millisecondClockValue - startedAt.
	self assert: elapsed < 250.
	self assert: (exporter waitForForceFlushTimeoutMillis: 200)
]

{ #category : 'tests' }
OTBatchSpanProcessorTest >> testForceFlushReturnsFalseAfterShutdown [

	exporter := OTRecordingSpanExporter new.
	OTSpanExporter current: exporter.
	processor := OTBatchSpanProcessor new.
	processor
		batchSize: 10;
		scheduledDelayMillis: 1000.
	self assert: processor shutdown.
	self deny: processor forceFlush.
	self assert: exporter forceFlushCount equals: 1.
	self assert: exporter shutdownCount equals: 1
]

{ #category : 'tests' }
OTBatchSpanProcessorTest >> testForceFlushUsesExplicitExporterInsteadOfGlobalExporter [

	| globalExporter |
	exporter := OTRecordingSpanExporter new.
	globalExporter := OTRecordingSpanExporter new.
	OTSpanExporter current: globalExporter.
	processor := OTBatchSpanProcessor new exporter: exporter.
	processor
		batchSize: 10;
		scheduledDelayMillis: 1000.
	self assert: (processor onEnd: (self sampledSpanWithSuffix: 1)).
	self assert: processor forceFlush.
	self assert: exporter exportedBatches size equals: 1.
	self assert: globalExporter exportedBatches isEmpty
]

{ #category : 'tests' }
OTBatchSpanProcessorTest >> testInvalidRuntimeConfigurationValuesAreIgnoredAndWarned [

	exporter := OTRecordingSpanExporter new.
	processor := OTBatchSpanProcessor new exporter: exporter.
	processor
		batchSize: 1;
		maxQueueSize: 4;
		scheduledDelayMillis: 20;
		exportTimeoutMillis: 25.
	self withConfigurationWarningsDo: [ :warnings |
			processor
				batchSize: 0;
				maxQueueSize: 'x';
				scheduledDelayMillis: 'x';
				exportTimeoutMillis: -1;
				exporter: 42.
			self assert: processor batchSize equals: 1.
			self assert: processor maxQueueSize equals: 4.
			self assert: processor scheduledDelayMillis equals: 20.
			self assert: processor exportTimeoutMillis equals: 25.
			self assert: processor exporter identicalTo: exporter.
			self assert: (processor onEnd: (self sampledSpanWithSuffix: 1)).
			self assert: processor forceFlush.
			self assert: exporter exportedBatches size equals: 1.
			self
				assert: warnings asArray
				equals: { 'OpenTelemetry span processor configuration was invalid and has been ignored for ''batchSize:'': 0'.
					'OpenTelemetry span processor configuration was invalid and has been ignored for ''maxQueueSize:'': ''x'''.
					'OpenTelemetry span processor configuration was invalid and has been ignored for ''scheduledDelayMillis:'': ''x'''.
					'OpenTelemetry span processor configuration was invalid and has been ignored for ''exportTimeoutMillis:'': -1'.
					'OpenTelemetry span processor configuration was invalid and has been ignored for ''exporter:'': 42' } ]
]

{ #category : 'tests' }
OTBatchSpanProcessorTest >> testOnEndAcceptsRecordOnlySpanWithoutExporting [

	| provider span tracer |
	exporter := OTRecordingSpanExporter new.
	OTSpanExporter current: exporter.
	processor := OTBatchSpanProcessor new.
	processor
		batchSize: 1;
		scheduledDelayMillis: 1000.
	provider := OTTracerProvider new.
	provider
		spanProcessor: OTRecordingSpanProcessor new;
		sampler: (OTSamplingResultSampler result: OTSamplingResult recordOnly).
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	self assert: span isRecording.
	self deny: span spanContext isSampled.
	span end.
	self assert: (processor onEnd: span).
	self assert: exporter exportedBatches isEmpty
]

{ #category : 'tests' }
OTBatchSpanProcessorTest >> testOnEndAfterShutdownIsIgnoredWithoutExporting [

	exporter := OTRecordingSpanExporter new.
	OTSpanExporter current: exporter.
	processor := OTBatchSpanProcessor new.
	processor
		batchSize: 10;
		scheduledDelayMillis: 1000.
	self assert: processor shutdown.
	self deny: (processor onEnd: (self sampledSpanWithSuffix: 1)).
	self assert: exporter exportedBatches isEmpty.
	self assert: exporter shutdownCount equals: 1
]

{ #category : 'tests' }
OTBatchSpanProcessorTest >> testOnEndDropsSpansWhenQueueFillsDuringBlockedExport [

	exporter := OTBlockingSpanExporter new.
	exporter blockNextExport.
	OTSpanExporter current: exporter.
	processor := OTBatchSpanProcessor new.
	processor
		batchSize: 1;
		maxQueueSize: 2;
		scheduledDelayMillis: 1000.
	self assert: (processor onEnd: (self sampledSpanWithSuffix: 1)).
	self assert: (exporter waitForBlockedExportTimeoutMillis: 200).
	self assert: (processor onEnd: (self sampledSpanWithSuffix: 2)).
	self assert: (processor onEnd: (self sampledSpanWithSuffix: 3)).
	self deny: (processor onEnd: (self sampledSpanWithSuffix: 4)).
	exporter allowBlockedExport.
	self waitUntil: [ exporter exportedBatches size = 3 ] timeoutMillis: 500.
	self assert: (exporter exportedBatches inject: 0 into: [ :total :each | total + each size ]) equals: 3
]

{ #category : 'tests' }
OTBatchSpanProcessorTest >> testOnEndReturnsBeforeBlockedBatchExportCompletes [

	exporter := OTBlockingSpanExporter new.
	exporter blockNextExport.
	OTSpanExporter current: exporter.
	processor := OTBatchSpanProcessor new.
	processor
		batchSize: 1;
		scheduledDelayMillis: 1000.
	self assert: (processor onEnd: (self sampledSpanWithSuffix: 1)).
	self assert: (exporter waitForBlockedExportTimeoutMillis: 200).
	self assert: exporter exportedBatches isEmpty.
	exporter allowBlockedExport.
	self waitUntil: [ exporter exportedBatches size = 1 ] timeoutMillis: 500
]

{ #category : 'tests' }
OTBatchSpanProcessorTest >> testOnEndThatPassedInitialCheckIsIgnoredAfterShutdownCompletes [

	| done onEndResult shutdownResult |
	exporter := OTRecordingSpanExporter new.
	OTSpanExporter current: exporter.
	processor := OTHookedBatchSpanProcessor new.
	processor
		batchSize: 10;
		scheduledDelayMillis: 1000.
	done := Semaphore new.
	[
		onEndResult := processor onEnd: (self sampledSpanWithSuffix: 1).
		done signal ] forkAt: Processor userBackgroundPriority.
	self assert: (processor waitForOnEndHookTimeoutMillis: 200) not.
	shutdownResult := processor shutdown.
	processor allowOnEndToContinue.
	self assert: (done waitTimeoutMilliseconds: 200) not.
	self assert: shutdownResult.
	self deny: onEndResult.
	self assert: exporter exportedBatches isEmpty.
	self assert: exporter forceFlushCount equals: 1.
	self assert: exporter shutdownCount equals: 1
]

{ #category : 'tests' }
OTBatchSpanProcessorTest >> testScheduledDelayFlushesPendingBatch [

	exporter := OTRecordingSpanExporter new.
	OTSpanExporter current: exporter.
	processor := OTBatchSpanProcessor new.
	processor
		batchSize: 10;
		scheduledDelayMillis: 20.
	self assert: (processor onEnd: (self sampledSpanWithSuffix: 1)).
	self waitUntil: [ exporter exportedBatches size = 1 ] timeoutMillis: 500.
	self assert: exporter exportedBatches first size equals: 1
]

{ #category : 'tests' }
OTBatchSpanProcessorTest >> testShutdownFlushesPendingBatchAndShutsDownExporter [

	exporter := OTRecordingSpanExporter new.
	OTSpanExporter current: exporter.
	processor := OTBatchSpanProcessor new.
	processor
		batchSize: 10;
		scheduledDelayMillis: 1000.
	self assert: (processor onEnd: (self sampledSpanWithSuffix: 1)).
	self assert: processor shutdown.
	self assert: exporter exportedBatches size equals: 1.
	self assert: exporter forceFlushCount equals: 1.
	self assert: exporter shutdownCount equals: 1
]

{ #category : 'tests' }
OTBatchSpanProcessorTest >> testShutdownHonorsExportTimeoutWhenExporterForceFlushIsBlocked [

	| elapsed startedAt |
	exporter := OTBlockingForceFlushSpanExporter new.
	OTSpanExporter current: exporter.
	processor := OTBatchSpanProcessor new.
	processor exportTimeoutMillis: 25.
	startedAt := Time millisecondClockValue.
	self deny: processor shutdown.
	elapsed := Time millisecondClockValue - startedAt.
	self assert: elapsed < 250.
	self assert: (exporter waitForForceFlushTimeoutMillis: 200).
	self assert: exporter shutdownCount equals: 1.
	self assert: processor isShutdown
]

{ #category : 'tests' }
OTBatchSpanProcessorTest >> testShutdownHonorsExportTimeoutWhenExporterShutdownIsBlocked [

	| elapsed startedAt |
	exporter := OTBlockingShutdownSpanExporter new.
	OTSpanExporter current: exporter.
	processor := OTBatchSpanProcessor new.
	processor
		batchSize: 10;
		exportTimeoutMillis: 25;
		scheduledDelayMillis: 1000.
	self assert: (processor onEnd: (self sampledSpanWithSuffix: 1)).
	startedAt := Time millisecondClockValue.
	self deny: processor shutdown.
	elapsed := Time millisecondClockValue - startedAt.
	self assert: elapsed < 250.
	self assert: exporter forceFlushCount equals: 1.
	self assert: (exporter waitForShutdownTimeoutMillis: 200).
	self assert: exporter exportedBatches size equals: 1.
	self assert: processor isShutdown
]

{ #category : 'private' }
OTBatchSpanProcessorTest >> waitUntil: aBlock timeoutMillis: anInteger [

	| deadline |
	deadline := Time millisecondClockValue + anInteger.
	[
		aBlock value ifTrue: [ ^ self ].
		Time millisecondClockValue >= deadline ]
		whileFalse: [ (Delay forMilliseconds: 10) wait ].
	self fail: 'Timed out waiting for background batch export'
]

{ #category : 'private' }
OTBatchSpanProcessorTest >> withConfigurationWarningsDo: aBlock [

	| warnings |
	warnings := OrderedCollection new.
	OTSpanProcessor configurationWarningSink: [ :message | warnings add: message ].
	[ ^ aBlock value: warnings ] ensure: [ OTSpanProcessor configurationWarningSink: nil ]
]
