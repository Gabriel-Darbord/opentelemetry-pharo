"
I am a basic processor that forwards any `OTSpan` I receive directly to the configured `OTSpanExporter`.
"
Class {
	#name : #OTSimpleSpanProcessor,
	#superclass : #OTSpanProcessor,
	#category : 'OpenTelemetry-Exporters'
}

{ #category : #processing }
OTSimpleSpanProcessor >> process: span [
	"Directly export the span and return true if it was accepted"

	^ OTSpanExporter instance export: { span }
]
