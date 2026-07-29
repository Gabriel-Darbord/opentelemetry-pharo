"
An abstract OTLP metrics exporter that serializes each export batch as a single JSON line.
"
Class {
	#name : 'OTOtlpJsonLineMetricExporter',
	#superclass : 'OTMetricExporter',
	#instVars : [
		'encoder'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'accessing' }
OTOtlpJsonLineMetricExporter >> encoder [

	^ encoder ifNil: [ encoder := OTOtlpJsonMetricEncoder new ]
]

{ #category : 'accessing' }
OTOtlpJsonLineMetricExporter >> encoder: anEncoder [

	encoder := anEncoder
]

{ #category : 'exporting' }
OTOtlpJsonLineMetricExporter >> export: anOTMetricSnapshot [

	| jsonLine |
	^ self withSynchronizedExportDo: [
			  self isStopping ifTrue: [ ^ false ].
			  jsonLine := [ self jsonLineFrom: anOTMetricSnapshot ]
				              on: Error
				              do: [ :error |
						              self notePayloadEncodingFailure: error.
						              ^ false ].
			  self withOperationNamed: 'export' default: false do: [
					  self writeJsonLine: jsonLine.
					  true ] ]
]

{ #category : 'private' }
OTOtlpJsonLineMetricExporter >> jsonLineFrom: anOTMetricSnapshot [

	^ (ZnUtils defaultJSONWriter toString: (self encoder encodeSnapshot: anOTMetricSnapshot)) , String lf
]

{ #category : 'private - logging' }
OTOtlpJsonLineMetricExporter >> notePayloadEncodingFailure: anError [

	self warningSink value:
		(OTOtlpExportSupport payloadEncodingFailureMessageForSignal: 'metric' transport: 'JSON-line' error: anError)
]

{ #category : 'private' }
OTOtlpJsonLineMetricExporter >> writeJsonLine: aString [

	self subclassResponsibility
]
