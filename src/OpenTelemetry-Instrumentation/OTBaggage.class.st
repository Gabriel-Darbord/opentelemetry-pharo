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
OTBaggage class >> clearCurrent [

	| baggage |
	baggage := self empty.
	self current: baggage.
	^ baggage
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
OTBaggage class >> currentBuilder [

	^ self builderFrom: self current
]

{ #category : 'accessing' }
OTBaggage class >> currentEntryAt: aName [

	^ self current entryAt: aName
]

{ #category : 'accessing' }
OTBaggage class >> currentEntryAt: aName ifAbsent: aBlock [

	^ self current entryAt: aName ifAbsent: aBlock
]

{ #category : 'accessing' }
OTBaggage class >> currentValueAt: aName [

	^ self current valueAt: aName
]

{ #category : 'accessing' }
OTBaggage class >> currentValueAt: aName ifAbsent: aBlock [

	^ self current valueAt: aName ifAbsent: aBlock
]

{ #category : 'accessing' }
OTBaggage class >> currentWithEntryNamed: aName value: aValue [

	^ self currentWithEntryNamed: aName value: aValue metadata: nil
]

{ #category : 'accessing' }
OTBaggage class >> currentWithEntryNamed: aName value: aValue metadata: aMetadata [

	| baggage |
	baggage := self current
		withEntryNamed: aName
		value: aValue
		metadata: aMetadata.
	self current: baggage.
	^ baggage
]

{ #category : 'accessing' }
OTBaggage class >> currentWithoutEntryNamed: aName [

	| baggage |
	baggage := self current withoutEntryNamed: aName.
	self current: baggage.
	^ baggage
]

{ #category : 'instance creation' }
OTBaggage class >> empty [

	^ self new
]

{ #category : 'accessing' }
OTBaggage class >> fromContext: aContext [

	aContext ifNil: [ ^ self empty ].
	(aContext isKindOf: OTContext) ifFalse: [
			OTSpan noteIgnoredInvalidArgument: aContext forOperation: 'OTBaggage class>>fromContext:'.
			^ self empty ].
	^ aContext baggage
]

{ #category : 'private' }
OTBaggage class >> normalizedEntryNameFrom: anObject [

	anObject ifNil: [ ^ nil ].
	^ anObject asString
]

{ #category : 'private' }
OTBaggage class >> normalizedEntryValueFrom: anObject [

	anObject ifNil: [ ^ nil ].
	^ anObject asString
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

	| name updatedEntries |
	name := self class normalizedEntryNameFrom: aName.
	name ifNil: [ ^ self ].
	updatedEntries := entriesByName copy.
	updatedEntries removeKey: name.
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

	| name |
	name := self class normalizedEntryNameFrom: aName.
	name ifNil: [ ^ nil ].
	^ entriesByName at: name ifAbsent: [ nil ]
]

{ #category : 'accessing' }
OTBaggage >> entryAt: aName ifAbsent: anAbsentBlock [

	| name |
	name := self class normalizedEntryNameFrom: aName.
	name ifNil: [ ^ anAbsentBlock value ].
	^ entriesByName at: name ifAbsent: anAbsentBlock
]

{ #category : 'comparing' }
OTBaggage >> hash [

	^ entriesByName hash
]

{ #category : 'accessing' }
OTBaggage >> inContext: aContext [

	| baseContext |
	baseContext := aContext ifNil: [ OTContext new ] ifNotNil: [
			               (aContext isKindOf: OTContext)
				               ifTrue: [ aContext ]
				               ifFalse: [
						               OTSpan noteIgnoredInvalidArgument: aContext forOperation: 'OTBaggage>>inContext:'.
						               OTContext new ] ].
	^ baseContext withBaggage: self
]

{ #category : 'testing' }
OTBaggage >> includesEntryNamed: aName [

	| name |
	name := self class normalizedEntryNameFrom: aName.
	name ifNil: [ ^ false ].
	^ entriesByName includesKey: name
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

	| name updatedEntries value |
	name := self class normalizedEntryNameFrom: aName.
	value := self class normalizedEntryValueFrom: aValue.
	(name isNil or: [ value isNil ]) ifTrue: [ ^ self ].
	updatedEntries := entriesByName copy.
	updatedEntries
		at: name
		put: (OTBaggageEntry value: value metadata: aMetadataString).
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

	| name |
	name := self class normalizedEntryNameFrom: aName.
	name ifNil: [ ^ self ].
	(entriesByName includesKey: name) ifFalse: [ ^ self ].
	^ self copyWithoutEntryNamed: aName
]
