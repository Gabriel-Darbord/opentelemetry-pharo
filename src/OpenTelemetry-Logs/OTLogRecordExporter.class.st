"
Abstract exporter for readable log records.

The SDK must not call Export concurrently on the same exporter instance. ForceFlush and Shutdown must be safe to call concurrently with each other and with exporter-managed background work.
"
Class {
	#name : 'OTLogRecordExporter',
	#superclass : 'Object',
	#instVars : [
		'stateLock',
		'shutdownRequested',
		'shutdownCompleted'
	],
	#category : 'OpenTelemetry-Logs',
	#package : 'OpenTelemetry-Logs'
}

{ #category : 'private - lifecycle' }
OTLogRecordExporter >> beginShutdown [

	^ stateLock critical: [
			  (shutdownRequested = true or: [ shutdownCompleted = true ])
				  ifTrue: [ false ]
				  ifFalse: [
						  shutdownRequested := true.
						  true ] ]
]

{ #category : 'accessing' }
OTLogRecordExporter >> componentExporters [

	^ { self }
]

{ #category : 'testing' }
OTLogRecordExporter >> enabledIn: anOTContext instrumentationScope: anInstrumentationScope severityNumber: anObject eventName: aString [

	^ true
]

{ #category : 'exporting' }
OTLogRecordExporter >> export: someLogRecords [

	self subclassResponsibility
]

{ #category : 'exporting' }
OTLogRecordExporter >> forceFlush [

	^ self isShutdown
		  ifTrue: [ false ]
		  ifFalse: [ true ]
]

{ #category : 'initialization' }
OTLogRecordExporter >> initialize [

	super initialize.
	stateLock := Semaphore forMutualExclusion.
	shutdownRequested := false.
	shutdownCompleted := false
]

{ #category : 'testing' }
OTLogRecordExporter >> isShutdown [

	^ stateLock critical: [ shutdownRequested = true or: [ shutdownCompleted = true ] ]
]

{ #category : 'private - lifecycle' }
OTLogRecordExporter >> markShutdown [

	stateLock critical: [
			shutdownRequested := true.
			shutdownCompleted := true ].
	self
]

{ #category : 'exporting' }
OTLogRecordExporter >> shutdown [

	self beginShutdown ifFalse: [ ^ false ].
	self markShutdown.
	^ true
]
