"
I provide version-neutral class-side state storage for OpenTelemetry internals.
"
Class {
	#name : 'OTClassStateStore',
	#superclass : 'Object',
	#classInstVars : [
		'stateByClass',
		'stateLock'
	],
	#category : 'OpenTelemetry-SDK',
	#package : 'OpenTelemetry-SDK'
}

{ #category : 'class initialization' }
OTClassStateStore class >> initialize [

	stateLock := Semaphore forMutualExclusion.
	stateByClass ifNil: [ stateByClass := WeakIdentityKeyDictionary new ]
]

{ #category : 'accessing' }
OTClassStateStore class >> currentValueForClass: aBehavior ifAbsent: aBlock [

	^ self valueAt: #otCurrent forClass: aBehavior ifAbsent: aBlock
]

{ #category : 'accessing' }
OTClassStateStore class >> currentValueForClass: aBehavior ifAbsentPut: aBlock [

	^ self valueAt: #otCurrent forClass: aBehavior ifAbsentPut: aBlock
]

{ #category : 'accessing' }
OTClassStateStore class >> currentValueForClass: aBehavior put: anObject [

	^ self valueAt: #otCurrent forClass: aBehavior put: anObject
]

{ #category : 'accessing' }
OTClassStateStore class >> removeValueAt: aKey forClass: aBehavior ifAbsent: aBlock [

	| answer found |
	found := false.
	self stateLock critical: [
			| classState |
			classState := self stateByClassUnlocked at: aBehavior ifAbsent: [ nil ].
			(classState notNil and: [ classState includesKey: aKey ]) ifTrue: [
					answer := classState removeKey: aKey.
					classState isEmpty ifTrue: [ self stateByClassUnlocked removeKey: aBehavior ifAbsent: [ ] ].
					found := true ] ].
	found ifTrue: [ ^ answer ].
	^ aBlock value
]

{ #category : 'accessing' }
OTClassStateStore class >> removeCurrentValueForClass: aBehavior ifAbsent: aBlock [

	^ self removeValueAt: #otCurrent forClass: aBehavior ifAbsent: aBlock
]

{ #category : 'class initialization' }
OTClassStateStore class >> reset [

	self stateLock critical: [ stateByClass := nil ]
]

{ #category : 'private' }
OTClassStateStore class >> stateByClass [

	^ self stateLock critical: [ self stateByClassUnlocked ]
]

{ #category : 'testing' }
OTClassStateStore class >> stateByClassForTesting: aDictionary [

	self stateLock critical: [ stateByClass := aDictionary ].
	^ aDictionary
]

{ #category : 'private' }
OTClassStateStore class >> stateByClassUnlocked [

	^ stateByClass ifNil: [ stateByClass := WeakIdentityKeyDictionary new ]
]

{ #category : 'private' }
OTClassStateStore class >> stateFor: aBehavior [

	^ self stateLock critical: [ self stateByClassUnlocked at: aBehavior ifAbsentPut: [ Dictionary new ] ]
]

{ #category : 'private' }
OTClassStateStore class >> stateLock [

	stateLock ifNil: [ self initialize ].
	^ stateLock
]

{ #category : 'accessing' }
OTClassStateStore class >> valueAt: aKey forClass: aBehavior ifAbsent: aBlock [

	| answer found |
	found := false.
	self stateLock critical: [
			| classState |
			classState := self stateByClassUnlocked at: aBehavior ifAbsent: [ nil ].
			classState ifNotNil: [
					(classState includesKey: aKey) ifTrue: [
							answer := classState at: aKey.
							found := true ] ] ].
	found ifTrue: [ ^ answer ].
	^ aBlock value
]

{ #category : 'accessing' }
OTClassStateStore class >> valueAt: aKey forClass: aBehavior ifAbsentPut: aBlock [

	^ self stateLock critical: [
		  (self stateByClassUnlocked at: aBehavior ifAbsentPut: [ Dictionary new ]) at: aKey ifAbsentPut: aBlock ]
]

{ #category : 'accessing' }
OTClassStateStore class >> valueAt: aKey forClass: aBehavior put: anObject [

	^ self stateLock critical: [ (self stateByClassUnlocked at: aBehavior ifAbsentPut: [ Dictionary new ]) at: aKey put: anObject ]
]

{ #category : 'accessing' }
OTClassStateStore class >> valueAt: aKey forClass: aBehavior putOrRemoveIfNil: anObject [

	anObject
		ifNil: [ self removeValueAt: aKey forClass: aBehavior ifAbsent: [ ] ]
		ifNotNil: [ self valueAt: aKey forClass: aBehavior put: anObject ].
	^ anObject
]
