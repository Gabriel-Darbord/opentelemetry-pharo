Class {
	#name : 'OTBaggageTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'private' }
OTBaggageTest >> sampleImplicitSpan [

	^ OTNonRecordingSpan withSpanContext: (OTSpanContext
		traceId: '11111111111111111111111111111111'
		spanId: '2222222222222222')
]

{ #category : 'running' }
OTBaggageTest >> tearDown [

	[
		OpenTelemetry resetCurrentContext ]
		ensure: [ super tearDown ]
]

{ #category : 'tests' }
OTBaggageTest >> testBuildCurrentSetsImplicitBaggageAndPreservesSpan [

	| built span |
	span := self sampleImplicitSpan.
	OpenTelemetry currentSpan: span.
	built := OTBaggage builder
		putEntryNamed: 'user.id' value: '42';
		buildCurrent.
	self assert: built equals: OTBaggage current.
	self assert: (OTBaggage currentValueAt: 'user.id') equals: '42'.
	self assert: OpenTelemetry currentSpan identicalTo: span
]

{ #category : 'tests' }
OTBaggageTest >> testBuilderHelpersIgnoreInvalidBaggageObjectsWithoutError [

	| built fromClassHelper fromInstanceHelper seeded |
	seeded := OTBaggage empty withEntryNamed: 'user.id' value: '42'.
	fromClassHelper := nil.
	fromInstanceHelper := nil.
	self shouldnt: [ fromClassHelper := OTBaggage builderFrom: 42 ] raise: Error.
	self shouldnt: [ fromInstanceHelper := OTBaggageBuilder newFrom: 42 ] raise: Error.
	self shouldnt: [ fromClassHelper putEntriesFrom: 42 ] raise: Error.
	built := fromClassHelper
		         putEntriesFrom: seeded;
		         build.
	self assert: (built valueAt: 'user.id') equals: '42'.
	self assert: fromInstanceHelper build isEmpty
]

{ #category : 'tests' }
OTBaggageTest >> testBuilderIgnoresNilEntryName [

	| baggage builder |
	builder := OTBaggage builder.
	builder putEntryNamed: 'customer.id' value: '42'.
	baggage := builder build.
	builder putEntryNamed: nil value: '100'.
	self assert: builder build equals: baggage
]

{ #category : 'tests' }
OTBaggageTest >> testBuilderIgnoresNilEntryValue [

	| baggage builder |
	builder := OTBaggage builder.
	builder putEntryNamed: 'customer.id' value: '42'.
	baggage := builder build.
	builder putEntryNamed: 'tenant.id' value: nil.
	self assert: builder build equals: baggage
]

{ #category : 'tests' }
OTBaggageTest >> testBuilderUseDuringTemporarilyActivatesBuiltBaggage [

	| original result span |
	original := OTBaggage empty withEntryNamed: 'request.id' value: 'abc'.
	span := self sampleImplicitSpan.
	OpenTelemetry currentSpan: span.
	OTBaggage current: original.
	result := (OTBaggage currentBuilder
		putEntryNamed: 'tenant.id' value: 'acme';
		useDuring: [
			self assert: (OTBaggage currentValueAt: 'request.id') equals: 'abc'.
			self assert: (OTBaggage currentValueAt: 'tenant.id') equals: 'acme'.
			self assert: OpenTelemetry currentSpan identicalTo: span.
			'inside' ]).
	self assert: result equals: 'inside'.
	self assert: OTBaggage current equals: original.
	self assert: OpenTelemetry currentSpan identicalTo: span
]

{ #category : 'tests' }
OTBaggageTest >> testClearCurrentRemovesImplicitBaggageWithoutTouchingSpan [

	| cleared span |
	span := self sampleImplicitSpan.
	OpenTelemetry currentSpan: span.
	OTBaggage current: (OTBaggage empty withEntryNamed: 'user.id' value: '42').
	cleared := OTBaggage clearCurrent.
	self assert: cleared isEmpty.
	self assert: OTBaggage current isEmpty.
	self assert: OpenTelemetry currentSpan identicalTo: span
]

{ #category : 'tests' }
OTBaggageTest >> testContextBoundariesIgnoreInvalidObjectsWithoutError [

	| baggage context extracted updatedCurrent |
	baggage := OTBaggage empty withEntryNamed: 'user.id' value: '42'.
	context := nil.
	extracted := nil.
	updatedCurrent := nil.
	self shouldnt: [ context := baggage inContext: 42 ] raise: Error.
	self shouldnt: [ extracted := OTBaggage fromContext: 42 ] raise: Error.
	self shouldnt: [ updatedCurrent := OpenTelemetry currentBaggage: 42 ] raise: Error.
	self assert: context class identicalTo: OTContext.
	self assert: context baggage equals: baggage.
	self assert: extracted isEmpty.
	self assert: updatedCurrent baggage isEmpty.
	self assert: OTBaggage current isEmpty
]

{ #category : 'tests' }
OTBaggageTest >> testCurrentBuilderStartsFromImplicitCurrentBaggage [

	| baggage built |
	baggage := OTBaggage empty withEntryNamed: 'user.id' value: '42'.
	OTBaggage current: baggage.
	built := OTBaggage currentBuilder
		putEntryNamed: 'tenant.id' value: 'acme';
		build.
	self assert: (built valueAt: 'user.id') equals: '42'.
	self assert: (built valueAt: 'tenant.id') equals: 'acme'.
	self assert: OTBaggage current equals: baggage
]

{ #category : 'tests' }
OTBaggageTest >> testCurrentDefaultsToEmptyBaggage [

	self assert: OTBaggage current equals: OTBaggage empty
]

{ #category : 'tests' }
OTBaggageTest >> testCurrentValueAndEntryHelpersReadImplicitCurrentBaggage [

	| baggage entry |
	baggage := OTBaggage empty
		withEntryNamed: 'user.id'
		value: '42'
		metadata: 'source=crm'.
	OTBaggage current: baggage.
	entry := OTBaggage currentEntryAt: 'user.id'.
	self assert: entry value equals: '42'.
	self assert: entry metadata asString equals: 'source=crm'.
	self assert: (OTBaggage currentValueAt: 'user.id') equals: '42'.
	self assert: (OTBaggage currentValueAt: 'missing' ifAbsent: [ 'fallback' ]) equals: 'fallback'
]

{ #category : 'tests' }
OTBaggageTest >> testCurrentWithEntryNamedUpdatesImplicitBaggageAndPreservesSpan [

	| span updated |
	span := self sampleImplicitSpan.
	OpenTelemetry currentSpan: span.
	updated := OTBaggage currentWithEntryNamed: 'user.id' value: '42'.
	self assert: updated equals: OTBaggage current.
	self assert: (OTBaggage currentValueAt: 'user.id') equals: '42'.
	self assert: OpenTelemetry currentSpan identicalTo: span
]

{ #category : 'tests' }
OTBaggageTest >> testCurrentWithoutEntryNamedUpdatesImplicitBaggage [

	| updated |
	OTBaggage current: ((OTBaggage empty withEntryNamed: 'user.id' value: '42')
		withEntryNamed: 'tenant.id' value: 'acme').
	updated := OTBaggage currentWithoutEntryNamed: 'user.id'.
	self deny: (updated includesEntryNamed: 'user.id').
	self assert: (updated valueAt: 'tenant.id') equals: 'acme'.
	self assert: OTBaggage current equals: updated
]

{ #category : 'tests' }
OTBaggageTest >> testRemovalHelpersAcceptSingleNamesAndIgnoreInvalidCollectionsWithoutError [

	| baggage builder invalidUpdated removedByBuilder removedByString |
	baggage := (OTBaggage empty withEntryNamed: 'user.id' value: '42') withEntryNamed: 'tenant.id' value: 'acme'.
	builder := OTBaggage builderFrom: baggage.
	invalidUpdated := nil.
	removedByString := nil.
	removedByBuilder := nil.
	self shouldnt: [ invalidUpdated := baggage withoutEntriesNamed: 42 ] raise: Error.
	self shouldnt: [ removedByString := baggage withoutEntriesNamed: 'user.id' ] raise: Error.
	self
		shouldnt: [
				removedByBuilder := builder
					                    removeEntriesNamed: 'tenant.id';
					                    build ]
		raise: Error.
	self shouldnt: [ builder removeEntriesNamed: 42 ] raise: Error.
	self assert: invalidUpdated identicalTo: baggage.
	self deny: (removedByString includesEntryNamed: 'user.id').
	self assert: (removedByString valueAt: 'tenant.id') equals: 'acme'.
	self deny: (removedByBuilder includesEntryNamed: 'tenant.id').
	self assert: (removedByBuilder valueAt: 'user.id') equals: '42'
]

{ #category : 'tests' }
OTBaggageTest >> testWithEntriesFromIgnoresInvalidCallbackInputAndSuppressesCallbackErrors [

	| baggage invalidCallback updated |
	baggage := OTBaggage empty withEntryNamed: 'user.id' value: '42'.
	invalidCallback := nil.
	updated := nil.
	self shouldnt: [ invalidCallback := baggage withEntriesFrom: 42 ] raise: Error.
	self shouldnt: [ updated := baggage withEntriesFrom: [ :builder | Error signal: 'boom' ] ] raise: Error.
	self assert: invalidCallback identicalTo: baggage.
	self assert: updated identicalTo: baggage
]

{ #category : 'tests' }
OTBaggageTest >> testWithEntryNamedIgnoresNilEntryName [

	| baggage |
	baggage := (OTBaggage empty withEntryNamed: 'customer.id' value: '42')
		withEntryNamed: nil
		value: '100'.
	self assert: baggage size equals: 1.
	self assert: (baggage valueAt: 'customer.id') equals: '42'
]

{ #category : 'tests' }
OTBaggageTest >> testWithEntryNamedIgnoresNilEntryValue [

	| baggage |
	baggage := (OTBaggage empty withEntryNamed: 'customer.id' value: '42')
		withEntryNamed: 'tenant.id'
		value: nil.
	self assert: baggage size equals: 1.
	self assert: (baggage valueAt: 'customer.id') equals: '42'
]

{ #category : 'tests' }
OTBaggageTest >> testWithEntryNamedNormalizesNamesAndValuesToStrings [

	| baggage |
	baggage := OTBaggage empty withEntryNamed: #customerId value: 42.
	self assert: baggage size equals: 1.
	self assert: (baggage includesEntryNamed: 'customerId').
	self assert: (baggage includesEntryNamed: #customerId).
	self assert: (baggage valueAt: 'customerId') equals: '42'.
	self assert: (baggage valueAt: #customerId) equals: '42'
]

{ #category : 'tests' }
OTBaggageTest >> testWithoutEntryNamedNormalizesNames [

	| baggage |
	baggage := OTBaggage empty withEntryNamed: #customerId value: '42'.
	baggage := baggage withoutEntryNamed: 'customerId'.
	self assert: baggage isEmpty
]
