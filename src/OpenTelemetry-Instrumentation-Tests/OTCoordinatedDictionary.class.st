Class {
	#name : 'OTCoordinatedDictionary',
	#superclass : 'Object',
	#instVars : [
		'members',
		'lookupEntered',
		'lookupRelease',
		'lookupCount',
		'stateLock'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'accessing' }
OTCoordinatedDictionary >> at: aKey ifAbsentPut: aBlock [

	| value |
	stateLock critical: [ lookupCount := lookupCount + 1 ].
	lookupEntered signal.
	lookupRelease wait.
	value := members at: aKey ifAbsent: [
			         | created |
			         created := aBlock value.
			         members at: aKey put: created.
			         created ].
	^ value
]

{ #category : 'initialization' }
OTCoordinatedDictionary >> initialize [

	super initialize.
	members := IdentityDictionary new.
	lookupEntered := Semaphore new.
	lookupRelease := Semaphore new.
	lookupCount := 0.
	stateLock := Semaphore forMutualExclusion
]

{ #category : 'testing' }
OTCoordinatedDictionary >> lookupCount [

	^ stateLock critical: [ lookupCount ]
]

{ #category : 'control' }
OTCoordinatedDictionary >> releaseLookup [

	lookupRelease signal.
	self
]

{ #category : 'testing' }
OTCoordinatedDictionary >> waitForLookupTimeoutMillis: anInteger [

	^ (lookupEntered waitTimeoutMilliseconds: anInteger) not
]
