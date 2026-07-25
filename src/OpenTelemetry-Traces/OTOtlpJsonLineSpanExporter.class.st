"
An abstract OTLP traces exporter that serializes each export batch as a single JSON line.
"
Class {
	#name : 'OTOtlpJsonLineSpanExporter',
	#superclass : 'OTSpanExporter',
	#instVars : [
		'encoder'
	],
	#category : 'OpenTelemetry-Traces',
	#package : 'OpenTelemetry-Traces'
}

{ #category : 'accessing' }
OTOtlpJsonLineSpanExporter >> encoder [

	^ encoder ifNil: [ encoder := self defaultEncoderClass new ]
]

{ #category : 'accessing' }
OTOtlpJsonLineSpanExporter >> encoder: anEncoder [

	encoder := anEncoder
]

{ #category : 'exporting' }
OTOtlpJsonLineSpanExporter >> export: spans [

	^ self withExportLockDo: [
			  self isShutdown ifTrue: [ ^ false ].
			  self withOperationNamed: 'export' default: false do: [
					  self writeJsonLine: (self jsonLineFrom: spans).
					  true ] ]
]

{ #category : 'private' }
OTOtlpJsonLineSpanExporter >> defaultEncoderClass [

	^ OTOtlpJsonTraceEncoder
]

{ #category : 'private' }
OTOtlpJsonLineSpanExporter >> jsonLineFrom: spans [

	^ (ZnUtils defaultJSONWriter
		   toString:
		   (self encoder
			    perform: self payloadEncodingSelector
			    with: (self normalizedPayloadForEncoding: spans))) , String lf
]

{ #category : 'private' }
OTOtlpJsonLineSpanExporter >> normalizedPayloadForEncoding: anObject [

	^ anObject asArray
]

{ #category : 'private' }
OTOtlpJsonLineSpanExporter >> payloadEncodingSelector [

	^ #encodeSpans:
]

{ #category : 'private' }
OTOtlpJsonLineSpanExporter >> writeJsonLine: aString [

	self subclassResponsibility
]
