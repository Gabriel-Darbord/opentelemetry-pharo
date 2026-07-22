"
An abstract OTLP traces exporter that serializes each export batch as a single JSON line.
"
Class {
	#name : 'OTOtlpJsonLineSpanExporter',
	#superclass : 'OTSpanExporter',
	#instVars : [
		'encoder'
	],
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'accessing' }
OTOtlpJsonLineSpanExporter >> encoder [

	^ encoder ifNil: [ encoder := OTOtlpJsonTraceEncoder new ]
]

{ #category : 'accessing' }
OTOtlpJsonLineSpanExporter >> encoder: anEncoder [

	encoder := anEncoder
]

{ #category : 'exporting' }
OTOtlpJsonLineSpanExporter >> export: spans [

	^ self withExportLockDo: [
			  self isShutdown ifTrue: [ ^ false ].
			  self writeJsonLine: (self jsonLineFrom: spans).
			  true ]
]

{ #category : 'private' }
OTOtlpJsonLineSpanExporter >> jsonLineFrom: spans [

	^ (ZnUtils defaultJSONWriter toString: (self encoder encodeSpans: spans asArray))
		, String lf
]

{ #category : 'private' }
OTOtlpJsonLineSpanExporter >> writeJsonLine: aString [

	self subclassResponsibility
]
