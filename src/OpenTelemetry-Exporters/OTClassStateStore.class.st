"
I provide version-neutral class-side state storage for OpenTelemetry internals.
"
Class {
	#name : 'OTClassStateStore',
	#superclass : 'Object',
	#classInstVars : [
		'stateByClass'
	],
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'accessing' }
OTClassStateStore class >> removeValueAt: aKey forClass: aBehavior ifAbsent: aBlock [

	| classState answer |
	classState := self stateByClass at: aBehavior ifAbsent: [ ^ aBlock value ].
	answer := classState removeKey: aKey ifAbsent: aBlock.
	classState isEmpty ifTrue: [
		self stateByClass removeKey: aBehavior ifAbsent: [  ] ].
	^ answer
]

{ #category : 'class initialization' }
OTClassStateStore class >> reset [

	stateByClass := nil
]

{ #category : 'private' }
OTClassStateStore class >> stateByClass [

	^ stateByClass ifNil: [ stateByClass := WeakIdentityKeyDictionary new ]
]

{ #category : 'private' }
OTClassStateStore class >> stateFor: aBehavior [

	^ self stateByClass
		at: aBehavior
		ifAbsentPut: [ Dictionary new ]
]

{ #category : 'accessing' }
OTClassStateStore class >> valueAt: aKey forClass: aBehavior ifAbsent: aBlock [

	| classState |
	classState := self stateByClass at: aBehavior ifAbsent: [ ^ aBlock value ].
	^ classState at: aKey ifAbsent: aBlock
]

{ #category : 'accessing' }
OTClassStateStore class >> valueAt: aKey forClass: aBehavior put: anObject [

	(self stateFor: aBehavior)
		at: aKey
		put: anObject.
	^ anObject
]
