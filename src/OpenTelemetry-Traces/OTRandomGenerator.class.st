"
I draw the random bits that trace and span identifiers are made of, and the randomness that sampling compares with a threshold.

Each session of the image has its own generator, seeded at its first use in that session from the operating system's random device where there is one, the time to the microsecond, how long the VM has run and where the image is. Pharo's shared generator is seeded afresh at each start too, but from the milliseconds since the VM started and an identity hash, both nearly the same at every start of a saved image, so that its identifiers repeated from one start to the next.

I am xoshiro128**, so that every supported Pharo draws from 128 bits of state, which Pharo's own generator does not have on all of them.
"
Class {
	#name : 'OTRandomGenerator',
	#superclass : 'Object',
	#instVars : [
		'state'
	],
	#classVars : [
		'Current',
		'CurrentSession',
		'Lock'
	],
	#category : 'OpenTelemetry-Traces',
	#package : 'OpenTelemetry-Traces'
}

{ #category : 'private' }
OTRandomGenerator class >> entropy [
	"Bytes that differ from one session of the image to the next, and from one image or machine to another. A source that fails is left out."

	^ ByteArray streamContents: [ :stream |
			  {
				  [ self operatingSystemRandomBytes ].
				  [ Time primUTCMicrosecondsClock asByteArray ].
				  [ Time millisecondClockValue asByteArray ].
				  [ Smalltalk imagePath utf8Encoded ] } do: [ :each |
					  [ stream nextPutAll: each value ]
						  on: Error
						  do: [ :error | error return: nil ] ] ]
]

{ #category : 'accessing' }
OTRandomGenerator class >> generatorFor: aSession [
	"The generator of aSession of the image, seeded at its first use in that session."

	^ self lock critical: [ self unlockedGeneratorFor: aSession ]
]

{ #category : 'class initialization' }
OTRandomGenerator class >> initialize [

	Lock := Mutex new
]

{ #category : 'private' }
OTRandomGenerator class >> lock [
	"A mutex, which the process holding it enters again: reading the entropy may draw bits itself, as when the code it runs is instrumented."

	^ Lock ifNil: [ Lock := Mutex new ]
]

{ #category : 'private' }
OTRandomGenerator class >> mix: anInteger [
	"A 32-bit integer that every bit of the 32-bit anInteger affects, different for each anInteger (MurmurHash3's finalizer)."

	| hash |
	hash := (anInteger bitXor: (anInteger bitShift: -16)) * 16r85EBCA6B bitAnd: 16rFFFFFFFF.
	hash := (hash bitXor: (hash bitShift: -13)) * 16rC2B2AE35 bitAnd: 16rFFFFFFFF.
	^ hash bitXor: (hash bitShift: -16)
]

{ #category : 'drawing' }
OTRandomGenerator class >> nextBits: anInteger [
	"A random integer from 0 to 2 raised to anInteger, excluded, from the generator of this session of the image."

	^ self lock critical: [ (self unlockedGeneratorFor: Smalltalk session) nextBits: anInteger ]
]

{ #category : 'instance creation' }
OTRandomGenerator class >> onState: anArray [
	"A generator in the state of anArray, four 32-bit integers that are not all zero."

	^ self new setState: anArray
]

{ #category : 'private' }
OTRandomGenerator class >> operatingSystemRandomBytes [
	"Random bytes from the operating system's random device, or none where there is none."

	OSPlatform current isWindows ifTrue: [ ^ #[  ] ].
	^ '/dev/urandom' asFileReference binaryReadStreamDo: [ :stream | stream next: 16 ]
]

{ #category : 'class initialization' }
OTRandomGenerator class >> reset [
	"Forgets the generator, as a new session of the image does: the next bits come from one seeded afresh."

	self lock critical: [
			Current := nil.
			CurrentSession := nil ]
]

{ #category : 'instance creation' }
OTRandomGenerator class >> seededFrom: aByteArray [
	"A generator whose state is drawn from aByteArray: the same bytes give the same generator."

	| words |
	words := Array new: 4 withAll: 0.
	1 to: aByteArray size by: 4 do: [ :start |
			| chunk index |
			chunk := 0.
			start to: (start + 3 min: aByteArray size) do: [ :each | chunk := (chunk bitShift: 8) + (aByteArray at: each) ].
			index := start - 1 // 4 \\ 4 + 1.
			words at: index put: (self mix: ((words at: index) bitXor: chunk)) ].
	words := (1 to: 4) collect: [ :index | self mix: ((words at: index) + (index * 16r9E3779B9) bitAnd: 16rFFFFFFFF) ].
	(words allSatisfy: [ :each | each = 0 ]) ifTrue: [ words at: 1 put: 1 ].
	^ self onState: words
]

{ #category : 'private' }
OTRandomGenerator class >> unlockedGeneratorFor: aSession [
	"A generator saved with the image would draw, at every start from the saved file, what it drew after the save. Bits drawn while the entropy is read come from the clock alone."

	(Current notNil and: [ CurrentSession == aSession ]) ifFalse: [
			Current := self seededFrom: Time primUTCMicrosecondsClock asByteArray.
			CurrentSession := aSession.
			Current := self seededFrom: self entropy ].
	^ Current
]

{ #category : 'drawing' }
OTRandomGenerator >> next32 [
	"The next 32 random bits."

	| result s0 s1 s2 s3 t |
	s0 := state at: 1.
	s1 := state at: 2.
	s2 := state at: 3.
	s3 := state at: 4.
	result := (self rotate: (s1 * 5 bitAnd: 16rFFFFFFFF) left: 7) * 9 bitAnd: 16rFFFFFFFF.
	t := (s1 bitShift: 9) bitAnd: 16rFFFFFFFF.
	s2 := s2 bitXor: s0.
	s3 := s3 bitXor: s1.
	s1 := s1 bitXor: s2.
	s0 := s0 bitXor: s3.
	s2 := s2 bitXor: t.
	s3 := self rotate: s3 left: 11.
	state
		at: 1 put: s0;
		at: 2 put: s1;
		at: 3 put: s2;
		at: 4 put: s3.
	^ result
]

{ #category : 'drawing' }
OTRandomGenerator >> nextBits: anInteger [
	"A random integer from 0 to 2 raised to anInteger, excluded."

	| bits count |
	bits := 0.
	count := 0.
	[ count < anInteger ] whileTrue: [
			bits := (bits bitShift: 32) bitOr: self next32.
			count := count + 32 ].
	^ bits bitShift: anInteger - count
]

{ #category : 'private' }
OTRandomGenerator >> rotate: anInteger left: aNumber [

	^ ((anInteger bitShift: aNumber) bitAnd: 16rFFFFFFFF) bitOr: (anInteger bitShift: aNumber - 32)
]

{ #category : 'private' }
OTRandomGenerator >> setState: anArray [

	state := anArray asArray copy
]
