"
A log-record processor that bridges event-shaped log records onto the current recording span.

It adds one span event when the log record has an event name, the resolved context contains a current recording span, and the log record trace context matches that span. The log record still continues through the regular logs pipeline.
"
Class {
	#name : 'OTEventToSpanEventLogRecordProcessor',
	#superclass : 'OTLogRecordProcessor',
	#category : 'OpenTelemetry-Logs',
	#package : 'OpenTelemetry-Logs'
}

{ #category : 'private' }
OTEventToSpanEventLogRecordProcessor >> bridgeTimestampFor: anOTLogRecord [

	^ anOTLogRecord timestamp ifNil: [ anOTLogRecord observedTimestamp ]
]

{ #category : 'private' }
OTEventToSpanEventLogRecordProcessor >> hasValidSpanContextFor: anOTLogRecord [

	^ (OTSpanContext traceId: anOTLogRecord traceId spanId: anOTLogRecord spanId) isValid
]

{ #category : 'processing' }
OTEventToSpanEventLogRecordProcessor >> onEmit: anOTLogRecord context: anOTContext [

	| span timestamp |
	span := self spanToBridgeFromContext: anOTContext.
	(self shouldBridge: anOTLogRecord toSpan: span) ifFalse: [ ^ self ].
	timestamp := self bridgeTimestampFor: anOTLogRecord.
	span addEventNamed: anOTLogRecord eventName attributes: anOTLogRecord attributes timestamp: timestamp.
	self
]

{ #category : 'private' }
OTEventToSpanEventLogRecordProcessor >> shouldBridge: anOTLogRecord toSpan: aSpan [

	aSpan ifNil: [ ^ false ].
	aSpan isRecording ifFalse: [ ^ false ].
	anOTLogRecord eventName ifNil: [ ^ false ].
	(self hasValidSpanContextFor: anOTLogRecord) ifFalse: [ ^ false ].
	^ aSpan traceId = anOTLogRecord traceId and: [ aSpan spanId = anOTLogRecord spanId ]
]

{ #category : 'private' }
OTEventToSpanEventLogRecordProcessor >> spanToBridgeFromContext: anOTContext [

	| context |
	context := anOTContext ifNil: [ OpenTelemetry currentContext ].
	^ context ifNotNil: [ context span ]
]
