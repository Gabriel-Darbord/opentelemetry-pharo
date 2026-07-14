"
Tests for OpenTelemetry span-context normalization and identifier access.
"
Class {
	#name : 'OTSpanContextTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'tests' }
OTSpanContextTest >> testBinaryAccessorsReturnSpecSizedByteArrays [

	| spanContext |
	spanContext := OTSpanContext
		traceId: '00112233445566778899aabbccddeeff'
		spanId: '1122334455667788'
		traceFlags: '01'
		traceState: nil
		remote: false.
	self assert: spanContext traceIdBytes equals: #[0 17 34 51 68 85 102 119 136 153 170 187 204 221 238 255].
	self assert: spanContext spanIdBytes equals: #[17 34 51 68 85 102 119 136]
]

{ #category : 'tests' }
OTSpanContextTest >> testConstructorRejectsMalformedIdentifiers [

	self
		should: [
			OTSpanContext
				traceId: 'xyz'
				spanId: '1122334455667788'
				traceFlags: '01'
				traceState: nil
				remote: false ]
		raise: Error.
	self
		should: [
			OTSpanContext
				traceId: '00112233445566778899aabbccddeeff'
				spanId: 'nope'
				traceFlags: '01'
				traceState: nil
				remote: false ]
		raise: Error.
	self
		should: [
			OTSpanContext
				traceId: '00112233445566778899aabbccddeeff'
				spanId: '1122334455667788'
				traceFlags: 'gg'
				traceState: nil
				remote: false ]
		raise: Error
]

{ #category : 'tests' }
OTSpanContextTest >> testIdentifiersNormalizeToLowercaseHex [

	| spanContext |
	spanContext := OTSpanContext
		traceId: '4BF92F3577B34DA6A3CE929D0E0E4736'
		spanId: '00F067AA0BA902B7'
		traceFlags: '0A'
		traceState: nil
		remote: true.
	self assert: spanContext traceIdHex equals: '4bf92f3577b34da6a3ce929d0e0e4736'.
	self assert: spanContext spanIdHex equals: '00f067aa0ba902b7'.
	self assert: spanContext traceFlags equals: '0a'.
	self assert: spanContext isRemote
]

{ #category : 'tests' }
OTSpanContextTest >> testInvalidTraceStateIsDiscardedByConstructor [

	| spanContext |
	spanContext := OTSpanContext
		traceId: '00112233445566778899aabbccddeeff'
		spanId: '1122334455667788'
		traceFlags: '01'
		traceState: 'vendor=value,vendor=duplicate'
		remote: false.
	self assert: spanContext traceState equals: nil
]

{ #category : 'tests' }
OTSpanContextTest >> testInvalidContextUsesZeroIdentifiersAndUnsampledFlags [

	| spanContext |
	spanContext := OTSpanContext invalid.
	self assert: spanContext traceIdHex equals: (String new: 32 withAll: $0).
	self assert: spanContext spanIdHex equals: (String new: 16 withAll: $0).
	self assert: spanContext traceFlags equals: '00'.
	self deny: spanContext isSampled.
	self deny: spanContext isValid.
	self deny: spanContext isRemote
]

{ #category : 'tests' }
OTSpanContextTest >> testTraceStateStringNormalizesToTraceStateObject [

	| spanContext |
	spanContext := OTSpanContext
		traceId: '00112233445566778899aabbccddeeff'
		spanId: '1122334455667788'
		traceFlags: '01'
		traceState: 'vendor=value,tenant@system=opaque'
		remote: false.
	self assert: spanContext traceState class identicalTo: OTTraceState.
	self assert: (spanContext traceState valueAt: 'vendor') equals: 'value'.
	self assert: spanContext traceState asHeaderValue equals: 'vendor=value,tenant@system=opaque'
]
