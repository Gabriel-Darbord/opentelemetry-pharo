Class {
	#name : 'OTLifecycleResult',
	#superclass : 'Object',
	#instVars : [
		'status'
	],
	#category : 'OpenTelemetry-SDK',
	#package : 'OpenTelemetry-SDK'
}

{ #category : 'instance creation' }
OTLifecycleResult class >> failure [

	^ self new
		  status: #failure;
		  yourself
]

{ #category : 'instance creation' }
OTLifecycleResult class >> fromBoolean: aBoolean [

	^ aBoolean
		  ifTrue: [ self success ]
		  ifFalse: [ self failure ]
]

{ #category : 'instance creation' }
OTLifecycleResult class >> success [

	^ self new
		  status: #success;
		  yourself
]

{ #category : 'instance creation' }
OTLifecycleResult class >> timeout [

	^ self new
		  status: #timeout;
		  yourself
]

{ #category : 'combining' }
OTLifecycleResult >> combinedWith: anotherResult [

	anotherResult ifNil: [ ^ self ].
	self isTimeout ifTrue: [ ^ self ].
	anotherResult isTimeout ifTrue: [ ^ anotherResult ].
	self isFailure ifTrue: [ ^ self ].
	anotherResult isFailure ifTrue: [ ^ anotherResult ].
	^ self class success
]

{ #category : 'initialization' }
OTLifecycleResult >> initialize [

	super initialize.
	status := #failure
]

{ #category : 'testing' }
OTLifecycleResult >> isFailure [

	^ status = #failure
]

{ #category : 'testing' }
OTLifecycleResult >> isSuccess [

	^ status = #success
]

{ #category : 'testing' }
OTLifecycleResult >> isTimeout [

	^ status = #timeout
]

{ #category : 'printing' }
OTLifecycleResult >> printOn: aStream [

	super printOn: aStream.
	aStream
		nextPut: $(;
		nextPutAll: status asString;
		nextPut: $)
]

{ #category : 'accessing' }
OTLifecycleResult >> status [

	^ status
]

{ #category : 'accessing' }
OTLifecycleResult >> status: aSymbol [

	status := aSymbol
]
