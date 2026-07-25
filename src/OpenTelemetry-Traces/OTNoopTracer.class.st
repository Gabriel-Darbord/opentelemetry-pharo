"
A tracer that always answers non-recording spans and never enters the SDK recording pipeline.
"
Class {
	#name : 'OTNoopTracer',
	#superclass : 'OTTracer',
	#category : 'OpenTelemetry-Traces',
	#package : 'OpenTelemetry-Traces'
}

{ #category : 'tracing' }
OTNoopTracer >> enabledForSpanNamed: aString kind: aSpanKind in: aContext attributes: someAttributes links: someLinks [

	^ false
]

{ #category : 'tracing' }
OTNoopTracer >> spanBuilderNamed: aString [

	^ OTNoopSpanBuilder forTracer: self name: aString
]
