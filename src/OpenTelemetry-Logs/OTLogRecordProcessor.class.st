"
Abstract processor hook for emitted log records.
"
Class {
	#name : 'OTLogRecordProcessor',
	#superclass : 'Object',
	#category : 'OpenTelemetry-Logs',
	#package : 'OpenTelemetry-Logs'
}

{ #category : 'accessing' }
OTLogRecordProcessor >> componentProcessors [

	^ { self }
]

{ #category : 'testing' }
OTLogRecordProcessor >> enabledIn: anOTContext instrumentationScope: anInstrumentationScope severityNumber: anObject eventName: aString [

	^ true
]

{ #category : 'processing' }
OTLogRecordProcessor >> forceFlush [

	^ true
]

{ #category : 'processing' }
OTLogRecordProcessor >> onEmit: anOTLogRecord context: anOTContext [

	
]

{ #category : 'processing' }
OTLogRecordProcessor >> shutdown [

	^ true
]
