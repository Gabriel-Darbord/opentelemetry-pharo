"
A span builder that preserves parent propagation semantics while always producing non-recording spans.
"
Class {
	#name : 'OTNoopSpanBuilder',
	#superclass : 'OTSpanBuilder',
	#category : 'OpenTelemetry-Instrumentation',
	#package : 'OpenTelemetry-Instrumentation'
}

{ #category : 'starting' }
OTNoopSpanBuilder >> startSpan [

	| effectiveParentContext provider parentSpan span |
	effectiveParentContext := usesCurrentContext
		                          ifTrue: [ OTSpan currentContext ]
		                          ifFalse: [ self class normalizedParentContextFrom: parentContext ].
	rootRequested ifTrue: [ effectiveParentContext := effectiveParentContext withSpan: nil ].
	provider := tracer provider.
	provider ifNotNil: [ ^ provider nonRecordingSpanIn: effectiveParentContext instrumentationScope: tracer instrumentationScope ].
	parentSpan := effectiveParentContext span.
	parentSpan
		ifNotNil: [ span := OTSpan wrapping: parentSpan spanContext ]
		ifNil: [ span := OTSpan wrapping: OTSpanContext invalid ].
	span
		restoreContext: (effectiveParentContext withSpan: span);
		restoreInstrumentationScope: tracer instrumentationScope;
		restoreResource: OTResource empty.
	^ span
]
