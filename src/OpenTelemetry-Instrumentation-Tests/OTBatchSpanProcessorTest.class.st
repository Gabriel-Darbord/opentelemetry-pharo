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

{ #category : 'running' }
OTBatchSpanProcessorTest >> setUp [

	super setUp.
	OTSpanProcessor current: nil.
	OTSpanExporter current: nil
]

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
OTBatchSpanProcessorTest >> tearDown [

	[
		(exporter isKindOf: OTBlockingSpanExporter) ifTrue: [
			exporter allowBlockedExport ].
		processor ifNotNil: [ processor shutdown ].
		exporter ifNotNil: [ exporter shutdown ].
		OTSpanProcessor current: nil.
		OTSpanExporter current: nil ]
		ensure: [ super tearDown ]
]

{ #category : 'tests' }
OTBatchSpanProcessorTest >> testBeCurrentHandlesMissingCurrentProcessor [

	processor := OTBatchSpanProcessor beCurrent.
	self assert: processor class identicalTo: OTBatchSpanProcessor
]

{ #category : 'tests' }
OTBatchSpanProcessorTest >> testForceFlushExportsPendingBatchAndForwardsToExporter [

	exporter := OTRecordingSpanExporter new.
	OTSpanExporter current: exporter.
	processor := OTBatchSpanProcessor new.
	processor
		batchSize: 10;
		scheduledDelayMillis: 1000.
	self assert: (processor process: (self sampledSpanWithSuffix: 1)).
	self assert: processor forceFlush.
	self assert: exporter exportedBatches size equals: 1.
	self assert: exporter forceFlushCount equals: 1.
	self assert: exporter exportedBatches first size equals: 1
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
	self assert: (processor process: (self sampledSpanWithSuffix: 1)).
	self assert: processor forceFlush.
	self assert: exporter exportedBatches size equals: 1.
	self assert: globalExporter exportedBatches isEmpty
]

{ #category : 'tests' }
OTBatchSpanProcessorTest >> testProcessDropsSpansWhenQueueFillsDuringBlockedExport [

	exporter := OTBlockingSpanExporter new.
	exporter blockNextExport.
	OTSpanExporter current: exporter.
	processor := OTBatchSpanProcessor new.
	processor
		batchSize: 1;
		maxQueueSize: 2;
		scheduledDelayMillis: 1000.
	self assert: (processor process: (self sampledSpanWithSuffix: 1)).
	self assert: (exporter waitForBlockedExportTimeoutMillis: 200).
	self assert: (processor process: (self sampledSpanWithSuffix: 2)).
	self assert: (processor process: (self sampledSpanWithSuffix: 3)).
	self deny: (processor process: (self sampledSpanWithSuffix: 4)).
	exporter allowBlockedExport.
	self waitUntil: [ exporter exportedBatches size = 3 ] timeoutMillis: 500.
	self
		assert: ((exporter exportedBatches inject: 0 into: [ :total :each | total + each size ]))
		equals: 3
]

{ #category : 'tests' }
OTBatchSpanProcessorTest >> testProcessReturnsBeforeBlockedBatchExportCompletes [

	exporter := OTBlockingSpanExporter new.
	exporter blockNextExport.
	OTSpanExporter current: exporter.
	processor := OTBatchSpanProcessor new.
	processor
		batchSize: 1;
		scheduledDelayMillis: 1000.
	self assert: (processor process: (self sampledSpanWithSuffix: 1)).
	self assert: (exporter waitForBlockedExportTimeoutMillis: 200).
	self assert: exporter exportedBatches isEmpty.
	exporter allowBlockedExport.
	self waitUntil: [ exporter exportedBatches size = 1 ] timeoutMillis: 500
]

{ #category : 'tests' }
OTBatchSpanProcessorTest >> testScheduledDelayFlushesPendingBatch [

	exporter := OTRecordingSpanExporter new.
	OTSpanExporter current: exporter.
	processor := OTBatchSpanProcessor new.
	processor
		batchSize: 10;
		scheduledDelayMillis: 20.
	self assert: (processor process: (self sampledSpanWithSuffix: 1)).
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
	self assert: (processor process: (self sampledSpanWithSuffix: 1)).
	self assert: processor shutdown.
	self assert: exporter exportedBatches size equals: 1.
	self assert: exporter shutdownCount equals: 1
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
