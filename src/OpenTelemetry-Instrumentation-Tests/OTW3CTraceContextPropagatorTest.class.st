Class {
	#name : 'OTW3CTraceContextPropagatorTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'tests' }
OTW3CTraceContextPropagatorTest >> testExtractAcceptsFutureVersionTraceParentWithExtraSuffix [

	| carrier context |
	carrier := Dictionary new
		at: 'traceparent' put: '01-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-00-02';
		yourself.
	context := OTW3CTraceContextPropagator current
		extract: OTContext new
		from: carrier.
	self assert: context span spanContext traceId equals: '4bf92f3577b34da6a3ce929d0e0e4736'.
	self assert: context span spanContext spanId equals: '00f067aa0ba902b7'.
	self assert: context span spanContext traceFlags equals: '00'.
	self assert: context span spanContext isRemote
]

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
OTW3CTraceContextPropagatorTest >> testExtractCombinesRepeatedTraceStateHeaderValues [

	| carrier context traceState |
	carrier := Dictionary new
		           at: 'traceparent' put: '00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01';
		           at: 'tracestate' put: #( 'rojo=one' 'tenant@system=two' );
		           yourself.
	context := OTW3CTraceContextPropagator new extract: OTContext new from: carrier.
	traceState := context span spanContext traceState.
	self assert: (traceState valueAt: 'rojo') equals: 'one'.
	self assert: (traceState valueAt: 'tenant@system') equals: 'two'
]

{ #category : 'tests' }
OTW3CTraceContextPropagatorTest >> testExtractNilGetterReturnsOriginalContext [

	| context |
	context := OTContext new
		withSpan: ((OTSpanContext
			traceId: '4bf92f3577b34da6a3ce929d0e0e4736'
			spanId: '00f067aa0ba902b7'
			traceFlags: '01'
			traceState: nil
			remote: false) asNonRecordingSpan).
	self
		assert: (OTW3CTraceContextPropagator current
			extract: context
			from: Dictionary new
			getter: nil)
		identicalTo: context
]

{ #category : 'tests' }
OTW3CTraceContextPropagatorTest >> testExtractNormalizesCollectionHeaderValues [

	| carrier context |
	carrier := Dictionary new
		at: 'traceparent' put: #(nil ' 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01 ');
		at: 'tracestate' put: #(nil ' rojo=one,tenant@system=two ');
		yourself.
	context := OTW3CTraceContextPropagator current
		extract: OTContext new
		from: carrier.
	self assert: context span spanContext traceId equals: '4bf92f3577b34da6a3ce929d0e0e4736'.
	self assert: context span spanContext spanId equals: '00f067aa0ba902b7'.
	self assert: context span spanContext traceFlags equals: '01'.
	self assert: (context span spanContext traceState valueAt: 'rojo') equals: 'one'
]

{ #category : 'tests' }
OTW3CTraceContextPropagatorTest >> testExtractNormalizesSymbolHeaderValues [

	| carrier context |
	carrier := Dictionary new
		at: 'traceparent' put: #'00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01';
		at: 'tracestate' put: #'rojo=one,tenant@system=two';
		yourself.
	context := OTW3CTraceContextPropagator current
		extract: OTContext new
		from: carrier.
	self assert: context span spanContext traceId equals: '4bf92f3577b34da6a3ce929d0e0e4736'.
	self assert: context span spanContext spanId equals: '00f067aa0ba902b7'.
	self assert: context span spanContext traceFlags equals: '01'.
	self assert: (context span spanContext traceState valueAt: 'tenant@system') equals: 'two'
]

{ #category : 'tests' }
OTW3CTraceContextPropagatorTest >> testInjectNilSetterDoesNothing [

	| context spanContext |
	spanContext := OTSpanContext
		traceId: '4bf92f3577b34da6a3ce929d0e0e4736'
		spanId: '00f067aa0ba902b7'
		traceFlags: '01'
		traceState: 'rojo=one'
		remote: false.
	context := OTContext new withSpan: spanContext asNonRecordingSpan.
	self
		shouldnt: [
			OTW3CTraceContextPropagator current
				inject: context
				into: Dictionary new
				setter: nil ]
		raise: Error
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
OTW3CTraceContextPropagatorTest >> testRejectsVersion00TraceParentWithExtraSuffix [

	| carrier context |
	carrier := Dictionary new
		at: 'traceparent' put: '00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-00-02';
		yourself.
	context := OTW3CTraceContextPropagator current
		extract: OTContext new
		from: carrier.
	self assert: context span equals: nil
]
