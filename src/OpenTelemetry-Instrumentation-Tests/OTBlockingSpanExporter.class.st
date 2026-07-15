Class {
	#name : 'OTBlockingSpanExporter',
	#superclass : 'OTRecordingSpanExporter',
	#instVars : [
		'blockNextExport',
		'exportEntered',
		'exportRelease'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'control' }
OTBlockingSpanExporter >> allowBlockedExport [

	exportRelease signal.
	^ self
]

{ #category : 'control' }
OTBlockingSpanExporter >> blockNextExport [

	blockNextExport := true.
	^ self
]

{ #category : 'accessing' }
OTBlockingSpanExporter >> export: spans [

	blockNextExport = true ifTrue: [
		blockNextExport := false.
		exportEntered signal.
		exportRelease wait ].
	^ super export: spans
]

{ #category : 'initialization' }
OTBlockingSpanExporter >> initialize [

	super initialize.
	blockNextExport := false.
	exportEntered := Semaphore new.
	exportRelease := Semaphore new
]

{ #category : 'control' }
OTBlockingSpanExporter >> waitForBlockedExportTimeoutMillis: anInteger [

	^ (exportEntered waitTimeoutMilliseconds: anInteger) not
]
