Class {
	#name : 'OTSimpleLogRecordProcessorTest',
	#superclass : 'TestCase',
	#instVars : [
		'exporter',
		'processor'
	],
	#category : 'OpenTelemetry-Logs-Tests',
	#package : 'OpenTelemetry-Logs-Tests'
}

{ #category : 'running' }
OTSimpleLogRecordProcessorTest >> setUp [

	super setUp.
	exporter := OTRecordingLogRecordExporter new.
	processor := OTSimpleLogRecordProcessor new
		             exporter: exporter;
		             yourself
]

{ #category : 'tests' }
OTSimpleLogRecordProcessorTest >> testOnEmitExportsSingleRecordBatch [

	| record |
	record := OTLogRecord new
		          body: 'hello';
		          yourself.
	processor onEmit: record context: OTContext new.
	self assert: exporter exportedBatches size equals: 1.
	self assert: exporter exportedBatches first size equals: 1.
	self assert: exporter exportedBatches first first body equals: 'hello'
]

{ #category : 'tests' }
OTSimpleLogRecordProcessorTest >> testShutdownFlushesAndShutsDownExporter [

	self assert: processor shutdown.
	self assert: exporter forceFlushCount equals: 1.
	self assert: exporter shutdownCount equals: 1.
	self deny: (processor
			 enabledIn: nil
			 instrumentationScope: (OTInstrumentationScope named: '')
			 severityNumber: OTSeverity info
			 eventName: nil)
]
