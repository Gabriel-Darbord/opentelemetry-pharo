Class {
	#name : 'OTW3CTraceContextPropagatorTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'tests' }
OTW3CTraceContextPropagatorTest >> testExtractBuildsTraceStateFromHeader [

	| carrier context extractedTraceState |
	carrier := Dictionary new
		at: 'traceparent' put: '00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01';
		at: 'tracestate' put: 'rojo=one,tenant@system=two';
		yourself.
	context := OTW3CTraceContextPropagator current
		extract: OTContext new
		from: carrier.
	extractedTraceState := context span spanContext traceState.
	self assert: extractedTraceState class identicalTo: OTTraceState.
	self assert: (extractedTraceState valueAt: 'rojo') equals: 'one'.
	self assert: extractedTraceState asHeaderValue equals: 'rojo=one,tenant@system=two'
]

{ #category : 'tests' }
OTW3CTraceContextPropagatorTest >> testInjectSerializesTraceStateHeader [

	| carrier context spanContext |
	spanContext := OTSpanContext
		traceId: '4bf92f3577b34da6a3ce929d0e0e4736'
		spanId: '00f067aa0ba902b7'
		traceFlags: '01'
		traceState: 'rojo=one,congo=two'
		remote: false.
	context := OTContext new withSpan: spanContext asNonRecordingSpan.
	carrier := Dictionary new.
	OTW3CTraceContextPropagator current
		inject: context
		into: carrier.
	self assert: (carrier at: 'tracestate') equals: 'rojo=one,congo=two'
]

{ #category : 'tests' }
OTW3CTraceContextPropagatorTest >> testInvalidTraceStateHeaderIsDiscardedOnExtract [

	| carrier context |
	carrier := Dictionary new
		at: 'traceparent' put: '00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01';
		at: 'tracestate' put: 'rojo=one,rojo=two';
		yourself.
	context := OTW3CTraceContextPropagator current
		extract: OTContext new
		from: carrier.
	self assert: context span spanContext traceState equals: nil
]

{ #category : 'tests' }
OTW3CTraceContextPropagatorTest >> testInjectOmitsTraceStateHeaderWhenTraceStateIsEmpty [

	| carrier context spanContext |
	spanContext := OTSpanContext
		traceId: '4bf92f3577b34da6a3ce929d0e0e4736'
		spanId: '00f067aa0ba902b7'
		traceFlags: '01'
		traceState: OTTraceState empty
		remote: false.
	context := OTContext new withSpan: spanContext asNonRecordingSpan.
	carrier := Dictionary new.
	OTW3CTraceContextPropagator current
		inject: context
		into: carrier.
	self deny: (carrier includesKey: 'tracestate')
]
