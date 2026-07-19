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

	| span |
	span := aSpan ifNil: [ OTCustomRecordingSpan rootInInternal: aContext ] ifNotNil: [ OTCustomRecordingSpan underInternal: aSpan ].
	span instrumentationScope: anInstrumentationScope.
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
