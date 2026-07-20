"
Tests for immutable W3C TraceState behavior.
"
Class {
	#name : 'OTTraceStateTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'tests' }
OTTraceStateTest >> testAddPlacesNewEntryAtFront [

	| traceState updated |
	traceState := OTTraceState fromHeader: 'rojo=one,congo=two'.
	updated := traceState withKey: 'tenant@system' value: 'three'.
	self assert: updated asHeaderValue equals: 'tenant@system=three,rojo=one,congo=two'
]

{ #category : 'tests' }
OTTraceStateTest >> testDeleteRemovesKeyWithoutChangingRemainingOrder [

	| traceState updated |
	traceState := OTTraceState fromHeader: 'rojo=one,congo=two,tenant@system=three'.
	updated := traceState withoutKey: 'congo'.
	self assert: updated asHeaderValue equals: 'rojo=one,tenant@system=three'
]

{ #category : 'tests' }
OTTraceStateTest >> testInvalidMutationLeavesTraceStateUnchanged [

	| traceState |
	traceState := OTTraceState fromHeader: 'rojo=one'.
	self assert: (traceState withKey: 'Bad Key' value: 'value') identicalTo: traceState.
	self assert: (traceState withKey: 'vendor' value: 'bad,value') identicalTo: traceState
]

{ #category : 'tests' }
OTTraceStateTest >> testOpenTelemetrySubkeyUpdatesPreserveExistingValues [

	| traceState updated |
	traceState := OTTraceState fromHeader: 'vendor=one,ot=rv:7fffffffffffff'.
	updated := traceState withOtelValueAt: 'th' put: '8'.
	self assert: (updated valueAt: 'vendor') equals: 'one'.
	self assert: (updated otelValueAt: 'rv') equals: '7fffffffffffff'.
	self assert: (updated otelValueAt: 'th') equals: '8'
]

{ #category : 'tests' }
OTTraceStateTest >> testParsingRejectsDuplicateOrMalformedEntries [

	self assert: (OTTraceState fromHeader: 'rojo=one,rojo=two') equals: nil.
	self assert: (OTTraceState fromHeader: 'bad key=value') equals: nil.
	self assert: (OTTraceState fromHeader: 'rojo=') equals: nil
]

{ #category : 'tests' }
OTTraceStateTest >> testParsingSkipsEmptyMembersAndAcceptsWhitespaceOnlyHeader [

	| traceState emptyTraceState |
	traceState := OTTraceState fromHeader: 'rojo=one, , congo=two'.
	emptyTraceState := OTTraceState fromHeader: '   '.
	self assert: traceState asHeaderValue equals: 'rojo=one,congo=two'.
	self assert: emptyTraceState isEmpty
]

{ #category : 'tests' }
OTTraceStateTest >> testTraceStateClassCannotBeInstantiatedDirectlyOrMutated [

	| traceState |
	traceState := OTTraceState fromHeader: 'rojo=one'.
	self should: [ OTTraceState new ] raise: Error.
	self should: [ traceState perform: #entriesByKey: with: OrderedDictionary new ] raise: MessageNotUnderstood.
	self assert: (traceState valueAt: 'rojo') equals: 'one'
]

{ #category : 'tests' }
OTTraceStateTest >> testUpdateMovesExistingEntryToFront [

	| traceState updated |
	traceState := OTTraceState fromHeader: 'rojo=one,congo=two,tenant@system=three'.
	updated := traceState withKey: 'congo' value: 'updated'.
	self assert: updated asHeaderValue equals: 'congo=updated,rojo=one,tenant@system=three'
]
