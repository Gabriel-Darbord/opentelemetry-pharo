"
An OTLP logs exporter that sends JSON-encoded ExportLogsServiceRequest payloads over HTTP.

Per exporter instance, exports run through the shared OTLP HTTP export lock so
the SDK does not execute HTTP requests concurrently on the same exporter.
ForceFlush and Shutdown may still race with exporter-managed work and follow
the lifecycle contract documented on the exporter base classes.
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
