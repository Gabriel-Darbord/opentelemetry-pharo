"
An abstract OTLP trace payload encoder.
"
Class {
	#name : 'OTOtlpTraceEncoder',
	#superclass : 'Object',
	#category : 'OpenTelemetry-Traces',
	#package : 'OpenTelemetry-Traces'
}

{ #category : 'encoding' }
OTOtlpTraceEncoder >> encodeSpans: someSpans [

	self subclassResponsibility
]

{ #category : 'private - encoding' }
OTOtlpTraceEncoder >> normalizedSpansFrom: someSpans [

	^ (someSpans ifNil: [ #(  ) ]) collect: [ :each | OTSpanSnapshot fromExportableSpan: each ]
]
