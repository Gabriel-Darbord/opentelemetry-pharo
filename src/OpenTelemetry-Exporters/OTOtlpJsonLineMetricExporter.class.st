"
An abstract OTLP metrics exporter that serializes each export batch as a single JSON line.
"
Class {
	#name : 'OTOtlpJsonLineMetricExporter',
	#superclass : 'OTMetricExporter',
	#instVars : [
		'encoder'
	],
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
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

	self isShutdown ifTrue: [ ^ false ].
	self writeJsonLine: (self jsonLineFrom: anOTMetricSnapshot).
	^ true
]

{ #category : 'private' }
OTOtlpJsonLineMetricExporter >> jsonLineFrom: anOTMetricSnapshot [

	^ (ZnUtils defaultJSONWriter toString: (self encoder encodeSnapshot: anOTMetricSnapshot)) , String lf
]

{ #category : 'private' }
OTOtlpJsonLineMetricExporter >> writeJsonLine: aString [

	self subclassResponsibility
]
