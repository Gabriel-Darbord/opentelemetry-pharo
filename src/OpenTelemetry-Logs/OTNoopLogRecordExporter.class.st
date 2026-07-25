"
A no-op log-record exporter.
"
Class {
	#name : 'OTNoopLogRecordExporter',
	#superclass : 'OTLogRecordExporter',
	#category : 'OpenTelemetry-Logs',
	#package : 'OpenTelemetry-Logs'
}

{ #category : 'exporting' }
OTNoopLogRecordExporter >> export: someLogRecords [

	^ true
]
