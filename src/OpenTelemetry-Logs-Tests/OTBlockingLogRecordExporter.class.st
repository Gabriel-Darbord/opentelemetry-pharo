Class {
	#name : 'OTBlockingLogRecordExporter',
	#superclass : 'OTRecordingLogRecordExporter',
	#instVars : [
		'blockNextExport',
		'exportEntered',
		'exportRelease'
	],
	#category : 'OpenTelemetry-Logs-Tests',
	#package : 'OpenTelemetry-Logs-Tests'
}

{ #category : 'control' }
OTBlockingLogRecordExporter >> allowBlockedExport [

	exportRelease signal.
	self
]

{ #category : 'control' }
OTBlockingLogRecordExporter >> blockNextExport [

	blockNextExport := true.
	self
]

{ #category : 'exporting' }
OTBlockingLogRecordExporter >> export: someLogRecords [

	blockNextExport = true ifTrue: [
		blockNextExport := false.
		exportEntered signal.
		exportRelease wait ].
	^ super export: someLogRecords
]

{ #category : 'initialization' }
OTBlockingLogRecordExporter >> initialize [

	super initialize.
	blockNextExport := false.
	exportEntered := Semaphore new.
	exportRelease := Semaphore new
]

{ #category : 'control' }
OTBlockingLogRecordExporter >> waitForBlockedExportTimeoutMillis: anInteger [

	^ (exportEntered waitTimeoutMilliseconds: anInteger) not
]
