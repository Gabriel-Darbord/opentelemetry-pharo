"
An abstract OTLP logs exporter that serializes each export batch as a single JSON line.
"
Class {
	#name : 'OTOtlpJsonLineLogRecordExporter',
	#superclass : 'OTOtlpJsonLineSpanExporter',
	#category : 'OpenTelemetry-Logs',
	#package : 'OpenTelemetry-Logs'
}

{ #category : 'accessing' }
OTOtlpJsonLineLogRecordExporter >> encoder [

	^ encoder ifNil: [ encoder := OTOtlpJsonLogRecordEncoder new ]
]

{ #category : 'private' }
OTOtlpJsonLineLogRecordExporter >> jsonLineFrom: logRecords [

	^ (ZnUtils defaultJSONWriter
		   toString: (self encoder encodeLogRecords: logRecords asArray))
		, String lf
]
