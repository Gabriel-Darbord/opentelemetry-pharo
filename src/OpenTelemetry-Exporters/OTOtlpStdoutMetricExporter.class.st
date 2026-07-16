"
An OTLP metrics exporter that writes JSON-line OTLP payloads to standard output.
"
Class {
	#name : 'OTOtlpStdoutMetricExporter',
	#superclass : 'OTOtlpJsonLineMetricExporter',
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'private' }
OTOtlpStdoutMetricExporter >> outputStream [

	^ Stdio stdout
]

{ #category : 'private' }
OTOtlpStdoutMetricExporter >> writeJsonLine: aString [

	self outputStream nextPutAll: aString
]
