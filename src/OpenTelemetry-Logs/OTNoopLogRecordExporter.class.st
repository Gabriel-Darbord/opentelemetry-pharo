"
A no-op log-record exporter.

Before shutdown, export succeeds without transmitting telemetry. After shutdown, export and lifecycle operations fail according to the OTLogRecordExporter contract. It performs no protocol work and keeps only the minimal lifecycle state needed for shutdown semantics.
"
Class {
	#name : 'OTNoopLogRecordExporter',
	#superclass : 'OTLogRecordExporter',
	#category : 'OpenTelemetry-Logs',
	#package : 'OpenTelemetry-Logs'
}

{ #category : 'exporting' }
OTNoopLogRecordExporter >> export: someLogRecords [

	^ self isShutdown not
]
