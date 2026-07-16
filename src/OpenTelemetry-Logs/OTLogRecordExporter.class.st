"
Abstract exporter for readable log records.
"
Class {
	#name : 'OTLogRecordExporter',
	#superclass : 'Object',
	#category : 'OpenTelemetry-Logs',
	#package : 'OpenTelemetry-Logs'
}

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

	^ true
]

{ #category : 'exporting' }
OTLogRecordExporter >> shutdown [

	^ true
]
