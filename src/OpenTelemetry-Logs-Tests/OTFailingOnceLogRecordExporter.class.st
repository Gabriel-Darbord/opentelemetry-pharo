"
I record the batches I export, except the one after failNextExport, which fails with an error.
"
Class {
	#name : 'OTFailingOnceLogRecordExporter',
	#superclass : 'OTRecordingLogRecordExporter',
	#instVars : [
		'failsNextExport'
	],
	#category : 'OpenTelemetry-Logs-Tests',
	#package : 'OpenTelemetry-Logs-Tests'
}

{ #category : 'exporting' }
OTFailingOnceLogRecordExporter >> export: someLogRecords [

	failsNextExport = true ifTrue: [
			failsNextExport := false.
			Error signal: 'exporter failure' ].
	^ super export: someLogRecords
]

{ #category : 'control' }
OTFailingOnceLogRecordExporter >> failNextExport [

	failsNextExport := true
]
