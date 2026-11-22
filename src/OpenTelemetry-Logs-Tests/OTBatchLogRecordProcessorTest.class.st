Class {
	#name : 'OTBatchLogRecordProcessorTest',
	#superclass : 'TestCase',
	#instVars : [
		'exporter',
		'processor'
	],
	#category : 'OpenTelemetry-Logs-Tests',
	#package : 'OpenTelemetry-Logs-Tests'
}

{ #category : 'private' }
OTBatchLogRecordProcessorTest >> sampleLogRecordWithSuffix: anInteger [

	^ OTLogRecord new
		  body: 'log-' , anInteger asString;
		  severityNumber: OTSeverity info;
		  severityText: 'INFO';
		  eventName: 'event.' , anInteger asString;
		  observedTimestamp: DateAndTime now;
		  yourself
]

{ #category : 'running' }
OTBatchLogRecordProcessorTest >> setUp [

	super setUp
]

{ #category : 'running' }
OTBatchLogRecordProcessorTest >> tearDown [

	[
		(exporter isKindOf: OTBlockingLogRecordExporter) ifTrue: [ exporter allowBlockedExport ].
		processor ifNotNil: [ processor shutdown ].
		exporter ifNotNil: [ exporter shutdown ] ] ensure: [ super tearDown ]
]

{ #category : 'tests' }
OTBatchLogRecordProcessorTest >> testAnErrorInAnExportDropsTheBatchAndTheFlushGoesOn [

	| logger warnings |
	warnings := OrderedCollection new.
	logger := OTDiagnosticLogger current.
	OTDiagnosticLogger current: (OTDiagnosticLogger onWarningDo: [ :message | warnings add: message ]).
	exporter := OTFailingOnceLogRecordExporter new.
	exporter failNextExport.
	processor := OTBatchLogRecordProcessor new
		             exporter: exporter;
		             yourself.
	processor
		maxExportBatchSize: 1;
		scheduledDelayMillis: 10.
	[
		processor onEmit: (self sampleLogRecordWithSuffix: 1) context: OTContext new.
		self waitUntil: [ warnings isNotEmpty ] timeoutMillis: 2000.
		self assert: (warnings first includesSubstring: 'flush failed').
		processor onEmit: (self sampleLogRecordWithSuffix: 2) context: OTContext new.
		self waitUntil: [ exporter exportedBatches size = 1 ] timeoutMillis: 2000.
		self assert: exporter exportedBatches first first body equals: 'log-2' ] ensure: [ OTDiagnosticLogger current: logger ]
]

{ #category : 'tests' }
OTBatchLogRecordProcessorTest >> testAnErrorWhileNotingAFailedExportLeavesTheFlushGoing [

	| logger notes |
	notes := 0.
	logger := OTDiagnosticLogger current.
	OTDiagnosticLogger current: (OTDiagnosticLogger new
			 errorHandler: [ :error :message |
					 notes := notes + 1.
					 Error signal: 'noting failed' ];
			 yourself).
	exporter := OTFailingOnceLogRecordExporter new.
	exporter failNextExport.
	processor := OTBatchLogRecordProcessor new
		             exporter: exporter;
		             yourself.
	processor
		maxExportBatchSize: 1;
		scheduledDelayMillis: 10.
	[
		processor onEmit: (self sampleLogRecordWithSuffix: 1) context: OTContext new.
		self waitUntil: [ notes > 0 ] timeoutMillis: 2000.
		processor onEmit: (self sampleLogRecordWithSuffix: 2) context: OTContext new.
		self waitUntil: [ exporter exportedBatches size = 1 ] timeoutMillis: 2000.
		self assert: exporter exportedBatches first first body equals: 'log-2' ] ensure: [ OTDiagnosticLogger current: logger ]
]

{ #category : 'tests' }
OTBatchLogRecordProcessorTest >> testForceFlushExportsPendingBatchAndForwardsToExporter [

	exporter := OTRecordingLogRecordExporter new.
	processor := OTBatchLogRecordProcessor new
		             exporter: exporter;
		             yourself.
	processor
		maxExportBatchSize: 10;
		scheduledDelayMillis: 1000.
	processor onEmit: (self sampleLogRecordWithSuffix: 1) context: OTContext new.
	self assert: processor forceFlush.
	self assert: exporter exportedBatches size equals: 1.
	self assert: exporter forceFlushCount equals: 1.
	self assert: exporter exportedBatches first size equals: 1
]

{ #category : 'tests' }
OTBatchLogRecordProcessorTest >> testOnEmitDropsLogsWhenQueueFillsDuringBlockedExport [

	exporter := OTBlockingLogRecordExporter new.
	exporter blockNextExport.
	processor := OTBatchLogRecordProcessor new
		             exporter: exporter;
		             yourself.
	processor
		maxExportBatchSize: 1;
		maxQueueSize: 2;
		scheduledDelayMillis: 1000.
	processor onEmit: (self sampleLogRecordWithSuffix: 1) context: OTContext new.
	self assert: (exporter waitForBlockedExportTimeoutMillis: 200).
	processor onEmit: (self sampleLogRecordWithSuffix: 2) context: OTContext new.
	processor onEmit: (self sampleLogRecordWithSuffix: 3) context: OTContext new.
	processor onEmit: (self sampleLogRecordWithSuffix: 4) context: OTContext new.
	exporter allowBlockedExport.
	self waitUntil: [ exporter exportedRecords size = 3 ] timeoutMillis: 500.
	self assert: exporter exportedRecords size equals: 3
]

{ #category : 'tests' }
OTBatchLogRecordProcessorTest >> testRecordsEmittedAtOnceStartOneFlushProcess [
	"A process finds that the flush process has ended and is preempted, before it starts another, by one that finds it too."

	| inner outer |
	processor := OTBatchLogRecordProcessor new.
	processor
		instVarNamed: #flushProcess
		put: (OTEndedFlushProcess onCheck: [ [ inner := processor ensureFlushProcess ] forkAt: Processor activePriority + 1 ]).
	[
		outer := processor ensureFlushProcess.
		self waitUntil: [ inner isNotNil ] timeoutMillis: 2000.
		self assert: inner identicalTo: outer ] ensure: [
			{
				inner.
				outer } do: [ :each | each ifNotNil: [ each terminate ] ] ]
]

{ #category : 'tests' }
OTBatchLogRecordProcessorTest >> testScheduledDelayFlushesPendingBatch [

	exporter := OTRecordingLogRecordExporter new.
	processor := OTBatchLogRecordProcessor new
		             exporter: exporter;
		             yourself.
	processor
		maxExportBatchSize: 10;
		scheduledDelayMillis: 20.
	processor onEmit: (self sampleLogRecordWithSuffix: 1) context: OTContext new.
	self waitUntil: [ exporter exportedBatches size = 1 ] timeoutMillis: 500.
	self assert: exporter exportedBatches first size equals: 1
]

{ #category : 'tests' }
OTBatchLogRecordProcessorTest >> testShutdownFlushesPendingBatchAndShutsDownExporter [

	exporter := OTRecordingLogRecordExporter new.
	processor := OTBatchLogRecordProcessor new
		             exporter: exporter;
		             yourself.
	processor
		maxExportBatchSize: 10;
		scheduledDelayMillis: 1000.
	processor onEmit: (self sampleLogRecordWithSuffix: 1) context: OTContext new.
	self assert: processor shutdown.
	self assert: exporter exportedBatches size equals: 1.
	self assert: exporter shutdownCount equals: 1
]

{ #category : 'private' }
OTBatchLogRecordProcessorTest >> waitUntil: aBlock timeoutMillis: anInteger [

	| deadline |
	deadline := Time millisecondClockValue + anInteger.
	[
		aBlock value ifTrue: [ ^ self ].
		Time millisecondClockValue >= deadline ] whileFalse: [ (Delay forMilliseconds: 10) wait ].
	self fail: 'Timed out waiting for background batch export'
]
