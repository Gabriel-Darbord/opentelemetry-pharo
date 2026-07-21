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
OTSpanContextTest >> testBinaryConstructorBuildsEquivalentSpanContext [

	| spanContext |
	spanContext := OTSpanContext
		traceIdBytes: #[0 17 34 51 68 85 102 119 136 153 170 187 204 221 238 255]
		spanIdBytes: #[17 34 51 68 85 102 119 136]
		traceFlags: '01'
		traceState: 'vendor=value'
		remote: true.
	self assert: spanContext traceIdHex equals: '00112233445566778899aabbccddeeff'.
	self assert: spanContext spanIdHex equals: '1122334455667788'.
	self assert: spanContext traceFlags equals: '01'.
	self assert: spanContext traceState asHeaderValue equals: 'vendor=value'.
	self assert: spanContext isRemote
]

{ #category : 'tests' }
OTSpanContextTest >> testBinaryConstructorRejectsMalformedByteArrays [

	self
		should: [
			OTSpanContext
				traceIdBytes: #[1 2 3]
				spanIdBytes: #[17 34 51 68 85 102 119 136]
				traceFlags: '01'
				traceState: nil
				remote: false ]
		raise: Error.
	self
		should: [
			OTSpanContext
				traceIdBytes: #[0 17 34 51 68 85 102 119 136 153 170 187 204 221 238 255]
				spanIdBytes: #[1 2 3]
				traceFlags: '01'
				traceState: nil
				remote: false ]
		raise: Error
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
OTSpanContextTest >> testCopyingOperationsReturnNewSpanContextsWithoutMutatingOriginal [

	| original updatedFlags updatedRemote updatedState |
	original := OTSpanContext
		            traceId: '00112233445566778899aabbccddeeff'
		            spanId: '1122334455667788'
		            traceFlags: '01'
		            traceState: 'vendor=value'
		            remote: false.
	updatedFlags := original withTraceFlags: '03'.
	updatedState := original withTraceState: 'vendor=next'.
	updatedRemote := original withRemote: true.
	self assert: original traceFlags equals: '01'.
	self assert: original traceState asHeaderValue equals: 'vendor=value'.
	self deny: original isRemote.
	self assert: updatedFlags traceFlags equals: '03'.
	self assert: updatedState traceState asHeaderValue equals: 'vendor=next'.
	self assert: updatedRemote isRemote
]

{ #category : 'tests' }
OTSpanContextTest >> testFromSpanPreservesRemoteWrappedSpanContext [

	| remoteContext wrappedSpan |
	remoteContext := OTSpanContext
		                 traceId: '00112233445566778899aabbccddeeff'
		                 spanId: '1122334455667788'
		                 traceFlags: '01'
		                 traceState: 'vendor=value'
		                 remote: true.
	wrappedSpan := remoteContext asNonRecordingSpan.
	self assert: (OTSpanContext fromSpan: wrappedSpan) identicalTo: remoteContext.
	self assert: (OTSpanContext fromSpan: wrappedSpan) isRemote
]

{ #category : 'tests' }
OTSpanContextTest >> testGeneratedIdentifiersHaveSpecShape [

	| spanId traceId |
	traceId := OTSpanContext newTraceId.
	spanId := OTSpanContext newSpanId.
	self assert: (OTSpanContext isLowercaseHexString: traceId size: 32).
	self assert: (OTSpanContext isLowercaseHexString: spanId size: 16).
	self deny: (OTSpanContext isZeroHexIdentifier: traceId).
	self deny: (OTSpanContext isZeroHexIdentifier: spanId)
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
OTSpanContextTest >> testRecordingSpanDoesNotExposeCreationStateMutators [

	| exportRecord originalKind originalParentContext provider replacementParentContext span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	originalParentContext := OTSpanContext
		                         traceId: '00112233445566778899aabbccddeeff'
		                         spanId: '1122334455667788'
		                         traceFlags: '01'
		                         traceState: 'upstream=value'
		                         remote: true.
	span := (tracer spanBuilderNamed: 'operation')
		        inContext: (OTContext new withSpan: originalParentContext asNonRecordingSpan);
		        kind: OTSpan client;
		        startSpan.
	replacementParentContext := OTSpanContext
		                            traceId: 'ffeeddccbbaa99887766554433221100'
		                            spanId: '8877665544332211'
		                            traceFlags: '03'
		                            traceState: 'downstream=value'
		                            remote: true.
	exportRecord := span asExportRecord.
	originalKind := exportRecord at: #kind.
	self should: [ span perform: #kind: with: OTSpan server ] raise: MessageNotUnderstood.
	self should: [ span perform: #parentSpanContext: with: replacementParentContext ] raise: MessageNotUnderstood.
	exportRecord := span asExportRecord.
	self assert: (exportRecord at: #kind) equals: originalKind.
	self assert: (exportRecord at: #parentSpanContext) equals: originalParentContext
]

{ #category : 'tests' }
OTSpanContextTest >> testRecordingSpanDoesNotExposeSpanContextMutator [

	| original provider span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	original := span spanContext.
	self should: [ span perform: #spanContext: with: (original withTraceState: 'vendor=value') ] raise: MessageNotUnderstood.
	self assert: span spanContext identicalTo: original.
	self assert: span spanContext traceState equals: original traceState
]

{ #category : 'tests' }
OTSpanContextTest >> testRecordingSpanStonRoundTripPreservesLocalSpanContext [

	| parentContext provider roundTripped span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	parentContext := OTContext new withSpan: (OTSpanContext
			                  traceId: '00112233445566778899aabbccddeeff'
			                  spanId: '1122334455667788'
			                  traceFlags: '01'
			                  traceState: 'vendor=value'
			                  remote: true) asNonRecordingSpan.
	span := (tracer spanBuilderNamed: 'operation')
		        inContext: parentContext;
		        startSpan.
	roundTripped := STON fromString: (STON toString: span).
	self deny: roundTripped spanContext isRemote.
	self assert: roundTripped spanContext traceId equals: span spanContext traceId.
	self assert: roundTripped spanContext spanId equals: span spanContext spanId.
	self assert: roundTripped spanContext traceFlags equals: span spanContext traceFlags.
	self assert: roundTripped spanContext traceState equals: span spanContext traceState
]

{ #category : 'tests' }
OTSpanContextTest >> testSpanClassesCannotBeInstantiatedDirectly [

	self should: [ OTSpan new ] raise: Error.
	self should: [ OTNonRecordingSpan new ] raise: Error.
	self should: [ OTSpan perform: #newSpanId ] raise: MessageNotUnderstood.
	self should: [ OTSpan perform: #newTraceId ] raise: MessageNotUnderstood.
	self should: [ OTSpan perform: #isZeroHexIdentifier: with: '0' ] raise: MessageNotUnderstood.
	self should: [ OTSpan perform: #randomHexDigit ] raise: MessageNotUnderstood.
	self should: [ OTSpan perform: #rootInInternal: with: OTContext new ] raise: MessageNotUnderstood.
	self should: [ OTSpan perform: #underInternal: with: (OTSpan wrapping: OTSpanContext invalid) ] raise: MessageNotUnderstood
]

{ #category : 'tests' }
OTSpanContextTest >> testSpanContextClassCannotBeInstantiatedDirectly [

	self should: [ OTSpanContext new ] raise: Error
]

{ #category : 'tests' }
OTSpanContextTest >> testTraceFlagsSupportSampledAndRandomBits [

	| sampledRandom randomOnly |
	sampledRandom := OTSpanContext
		traceId: '00112233445566778899aabbccddeeff'
		spanId: '1122334455667788'
		traceFlags: '03'
		traceState: nil
		remote: false.
	randomOnly := OTSpanContext
		traceId: '00112233445566778899aabbccddeeff'
		spanId: '1122334455667788'
		traceFlags: '02'
		traceState: nil
		remote: false.
	self assert: sampledRandom isSampled.
	self assert: sampledRandom isRandom.
	self deny: randomOnly isSampled.
	self assert: randomOnly isRandom
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

{ #category : 'tests' }
OTSpanContextTest >> testWithRemoteHelpersPreserveIdentityAndFlags [

	| local remote |
	local := OTSpanContext
		traceId: '00112233445566778899aabbccddeeff'
		spanId: '1122334455667788'
		traceFlags: '03'
		traceState: 'vendor=value'
		remote: false.
	remote := local asRemote.
	self deny: local identicalTo: remote.
	self deny: local isRemote.
	self assert: remote isRemote.
	self assert: remote traceIdHex equals: local traceIdHex.
	self assert: remote spanIdHex equals: local spanIdHex.
	self assert: remote traceFlags equals: local traceFlags.
	self assert: remote traceState asHeaderValue equals: local traceState asHeaderValue.
	self assert: remote asLocal equals: local
]

{ #category : 'tests' }
OTSpanContextTest >> testWithTraceStateReturnsCopiedImmutableContext [

	| original updated |
	original := OTSpanContext
		traceId: '00112233445566778899aabbccddeeff'
		spanId: '1122334455667788'
		traceFlags: '01'
		traceState: nil
		remote: false.
	updated := original withTraceState: 'vendor=value'.
	self deny: updated identicalTo: original.
	self assert: original traceState equals: nil.
	self assert: updated traceState asHeaderValue equals: 'vendor=value'.
	self deny: updated isRemote
]
