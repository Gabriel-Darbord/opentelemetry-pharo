Class {
	#name : 'OTCoordinatedMembershipSet',
	#superclass : 'Object',
	#instVars : [
		'members',
		'includesEntered',
		'includesRelease',
		'addCount',
		'includesCount',
		'stateLock'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'accessing' }
OTCoordinatedMembershipSet >> add: anObject [

	stateLock critical: [ addCount := addCount + 1 ].
	^ members add: anObject
]

{ #category : 'testing' }
OTCoordinatedMembershipSet >> addCount [

	^ stateLock critical: [ addCount ]
]

{ #category : 'testing' }
OTCoordinatedMembershipSet >> includes: anObject [

	| includesMember |
	includesMember := members includes: anObject.
	stateLock critical: [ includesCount := includesCount + 1 ].
	includesEntered signal.
	includesRelease wait.
	^ includesMember
]

{ #category : 'initialization' }
OTCoordinatedMembershipSet >> initialize [

	super initialize.
	members := IdentitySet new.
	includesEntered := Semaphore new.
	includesRelease := Semaphore new.
	addCount := 0.
	includesCount := 0.
	stateLock := Semaphore forMutualExclusion
]

{ #category : 'control' }
OTCoordinatedMembershipSet >> releaseIncludes [

	includesRelease signal.
	self
]

{ #category : 'testing' }
OTCoordinatedMembershipSet >> waitForIncludesTimeoutMillis: anInteger [

	^ (includesEntered waitTimeoutMilliseconds: anInteger) not
]
