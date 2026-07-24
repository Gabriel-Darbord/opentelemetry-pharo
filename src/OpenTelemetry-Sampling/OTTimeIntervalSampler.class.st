"
I enforce a minimum sampling interval using a very low-overhead time check.

This sampler is optimized for instrumentation hot paths. It uses a fast millisecond clock and keeps the decision logic intentionally simple to minimize runtime cost.

The current implementation is safe to share across concurrent Pharo processes. A mutex protects the interval state so one shared sampler instance still enforces at most one accepted sample per interval.

The clock can roll over, but *rarely*. Assuming 31 bits, a cycle lasts `((2 raisedTo: 31) - 1) milliSeconds days` = 24 days. The clock is also restarted along with the VM. For performance reasons, sampling is accepted in both scenarios, ignoring the interval.
"
Class {
	#name : 'OTTimeIntervalSampler',
	#superclass : 'OTSampler',
	#instVars : [
		'interval',
		'last',
		'stateLock'
	],
	#category : 'OpenTelemetry-Sampling',
	#package : 'OpenTelemetry-Sampling'
}

{ #category : 'accessing' }
OTTimeIntervalSampler >> description [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'TimeIntervalSampler{';
				  print: self interval;
				  nextPutAll: 'ms}' ]
]

{ #category : 'initialization' }
OTTimeIntervalSampler >> initialize [

	super initialize.
	interval := 0.
	last := nil.
	stateLock := Semaphore forMutualExclusion
]

{ #category : 'accessing' }
OTTimeIntervalSampler >> interval [

	^ stateLock critical: [ interval ]
]

{ #category : 'accessing' }
OTTimeIntervalSampler >> interval: anInteger [

	(anInteger isInteger and: [ anInteger >= 0 ]) ifFalse: [
		Error signal: 'Sampling interval must be a non-negative integer number of milliseconds' ].
	stateLock critical: [ interval := anInteger ]
]

{ #category : 'initialization' }
OTTimeIntervalSampler >> reset [

	stateLock critical: [ last := nil ]
]

{ #category : 'asserting' }
OTTimeIntervalSampler >> shouldSample [

	^ stateLock critical: [
			  | now previous |
			  now := Time millisecondClockValue.
			  previous := last.
			  previous ifNil: [
					  last := now.
					  ^ true ].
			  (now < previous or: [ now - previous >= interval ]) ifTrue: [
					  last := now.
					  ^ true ].
			  false ]
]
