Class {
	#name : 'OTClassStateStoreTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'running' }
OTClassStateStoreTest >> setUp [

	super setUp.
	OTClassStateStore reset.
	OTClassStateStore initialize
]

{ #category : 'running' }
OTClassStateStoreTest >> tearDown [

	OTClassStateStore reset.
	super tearDown
]

{ #category : 'tests' }
OTClassStateStoreTest >> testStateAccessIsSerializedOnFirstConcurrentWrite [

	| firstDone secondDone store |
	store := OTCoordinatedDictionary new.
	OTClassStateStore stateByClassForTesting: store.
	firstDone := Semaphore new.
	secondDone := Semaphore new.
	[
		[
			OTClassStateStore valueAt: #demo forClass: OTSpanExporter put: 1.
			firstDone signal ] forkAt: Processor userBackgroundPriority.
		self assert: (store waitForLookupTimeoutMillis: 200).
		[
			OTClassStateStore valueAt: #other forClass: OTSpanExporter put: 2.
			secondDone signal ] forkAt: Processor userBackgroundPriority.
		self assert: (secondDone waitTimeoutMilliseconds: 50).
		self deny: (store waitForLookupTimeoutMillis: 50).
		store releaseLookup.
		self assert: (firstDone waitTimeoutMilliseconds: 200) not.
		self assert: (store waitForLookupTimeoutMillis: 200).
		store releaseLookup.
		self assert: (secondDone waitTimeoutMilliseconds: 200) not.
		self assert: store lookupCount equals: 2 ] ensure: [
			store releaseLookup.
			store releaseLookup.
			OTClassStateStore reset.
			OTClassStateStore initialize ]
]
