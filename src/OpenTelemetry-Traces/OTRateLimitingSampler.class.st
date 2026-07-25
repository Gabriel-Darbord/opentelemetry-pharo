"
I implement a leaky-bucket sampler that limits the number of sampled traces
per second.
"
Class {
	#name : 'OTRateLimitingSampler',
	#superclass : 'OTSampler',
	#instVars : [
		'maxTracesPerSecond',
		'maxBalance',
		'balance',
		'lastBalanceUpdate',
		'clockBlock',
		'stateLock'
	],
	#category : 'OpenTelemetry-Traces',
	#package : 'OpenTelemetry-Traces'
}

{ #category : 'accessing' }
OTRateLimitingSampler >> clockBlock: aBlockClosure [

	clockBlock := aBlockClosure
]

{ #category : 'private' }
OTRateLimitingSampler >> currentTimeMillis [

	^ clockBlock value
]

{ #category : 'accessing' }
OTRateLimitingSampler >> description [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'RateLimitingSampler{';
				  print: (self maxTracesPerSecond printShowingDecimalPlaces: 2);
				  nextPutAll: '}' ]
]

{ #category : 'initialization' }
OTRateLimitingSampler >> initialize [

	super initialize.
	clockBlock := [ Time millisecondClockValue ].
	stateLock := Semaphore forMutualExclusion.
	self maxTracesPerSecond: 0
]

{ #category : 'accessing' }
OTRateLimitingSampler >> maxTracesPerSecond [

	^ stateLock critical: [ maxTracesPerSecond ]
]

{ #category : 'accessing' }
OTRateLimitingSampler >> maxTracesPerSecond: anInteger [

	(anInteger isInteger and: [ anInteger >= 0 ]) ifFalse: [
		Error signal: 'Rate-limiting sampler requires a non-negative integer number of traces per second' ].
	stateLock critical: [
			maxTracesPerSecond := anInteger.
			maxBalance := anInteger < 1
				              ifTrue: [ 1.0 ]
				              ifFalse: [ anInteger asFloat ].
			balance := anInteger = 0
				           ifTrue: [ 0.0 ]
				           ifFalse: [ maxBalance ].
			lastBalanceUpdate := nil ].
	^ self maxTracesPerSecond
]

{ #category : 'private' }
OTRateLimitingSampler >> refillBalanceAt: now [

	| elapsed previous |
	previous := lastBalanceUpdate.
	lastBalanceUpdate := now.
	previous ifNil: [ ^ self ].
	now < previous ifTrue: [
			balance := maxBalance.
			^ self ].
	elapsed := now - previous.
	elapsed <= 0 ifTrue: [ ^ self ].
	balance := balance + (elapsed / 1000.0 * maxTracesPerSecond) min: maxBalance
]

{ #category : 'asserting' }
OTRateLimitingSampler >> shouldSample [

	^ stateLock critical: [
			  maxTracesPerSecond = 0 ifTrue: [ ^ false ].
			  self refillBalanceAt: self currentTimeMillis.
			  balance < 1.0 ifTrue: [ ^ false ].
			  balance := balance - 1.0.
			  true ]
]
