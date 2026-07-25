"
An OTLP logs exporter that sends JSON-encoded ExportLogsServiceRequest payloads over HTTP.
"
Class {
	#name : 'OTOtlpHttpJsonLogRecordExporter',
	#superclass : 'OTOtlpHttpJsonSpanExporter',
	#category : 'OpenTelemetry-Logs',
	#package : 'OpenTelemetry-Logs'
}

{ #category : 'private - encoding' }
OTOtlpHttpJsonLogRecordExporter >> defaultEncoderClass [

	^ OTOtlpJsonLogRecordEncoder
]

{ #category : 'private - logging' }
OTOtlpHttpJsonLogRecordExporter >> otlpSignalName [

	^ 'log'
]

{ #category : 'private - encoding' }
OTOtlpHttpJsonLogRecordExporter >> encodedPayloadFrom: logRecords [

	^ self encoder encodeLogRecords: logRecords
]

{ #category : 'private - success handling' }
OTOtlpHttpJsonLogRecordExporter >> rejectedCountFromPartialSuccess: aDictionary [

	^ self
		  nonNegativeIntegerFrom:
		  (aDictionary at: 'rejectedLogRecords' ifAbsent: [ aDictionary at: 'rejected_log_records' ifAbsent: [ 0 ] ])
		  default: 0
]
