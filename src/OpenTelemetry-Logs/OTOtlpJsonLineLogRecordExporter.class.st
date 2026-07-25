"
An abstract OTLP logs exporter that serializes each export batch as a single JSON line.
"
Class {
	#name : 'OTOtlpJsonLineLogRecordExporter',
	#superclass : 'OTOtlpJsonLineSpanExporter',
	#category : 'OpenTelemetry-Logs',
	#package : 'OpenTelemetry-Logs'
}

{ #category : 'private' }
OTOtlpJsonLineLogRecordExporter >> defaultEncoderClass [

	^ OTOtlpJsonLogRecordEncoder
]

{ #category : 'private' }
OTOtlpJsonLineLogRecordExporter >> payloadEncodingSelector [

	^ #encodeLogRecords:
]
