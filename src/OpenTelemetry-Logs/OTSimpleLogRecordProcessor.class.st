"
A synchronous processor that exports each log record immediately.
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

	shutdown = true ifTrue: [ ^ self ].
	exportLock critical: [ self exporter export: { anOTLogRecord copy } ].
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
