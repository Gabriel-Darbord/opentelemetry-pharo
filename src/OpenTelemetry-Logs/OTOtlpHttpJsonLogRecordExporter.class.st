"
An OTLP logs exporter that sends JSON-encoded ExportLogsServiceRequest payloads over HTTP.
"
Class {
	#name : 'OTOtlpHttpJsonLogRecordExporter',
	#superclass : 'OTOtlpHttpJsonSpanExporter',
	#category : 'OpenTelemetry-Logs',
	#package : 'OpenTelemetry-Logs'
}

{ #category : 'accessing' }
OTOtlpHttpJsonLogRecordExporter >> encoder [

	^ encoder ifNil: [ encoder := OTOtlpJsonLogRecordEncoder new ]
]

{ #category : 'exporting' }
OTOtlpHttpJsonLogRecordExporter >> export: logRecords [

	self isShutdown ifTrue: [ ^ false ].
	^ self exportAttemptNumber: 1 payloadString: (self payloadStringFrom: logRecords)
]

{ #category : 'private - logging' }
OTOtlpHttpJsonLogRecordExporter >> noteInvalidSuccessResponse: anError [

	self warningSink value: 'OpenTelemetry OTLP log export returned an invalid success response: ' , anError messageText
]

{ #category : 'private - logging' }
OTOtlpHttpJsonLogRecordExporter >> notePartialSuccess: aDictionary [

	self warningSink value: 'OpenTelemetry OTLP log export reported partial success: ' , aDictionary printString
]

{ #category : 'private - logging' }
OTOtlpHttpJsonLogRecordExporter >> noteRetryExhaustedForError: anError [

	self warningSink value:
		'OpenTelemetry OTLP log export exhausted retries after a retryable transport failure: ' , anError messageText
]

{ #category : 'private - logging' }
OTOtlpHttpJsonLogRecordExporter >> noteRetryExhaustedForResponse: aResponse [

	self warningSink value:
		'OpenTelemetry OTLP log export exhausted retries after HTTP status ' , (self responseCodeFrom: aResponse) asString
]

{ #category : 'private - encoding' }
OTOtlpHttpJsonLogRecordExporter >> payloadStringFrom: logRecords [

	^ ZnUtils defaultJSONWriter toString: (self encoder encodeLogRecords: logRecords asArray)
]

{ #category : 'private - success handling' }
OTOtlpHttpJsonLogRecordExporter >> rejectedSpanCountFromPartialSuccess: aDictionary [

	^ self
		  nonNegativeIntegerFrom:
		  (aDictionary at: 'rejectedLogRecords' ifAbsent: [ aDictionary at: 'rejected_log_records' ifAbsent: [ 0 ] ])
		  default: 0
]
