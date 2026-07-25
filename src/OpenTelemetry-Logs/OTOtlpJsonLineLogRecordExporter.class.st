"
An abstract OTLP logs exporter that serializes each export batch as a single JSON line.

The SDK serializes export calls per exporter instance before subclasses write
their JSON line to a destination. ForceFlush and Shutdown may still race with
destination-specific work and therefore follow the lifecycle contract
documented on the exporter base classes.
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
OTOtlpJsonLineLogRecordExporter >> encodedPayloadFrom: logRecords [

	^ self encoder encodeLogRecords: logRecords
]
