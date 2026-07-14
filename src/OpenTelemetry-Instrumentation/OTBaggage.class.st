"
An immutable collection of baggage entries keyed by case-sensitive name.
"
Class {
	#name : 'OTBaggage',
	#superclass : 'Object',
	#instVars : [
		'entriesByName'
	],
	#category : 'OpenTelemetry-Instrumentation',
	#package : 'OpenTelemetry-Instrumentation'
}

{ #category : 'instance creation' }
OTBaggage class >> builder [

	^ OTBaggageBuilder new
]

{ #category : 'instance creation' }
OTBaggage class >> builderFrom: aBaggage [

	^ OTBaggageBuilder newFrom: aBaggage
]

{ #category : 'instance creation' }
OTBaggage class >> builderFromContext: aContext [

	^ self builderFrom: (self fromContext: aContext)
]

{ #category : 'accessing' }
OTBaggage class >> clearFromContext: aContext [

	^ self empty inContext: aContext
]

{ #category : 'accessing' }
OTBaggage class >> current [

	^ OpenTelemetry currentBaggage
]

{ #category : 'accessing' }
OTBaggage class >> current: aBaggage [

	^ OpenTelemetry currentBaggage: aBaggage
]

{ #category : 'instance creation' }
OTBaggage class >> empty [

	^ self new
]

{ #category : 'accessing' }
OTBaggage class >> fromContext: aContext [

	^ aContext
		ifNil: [ self empty ]
		ifNotNil: [ aContext baggage ]
]

{ #category : 'actions' }
OTBaggage class >> use: aBaggage during: aBlock [

	^ OpenTelemetry useBaggage: aBaggage during: aBlock
]

{ #category : 'comparing' }
OTBaggage >> = anObject [

	self == anObject ifTrue: [ ^ true ].
	self class = anObject class ifFalse: [ ^ false ].
	^ entriesByName = anObject entriesByName
]

{ #category : 'accessing' }
OTBaggage >> allEntries [

	^ self entries copy
]

{ #category : 'instance creation' }
OTBaggage >> builder [

	^ self class builderFrom: self
]

{ #category : 'updating' }
OTBaggage >> cleared [

	^ self class empty
]

{ #category : 'private' }
OTBaggage >> copyWithoutEntryNamed: aName [

	| updatedEntries |
	updatedEntries := entriesByName copy.
	updatedEntries removeKey: aName.
	^ self class new
		entriesByName: updatedEntries;
		yourself
]

{ #category : 'accessing' }
OTBaggage >> entries [

	^ entriesByName associations asArray
]

{ #category : 'private' }
OTBaggage >> entriesByName [

	^ entriesByName
]

{ #category : 'private' }
OTBaggage >> entriesByName: aDictionary [

	entriesByName := aDictionary
]

{ #category : 'accessing' }
OTBaggage >> entryAt: aName [

	^ entriesByName at: aName ifAbsent: [ nil ]
]

{ #category : 'accessing' }
OTBaggage >> entryAt: aName ifAbsent: anAbsentBlock [

	^ entriesByName at: aName ifAbsent: anAbsentBlock
]

{ #category : 'comparing' }
OTBaggage >> hash [

	^ entriesByName hash
]

{ #category : 'accessing' }
OTBaggage >> inContext: aContext [

	| baseContext |
	baseContext := aContext ifNil: [ OTContext new ] ifNotNil: [ aContext ].
	^ baseContext withBaggage: self
]

{ #category : 'testing' }
OTBaggage >> includesEntryNamed: aName [

	^ entriesByName includesKey: aName
]

{ #category : 'initialization' }
OTBaggage >> initialize [

	super initialize.
	entriesByName := OrderedDictionary new
]

{ #category : 'testing' }
OTBaggage >> isEmpty [

	^ entriesByName isEmpty
]

{ #category : 'accessing' }
OTBaggage >> size [

	^ entriesByName size
]

{ #category : 'accessing' }
OTBaggage >> valueAt: aName [

	^ (self entryAt: aName)
		ifNotNil: [ :anEntry | anEntry value ]
]

{ #category : 'accessing' }
OTBaggage >> valueAt: aName ifAbsent: anAbsentBlock [

	| entry |
	entry := self entryAt: aName ifAbsent: [ ^ anAbsentBlock value ].
	^ entry value
]

{ #category : 'updating' }
OTBaggage >> withEntriesFrom: aBlock [

	| builder |
	builder := self builder.
	aBlock value: builder.
	^ builder build
]

{ #category : 'updating' }
OTBaggage >> withEntryNamed: aName value: aValue [

	^ self withEntryNamed: aName value: aValue metadata: nil
]

{ #category : 'updating' }
OTBaggage >> withEntryNamed: aName value: aValue metadata: aMetadataString [

	| updatedEntries |
	updatedEntries := entriesByName copy.
	updatedEntries
		at: aName
		put: (OTBaggageEntry value: aValue metadata: aMetadataString).
	^ self class new
		entriesByName: updatedEntries;
		yourself
]

{ #category : 'updating' }
OTBaggage >> withoutEntriesNamed: aCollection [

	| updatedBaggage |
	updatedBaggage := self.
	aCollection do: [ :eachName |
		updatedBaggage := updatedBaggage withoutEntryNamed: eachName ].
	^ updatedBaggage
]

{ #category : 'updating' }
OTBaggage >> withoutEntryNamed: aName [

	(entriesByName includesKey: aName) ifFalse: [ ^ self ].
	^ self copyWithoutEntryNamed: aName
]
