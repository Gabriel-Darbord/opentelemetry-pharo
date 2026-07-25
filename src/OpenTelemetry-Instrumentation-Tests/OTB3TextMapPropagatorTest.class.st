Class {
	#name : 'OTB3TextMapPropagatorTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'tests' }
OTB3TextMapPropagatorTest >> testExtractNilGetterReturnsOriginalContext [

	| context |
	context := OTContext new withSpan: (OTSpanContext
			            traceId: '4bf92f3577b34da6a3ce929d0e0e4736'
			            spanId: '00f067aa0ba902b7'
			            traceFlags: '01'
			            traceState: nil
			            remote: false) asNonRecordingSpan.
	self assert: (OTB3TextMapPropagator singleHeader extract: context from: Dictionary new getter: nil) identicalTo: context
]

{ #category : 'tests' }
OTB3TextMapPropagatorTest >> testExtractSingleHeaderFromCollectionValue [

	| carrier context |
	carrier := Dictionary new
		           at: 'b3' put: #( nil ' 4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-1 ' );
		           yourself.
	context := OTB3TextMapPropagator singleHeader extract: OTContext new from: carrier.
	self assert: context span spanContext traceId equals: '4bf92f3577b34da6a3ce929d0e0e4736'.
	self assert: context span spanContext spanId equals: '00f067aa0ba902b7'.
	self assert: context span spanContext traceFlags equals: '01'.
	self assert: context span spanContext isRemote
]

{ #category : 'tests' }
OTB3TextMapPropagatorTest >> testInjectNilSetterDoesNothingForMultiHeader [

	| context spanContext |
	spanContext := OTSpanContext
		               traceId: '4bf92f3577b34da6a3ce929d0e0e4736'
		               spanId: '00f067aa0ba902b7'
		               traceFlags: '01'
		               traceState: nil
		               remote: false.
	context := (OTContext new withSpan: spanContext asNonRecordingSpan)
		           withPropertyAt: OTB3TextMapPropagator debugPropertyKey
		           put: true.
	self shouldnt: [ OTB3TextMapPropagator multiHeader inject: context into: Dictionary new setter: nil ] raise: Error
]

{ #category : 'tests' }
OTB3TextMapPropagatorTest >> testInjectNilSetterDoesNothingForSingleHeader [

	| context spanContext |
	spanContext := OTSpanContext
		               traceId: '4bf92f3577b34da6a3ce929d0e0e4736'
		               spanId: '00f067aa0ba902b7'
		               traceFlags: '01'
		               traceState: nil
		               remote: false.
	context := OTContext new withSpan: spanContext asNonRecordingSpan.
	self shouldnt: [ OTB3TextMapPropagator singleHeader inject: context into: Dictionary new setter: nil ] raise: Error
]
