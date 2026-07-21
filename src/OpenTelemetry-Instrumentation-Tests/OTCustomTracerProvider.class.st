Class {
	#name : 'OTCustomTracerProvider',
	#superclass : 'OTTracerProvider',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'tracing' }
OTCustomTracerProvider >> nonRecordingSpanContext: aSpanContext context: aContext parent: aSpan instrumentationScope: anInstrumentationScope [

	^ OTCustomNonRecordingSpan
		spanContext: aSpanContext
		context: aContext
		parent: aSpan
		instrumentationScope: anInstrumentationScope
]

{ #category : 'tracing' }
OTCustomTracerProvider >> recordingSpanIn: aContext parent: aSpan instrumentationScope: anInstrumentationScope [

	| effectiveContext span |
	effectiveContext := aContext
		                    ifNil: [ aSpan ifNil: [ OTContext new ] ifNotNil: [ aSpan effectiveContext ] ]
		                    ifNotNil: [ aContext ].
	span := OTCustomRecordingSpan newInternal.
	span restoreContext: effectiveContext.
	aSpan ifNotNil: [ span restoreParent: aSpan ].
	span restoreInstrumentationScope: anInstrumentationScope.
	^ span
]

{ #category : 'tracing' }
OTCustomTracerProvider >> tracerForInstrumentationScope: anInstrumentationScope [

	^ OTCustomTracer
		forProvider: self
		instrumentationScope: anInstrumentationScope
]

{ #category : 'tracing' }
OTCustomTracerProvider >> wrapSpanContext: aSpanContext [

	^ OTCustomNonRecordingSpan withSpanContext: aSpanContext
]
