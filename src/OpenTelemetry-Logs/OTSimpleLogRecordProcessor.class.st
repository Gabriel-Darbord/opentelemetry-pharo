"
A synchronous processor that exports each log record immediately.

It serializes calls to its exporter so `export:` is never invoked concurrently, and after shutdown it stops accepting new log records.
"
Class {
	#name : 'OTSimpleLogRecordProcessor',
	#superclass : 'OTLogRecordProcessor',
	#instVars : [
		'exporter',
		'exportLock',
		'shutdown'
	],
	#category : 'OpenTelemetry-Logs',
	#package : 'OpenTelemetry-Logs'
}

{ #category : 'testing' }
OTSimpleLogRecordProcessor >> enabledIn: anOTContext instrumentationScope: anInstrumentationScope severityNumber: anObject eventName: aString [

	^ shutdown = true
		  ifTrue: [ false ]
		  ifFalse: [
				  self exporter
					  enabledIn: anOTContext
					  instrumentationScope: anInstrumentationScope
					  severityNumber: anObject
					  eventName: aString ]
]

{ #category : 'accessing' }
OTSimpleLogRecordProcessor >> exporter [

	^ exporter ifNil: [ OTNoopLogRecordExporter new ]
]

{ #category : 'accessing' }
OTSimpleLogRecordProcessor >> exporter: anOTLogRecordExporter [

	exporter := anOTLogRecordExporter.
	^ exporter
]

{ #category : 'processing' }
OTSimpleLogRecordProcessor >> forceFlush [

	^ exportLock critical: [ self exporter forceFlush ]
]

{ #category : 'initialization' }
OTSimpleLogRecordProcessor >> initialize [

	super initialize.
	exportLock := Semaphore forMutualExclusion.
	shutdown := false
]

{ #category : 'processing' }
OTSimpleLogRecordProcessor >> onEmit: anOTLogRecord context: anOTContext [

	| durationSeconds result startedMillis |
	shutdown = true ifTrue: [ ^ self ].
	exportLock critical: [
			startedMillis := Time millisecondClockValue.
			OTSdkSelfObservability current recordExportStartedFor: self exporter signal: #log itemCount: 1.
			result := [ self exporter export: { anOTLogRecord copy } ]
				          on: Error
				          do: [ false ].
			durationSeconds := OTSdkSelfObservability elapsedSecondsSinceMillisecondClockValue: startedMillis.
			OTSdkSelfObservability current
				recordExportFinishedFor: self exporter
				signal: #log
				itemCount: 1
				result: (OTLifecycleResult fromBoolean: result)
				durationSeconds: durationSeconds;
				recordProcessedCount: 1
				forProcessor: self
				signal: #log
				errorType: (OTSdkSelfObservability lifecycleErrorTypeFor: (OTLifecycleResult fromBoolean: result)) ].
	self
]

{ #category : 'processing' }
OTSimpleLogRecordProcessor >> shutdown [

	| flushed shutdownResult |
	shutdown = true ifTrue: [ ^ false ].
	shutdown := true.
	flushed := self forceFlush.
	shutdownResult := exportLock critical: [ self exporter shutdown ].
	^ shutdownResult & flushed
]
