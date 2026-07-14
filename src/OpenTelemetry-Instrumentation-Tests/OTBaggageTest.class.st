Class {
	#name : 'OTBaggageTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'running' }
OTBaggageTest >> tearDown [

	[
		OpenTelemetry resetCurrentContext ]
		ensure: [ super tearDown ]
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
OTBaggageTest >> testCurrentDefaultsToEmptyBaggage [

	self assert: OTBaggage current equals: OTBaggage empty
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
