"
An abstract OTLP trace payload encoder.
"
Class {
	#name : 'OTOtlpTraceEncoder',
	#superclass : 'Object',
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'encoding' }
OTOtlpTraceEncoder >> encodeSpans: someSpans [

	self subclassResponsibility
]
