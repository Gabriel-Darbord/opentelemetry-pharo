Class {
	#name : 'OTRandomGeneratorTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'running' }
OTRandomGeneratorTest >> tearDown [

	OTRandomGenerator reset.
	super tearDown
]

{ #category : 'tests' }
OTRandomGeneratorTest >> testAGeneratorDrawsXoshiro128StarStar [

	| generator |
	generator := OTRandomGenerator onState: #( 1 2 3 4 ).
	self
		assert: ((1 to: 10) collect: [ :each | generator next32 ])
		equals: #( 11520 0 5927040 70819200 2031721883 1637235492 1287239034 3734860849 3729100597 4258142804 )
]

{ #category : 'tests' }
OTRandomGeneratorTest >> testASessionKeepsItsGeneratorAndTheNextOneSeedsItsOwn [

	| first second |
	first := Object new.
	second := Object new.
	self assert: (OTRandomGenerator generatorFor: first) identicalTo: (OTRandomGenerator generatorFor: first).
	self deny: (OTRandomGenerator generatorFor: first) identicalTo: (OTRandomGenerator generatorFor: second).
	self
		deny: ((OTRandomGenerator generatorFor: first) nextBits: 128)
		equals: ((OTRandomGenerator generatorFor: second) nextBits: 128)
]

{ #category : 'tests' }
OTRandomGeneratorTest >> testBitsDrawnWhileTheEntropyIsReadDoNotWaitForIt [

	| bits done |
	done := Semaphore new.
	[
		bits := OTRandomGeneratorDrawingWhileSeeded nextBits: 64.
		done signal ] fork.
	self deny: (done waitTimeoutMilliseconds: 2000).
	self assert: bits isInteger
]

{ #category : 'tests' }
OTRandomGeneratorTest >> testEachStartDrawsOtherIdentifiers [
	"A start from the saved image makes a new session, which reset stands for."

	| spanIds traceIds |
	traceIds := Set new.
	spanIds := Set new.
	10 timesRepeat: [
			OTRandomGenerator reset.
			traceIds add: OTIdGenerator default generateTraceIdHex.
			spanIds add: OTIdGenerator default generateSpanIdHex ].
	self assert: traceIds size equals: 10.
	self assert: spanIds size equals: 10
]

{ #category : 'tests' }
OTRandomGeneratorTest >> testIdentifiersAreLowercaseHexOfTheirSizeAndDoNotRepeat [

	| spanIds traceIds |
	traceIds := (1 to: 1000) collect: [ :each | OTSpanContext newTraceId ].
	spanIds := (1 to: 1000) collect: [ :each | OTSpanContext newSpanId ].
	self assert: traceIds asSet size equals: 1000.
	self assert: spanIds asSet size equals: 1000.
	self assert: (traceIds allSatisfy: [ :each | OTSpanContext isLowercaseHexString: each size: 32 ]).
	self assert: (spanIds allSatisfy: [ :each | OTSpanContext isLowercaseHexString: each size: 16 ])
]

{ #category : 'tests' }
OTRandomGeneratorTest >> testNextBitsAnswersThatManyBits [

	| generator reference |
	reference := OTRandomGenerator onState: #( 1 2 3 4 ).
	generator := OTRandomGenerator onState: #( 1 2 3 4 ).
	self assert: (generator nextBits: 0) equals: 0.
	self assert: (generator nextBits: 36) equals: ((reference next32 bitShift: 32) + reference next32 bitShift: -28).
	1000 timesRepeat: [
			self assert: ((generator nextBits: 4) between: 0 and: 15).
			self assert: ((generator nextBits: 128) between: 0 and: (2 raisedTo: 128) - 1) ]
]

{ #category : 'tests' }
OTRandomGeneratorTest >> testTheEntropyDiffersEachTime [
	"What a start seeds its generator from: the same image started twice, with its identity hashes and how long the VM has run the same, still seeds two generators."

	self deny: OTRandomGenerator entropy equals: OTRandomGenerator entropy
]

{ #category : 'tests' }
OTRandomGeneratorTest >> testTheOperatingSystemGivesRandomBytesWhereItHasARandomDevice [

	OSPlatform current isWindows ifTrue: [ ^ self skip ].
	self assert: OTRandomGenerator operatingSystemRandomBytes size equals: 16.
	self deny: OTRandomGenerator operatingSystemRandomBytes equals: OTRandomGenerator operatingSystemRandomBytes
]

{ #category : 'tests' }
OTRandomGeneratorTest >> testTheSameBytesSeedTheSameGenerator [

	self
		assert: ((OTRandomGenerator seededFrom: #[ 1 2 3 4 5 6 7 8 9 ]) nextBits: 128)
		equals: ((OTRandomGenerator seededFrom: #[ 1 2 3 4 5 6 7 8 9 ]) nextBits: 128).
	self
		deny: ((OTRandomGenerator seededFrom: #[ 1 2 3 4 5 6 7 8 9 ]) nextBits: 128)
		equals: ((OTRandomGenerator seededFrom: #[ 1 2 3 4 5 6 7 8 10 ]) nextBits: 128).
	self deny: ((OTRandomGenerator seededFrom: #[  ]) nextBits: 128) equals: 0
]
