Class {
	#name : 'OTContextTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'tests' }
OTContextTest >> testCreateKeyNamedReturnsDistinctKeysForTheSameName [

	| first second |
	first := OTContext createKeyNamed: 'demo'.
	second := OTContext createKeyNamed: 'demo'.
	self deny: first identicalTo: second
]

{ #category : 'tests' }
OTContextTest >> testWithBaggageReturnsNewContextWithoutMutatingOriginal [

	| baggage context updated |
	context := OTContext new.
	baggage := OTBaggage empty withEntryNamed: 'user.id' value: '42'.
	updated := context withBaggage: baggage.
	self assert: updated baggage equals: baggage.
	self assert: context baggage isEmpty
]

{ #category : 'tests' }
OTContextTest >> testWithSpanReturnsNewContextWithoutMutatingOriginal [

	| context span updated |
	context := OTContext new.
	span := OTSpanContext invalid asNonRecordingSpan.
	updated := context withSpan: span.
	self assert: updated span identicalTo: span.
	self assert: context span isNil
]

{ #category : 'tests' }
OTContextTest >> testWithValueAtPutReturnsNewContextWithoutMutatingOriginal [

	| context key updated |
	context := OTContext new.
	key := OTContext createKeyNamed: 'demo'.
	updated := context withValueAt: key put: 42.
	self assert: (updated valueAt: key) equals: 42.
	self assert: (context valueAt: key ifAbsent: [ #missing ]) equals: #missing
]

{ #category : 'tests' }
OTContextTest >> testWithoutValueAtRemovesStoredValue [

	| context key updated |
	key := OTContext createKeyNamed: 'demo'.
	context := (OTContext new withValueAt: key put: 42) withoutValueAt: key.
	updated := context valueAt: key ifAbsent: [ #missing ].
	self assert: updated equals: #missing
]
