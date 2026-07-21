Class {
	#name : 'OTSimpleSpanProcessorTest',
	#superclass : 'TestCase',
	#instVars : [
		'exporter',
		'processor'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'private' }
OTSimpleSpanProcessorTest >> sampledSpanWithSuffix: anInteger [

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
OTSimpleSpanProcessorTest >> setUp [

	super setUp.
	OTSpanExporter current: nil
]

{ #category : 'running' }
OTSimpleSpanProcessorTest >> tearDown [

	[
		(exporter isKindOf: OTBlockingSpanExporter) ifTrue: [ exporter allowBlockedExport ].
		(exporter isKindOf: OTBlockingShutdownSpanExporter) ifTrue: [ exporter allowShutdown ].
		processor ifNotNil: [ processor shutdown ].
		exporter ifNotNil: [ exporter shutdown ].
		OTSpanExporter current: nil ] ensure: [ super tearDown ]
]

{ #category : 'tests' }
OTSimpleSpanProcessorTest >> testConcurrentShutdownIsIdempotent [

	| firstDone firstResult secondDone secondResult |
	exporter := OTBlockingShutdownSpanExporter new.
	OTSpanExporter current: exporter.
	processor := OTSimpleSpanProcessor new.
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
OTSimpleSpanProcessorTest >> testForceFlushReturnsFalseAfterShutdown [

	exporter := OTRecordingSpanExporter new.
	OTSpanExporter current: exporter.
	processor := OTSimpleSpanProcessor new.
	self assert: processor shutdown.
	self deny: processor forceFlush.
	self assert: exporter forceFlushCount equals: 1.
	self assert: exporter shutdownCount equals: 1
]

{ #category : 'tests' }
OTSimpleSpanProcessorTest >> testForceFlushReturnsFalseWhileShutdownIsInProgress [

	| done shutdownResult |
	exporter := OTBlockingShutdownSpanExporter new.
	OTSpanExporter current: exporter.
	processor := OTSimpleSpanProcessor new.
	done := Semaphore new.
	[
		shutdownResult := processor shutdown.
		done signal ] forkAt: Processor userBackgroundPriority.
	self assert: (exporter waitForShutdownTimeoutMillis: 200).
	self deny: processor forceFlush.
	exporter allowShutdown.
	self assert: (done waitTimeoutMilliseconds: 200) not.
	self assert: shutdownResult
]

{ #category : 'tests' }
OTSimpleSpanProcessorTest >> testOnEndAcceptsRecordOnlySpanWithoutExporting [

	| provider span tracer |
	exporter := OTRecordingSpanExporter new.
	OTSpanExporter current: exporter.
	processor := OTSimpleSpanProcessor new.
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
OTSimpleSpanProcessorTest >> testOnEndAfterShutdownIsIgnoredWithoutExporting [

	exporter := OTRecordingSpanExporter new.
	OTSpanExporter current: exporter.
	processor := OTSimpleSpanProcessor new.
	self assert: processor shutdown.
	self deny: (processor onEnd: (self sampledSpanWithSuffix: 1)).
	self assert: exporter exportedBatches isEmpty.
	self assert: exporter shutdownCount equals: 1
]

{ #category : 'tests' }
OTSimpleSpanProcessorTest >> testOnEndExportsPrintableAndStonSerializableSnapshot [

	| exportedSnapshot printed serialized |
	exporter := OTRecordingSpanExporter new.
	OTSpanExporter current: exporter.
	processor := OTSimpleSpanProcessor new.
	self assert: (processor onEnd: (self sampledSpanWithSuffix: 1)).
	exportedSnapshot := exporter exportedBatches first first.
	printed := exportedSnapshot printString.
	serialized := STON toString: { exportedSnapshot asExportRecord }.
	self assert: (printed beginsWith: 'Span[').
	self assert: (serialized includesSubstring: 'traceId')
]

{ #category : 'tests' }
OTSimpleSpanProcessorTest >> testOnEndExportsSampledSpan [

	exporter := OTRecordingSpanExporter new.
	OTSpanExporter current: exporter.
	processor := OTSimpleSpanProcessor new.
	self assert: (processor onEnd: (self sampledSpanWithSuffix: 1)).
	self assert: exporter exportedBatches size equals: 1.
	self assert: exporter exportedBatches first size equals: 1.
	self assert: exporter exportedBatches first first class identicalTo: OTSpanSnapshot
]

{ #category : 'tests' }
OTSimpleSpanProcessorTest >> testOnEndReturnsFalseWhileShutdownIsInProgress [

	| done shutdownResult |
	exporter := OTBlockingShutdownSpanExporter new.
	OTSpanExporter current: exporter.
	processor := OTSimpleSpanProcessor new.
	done := Semaphore new.
	[
		shutdownResult := processor shutdown.
		done signal ] forkAt: Processor userBackgroundPriority.
	self assert: (exporter waitForShutdownTimeoutMillis: 200).
	self deny: (processor onEnd: (self sampledSpanWithSuffix: 1)).
	self assert: exporter exportedBatches isEmpty.
	exporter allowShutdown.
	self assert: (done waitTimeoutMilliseconds: 200) not.
	self assert: shutdownResult
]

{ #category : 'tests' }
OTSimpleSpanProcessorTest >> testOnEndSerializesConcurrentExports [

	| secondExportFinished |
	exporter := OTBlockingSpanExporter new.
	exporter blockNextExport.
	OTSpanExporter current: exporter.
	processor := OTSimpleSpanProcessor new.
	secondExportFinished := Semaphore new.
	[ processor onEnd: (self sampledSpanWithSuffix: 1) ] forkAt: Processor userBackgroundPriority.
	self assert: (exporter waitForBlockedExportTimeoutMillis: 200).
	[
		processor onEnd: (self sampledSpanWithSuffix: 2).
		secondExportFinished signal ] forkAt: Processor userBackgroundPriority.
	self assert: (secondExportFinished waitTimeoutMilliseconds: 50).
	exporter allowBlockedExport.
	self waitUntil: [ exporter exportedBatches size = 2 ] timeoutMillis: 500
]

{ #category : 'tests' }
OTSimpleSpanProcessorTest >> testOnEndUsesExplicitExporterInsteadOfGlobalExporter [

	| globalExporter |
	exporter := OTRecordingSpanExporter new.
	globalExporter := OTRecordingSpanExporter new.
	OTSpanExporter current: globalExporter.
	processor := OTSimpleSpanProcessor new exporter: exporter.
	self assert: (processor onEnd: (self sampledSpanWithSuffix: 1)).
	self assert: exporter exportedBatches size equals: 1.
	self assert: globalExporter exportedBatches isEmpty
]

{ #category : 'private' }
OTSimpleSpanProcessorTest >> waitUntil: aBlock timeoutMillis: anInteger [

	| deadline |
	deadline := Time millisecondClockValue + anInteger.
	[
		aBlock value ifTrue: [ ^ self ].
		Time millisecondClockValue >= deadline ]
		whileFalse: [ (Delay forMilliseconds: 10) wait ].
	self fail: 'Timed out waiting for simple span processor work'
]
