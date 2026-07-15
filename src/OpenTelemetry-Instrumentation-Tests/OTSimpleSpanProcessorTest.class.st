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
		(exporter isKindOf: OTBlockingSpanExporter) ifTrue: [
			exporter allowBlockedExport ].
		processor ifNotNil: [ processor shutdown ].
		exporter ifNotNil: [ exporter shutdown ].
		OTSpanExporter current: nil ]
		ensure: [ super tearDown ]
]

{ #category : 'tests' }
OTSimpleSpanProcessorTest >> testProcessExportsSampledSpan [

	exporter := OTRecordingSpanExporter new.
	OTSpanExporter current: exporter.
	processor := OTSimpleSpanProcessor new.
	self assert: (processor process: (self sampledSpanWithSuffix: 1)).
	self assert: exporter exportedBatches size equals: 1.
	self assert: exporter exportedBatches first size equals: 1
]

{ #category : 'tests' }
OTSimpleSpanProcessorTest >> testProcessUsesExplicitExporterInsteadOfGlobalExporter [

	| globalExporter |
	exporter := OTRecordingSpanExporter new.
	globalExporter := OTRecordingSpanExporter new.
	OTSpanExporter current: globalExporter.
	processor := OTSimpleSpanProcessor new exporter: exporter.
	self assert: (processor process: (self sampledSpanWithSuffix: 1)).
	self assert: exporter exportedBatches size equals: 1.
	self assert: globalExporter exportedBatches isEmpty
]

{ #category : 'tests' }
OTSimpleSpanProcessorTest >> testProcessSerializesConcurrentExports [

	| secondExportFinished |
	exporter := OTBlockingSpanExporter new.
	exporter blockNextExport.
	OTSpanExporter current: exporter.
	processor := OTSimpleSpanProcessor new.
	secondExportFinished := Semaphore new.
	[ processor process: (self sampledSpanWithSuffix: 1) ] forkAt: Processor userBackgroundPriority.
	self assert: (exporter waitForBlockedExportTimeoutMillis: 200).
	[
		processor process: (self sampledSpanWithSuffix: 2).
		secondExportFinished signal ]
		forkAt: Processor userBackgroundPriority.
	self assert: (secondExportFinished waitTimeoutMilliseconds: 50).
	exporter allowBlockedExport.
	self waitUntil: [ exporter exportedBatches size = 2 ] timeoutMillis: 500
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
