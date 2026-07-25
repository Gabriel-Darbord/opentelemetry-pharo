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
