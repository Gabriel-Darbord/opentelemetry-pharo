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
OTTraceStateTest >> testMutationAllowsThirtySecondEntryButRejectsThirtyThird [

	| full traceState updated |
	traceState := self traceStateWithEntryCount: 31.
	updated := traceState withKey: 'newkey' value: 'value'.
	full := updated withKey: 'otherkey' value: 'value'.
	self deny: updated identicalTo: traceState.
	self assert: updated allEntries size equals: 32.
	self assert: full identicalTo: updated
]

{ #category : 'tests' }
OTTraceStateTest >> testMutationThatWouldExceedHeaderLengthLeavesTraceStateUnchanged [

	| traceState updated |
	traceState := OTTraceState fromHeader: 'rojo=' , (String new: 250 withAll: $a) , ',congo=' , (String new: 250 withAll: $b).
	updated := traceState withKey: 'tenant@system' value: 'x'.
	self assert: traceState asHeaderValue size equals: 512.
	self assert: updated identicalTo: traceState
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
OTTraceStateTest >> testParsingAcceptsHeaderAtMaximumLength [

	| header traceState |
	header := 'rojo=' , (String new: 250 withAll: $a) , ',congo=' , (String new: 250 withAll: $b).
	traceState := OTTraceState fromHeader: header.
	self assert: header size equals: OTTraceState maximumHeaderLength.
	self assert: traceState notNil.
	self assert: traceState asHeaderValue size equals: OTTraceState maximumHeaderLength
]

{ #category : 'tests' }
OTTraceStateTest >> testParsingRejectsDuplicateOrMalformedEntries [

	self assert: (OTTraceState fromHeader: 'rojo=one,rojo=two') equals: nil.
	self assert: (OTTraceState fromHeader: 'bad key=value') equals: nil.
	self assert: (OTTraceState fromHeader: 'rojo=') equals: nil
]

{ #category : 'tests' }
OTTraceStateTest >> testParsingRejectsHeaderLongerThanMaximumLength [

	| header |
	header := 'rojo=' , (String new: 251 withAll: $a) , ',congo=' , (String new: 251 withAll: $b).
	self assert: header size equals: OTTraceState maximumHeaderLength + 2.
	self assert: (OTTraceState fromHeader: header) equals: nil
]

{ #category : 'tests' }
OTTraceStateTest >> testParsingRejectsHeaderWithMoreThanThirtyTwoMembers [

	self assert: (self traceStateWithEntryCount: 33) equals: nil
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
OTTraceStateTest >> testTenantAndSystemKeyLengthBoundaries [

	| invalidSystemKey invalidTenantKey traceState updated validKey |
	traceState := OTTraceState empty.
	validKey := (String new: 241 withAll: $a) , '@' , (String new: 14 withAll: $b).
	invalidTenantKey := (String new: 242 withAll: $a) , '@' , (String new: 14 withAll: $b).
	invalidSystemKey := (String new: 241 withAll: $a) , '@' , (String new: 15 withAll: $b).
	updated := traceState withKey: validKey value: 'value'.
	self deny: updated identicalTo: traceState.
	self assert: (updated valueAt: validKey) equals: 'value'.
	self assert: (traceState withKey: invalidTenantKey value: 'value') identicalTo: traceState.
	self assert: (traceState withKey: invalidSystemKey value: 'value') identicalTo: traceState
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
OTTraceStateTest >> testTraceStateMutationsIgnoreNonStringInputsWithoutError [

	| traceState |
	traceState := OTTraceState fromHeader: 'vendor=one,ot=rv:7fffffffffffff'.
	self shouldnt: [ traceState withKey: 'vendor' value: 42 ] raise: Error.
	self shouldnt: [ traceState withKey: 42 value: 'value' ] raise: Error.
	self shouldnt: [ traceState withOtelValueAt: 42 put: 7 ] raise: Error.
	self assert: (traceState withKey: 'vendor' value: 42) identicalTo: traceState.
	self assert: (traceState withKey: 42 value: 'value') identicalTo: traceState.
	self assert: (traceState withOtelValueAt: 42 put: 7) identicalTo: traceState
]

{ #category : 'tests' }
OTTraceStateTest >> testUpdateMovesExistingEntryToFront [

	| traceState updated |
	traceState := OTTraceState fromHeader: 'rojo=one,congo=two,tenant@system=three'.
	updated := traceState withKey: 'congo' value: 'updated'.
	self assert: updated asHeaderValue equals: 'congo=updated,rojo=one,tenant@system=three'
]

{ #category : 'tests' }
OTTraceStateTest >> testWithOtelValueRejectsEmptyOrMalformedSubkeysAndSubvalues [

	| traceState |
	traceState := OTTraceState fromHeader: 'vendor=one,ot=rv:7fffffffffffff'.
	self assert: (traceState withOtelValueAt: '1th' put: '8') identicalTo: traceState.
	self assert: (traceState withOtelValueAt: 'th-' put: '8') identicalTo: traceState.
	self assert: (traceState withOtelValueAt: 'th' put: '') identicalTo: traceState.
	self assert: (traceState withOtelValueAt: 'th' put: 'bad:value') identicalTo: traceState
]

{ #category : 'private' }
OTTraceStateTest >> traceStateWithEntryCount: anInteger [

	^ OTTraceState fromHeader: (String streamContents: [ :stream |
				   (1 to: anInteger) do: [ :index |
						   index > 1 ifTrue: [ stream nextPut: $, ].
						   stream
							   nextPutAll: 'k';
							   nextPutAll: index asString;
							   nextPut: $=;
							   nextPutAll: 'v' ] ])
]
