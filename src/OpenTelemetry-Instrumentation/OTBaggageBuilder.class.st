"
A mutable builder used to construct immutable baggage values.
"
Class {
	#name : 'OTBaggageBuilder',
	#superclass : 'Object',
	#instVars : [
		'entriesByName'
	],
	#category : 'OpenTelemetry-Instrumentation',
	#package : 'OpenTelemetry-Instrumentation'
}

{ #category : 'instance creation' }
OTBaggageBuilder class >> newFrom: aBaggage [

	^ self new
		initializeFrom: aBaggage;
		yourself
]

{ #category : 'building' }
OTBaggageBuilder >> build [

	| baggage |
	baggage := OTBaggage empty.
	entriesByName associationsDo: [ :each |
		baggage := baggage
			withEntryNamed: each key
			value: each value value
			metadata: each value metadata ].
	^ baggage
]

{ #category : 'building' }
OTBaggageBuilder >> buildCurrent [

	| baggage |
	baggage := self build.
	OTBaggage current: baggage.
	^ baggage
]

{ #category : 'building' }
OTBaggageBuilder >> buildInContext: aContext [

	^ self build inContext: aContext
]

{ #category : 'updating' }
OTBaggageBuilder >> clear [

	entriesByName := OrderedDictionary new.
	^ self
]

{ #category : 'initialization' }
OTBaggageBuilder >> initialize [

	super initialize.
	entriesByName := OrderedDictionary new
]

{ #category : 'initialization' }
OTBaggageBuilder >> initializeFrom: aBaggage [

	self initialize.
	aBaggage ifNil: [ ^ self ].
	(aBaggage isKindOf: OTBaggage) ifFalse: [
			OTSpan noteIgnoredInvalidArgument: aBaggage forOperation: 'OTBaggageBuilder>>initializeFrom:'.
			^ self ].
	aBaggage allEntries do: [ :each | entriesByName at: each key put: each value ]
]

{ #category : 'updating' }
OTBaggageBuilder >> putEntriesFrom: aBaggage [

	aBaggage ifNil: [ ^ self ].
	(aBaggage isKindOf: OTBaggage) ifFalse: [
			OTSpan noteIgnoredInvalidArgument: aBaggage forOperation: 'OTBaggageBuilder>>putEntriesFrom:'.
			^ self ].
	aBaggage allEntries do: [ :each | entriesByName at: each key put: each value ]
]

{ #category : 'updating' }
OTBaggageBuilder >> putEntryNamed: aName value: aValue [

	^ self putEntryNamed: aName value: aValue metadata: nil
]

{ #category : 'updating' }
OTBaggageBuilder >> putEntryNamed: aName value: aValue metadata: aMetadataObject [

	| name value |
	name := OTBaggage normalizedEntryNameFrom: aName.
	value := OTBaggage normalizedEntryValueFrom: aValue.
	(name isNil or: [ value isNil ]) ifTrue: [ ^ self ].
	entriesByName
		at: name
		put: (OTBaggageEntry value: value metadata: aMetadataObject).
	^ self
]

{ #category : 'updating' }
OTBaggageBuilder >> removeEntriesNamed: aCollection [

	aCollection ifNil: [ ^ self ].
	(aCollection isString or: [ aCollection isSymbol ]) ifTrue: [ ^ self removeEntryNamed: aCollection ].
	aCollection isCollection ifFalse: [
			OTSpan noteIgnoredInvalidArgument: aCollection forOperation: 'OTBaggageBuilder>>removeEntriesNamed:'.
			^ self ].
	aCollection do: [ :each | self removeEntryNamed: each ]
]

{ #category : 'updating' }
OTBaggageBuilder >> removeEntryNamed: aName [

	| name |
	name := OTBaggage normalizedEntryNameFrom: aName.
	name ifNil: [ ^ self ].
	entriesByName removeKey: name ifAbsent: [  ].
	^ self
]

{ #category : 'actions' }
OTBaggageBuilder >> useDuring: aBlock [

	^ OTBaggage use: self build during: aBlock
]
