"
I enforce a minimum sampling interval using a very low-overhead time check.

This sampler is optimized for instrumentation hot paths. It uses a fast millisecond clock and keeps the decision logic intentionally simple to minimize runtime cost.

The design favors performance over strict synchronization guarantees. When the same sampler instance is shared concurrently, sampling remains best-effort: contention may allow more than one sample within an interval, and exact minimum-interval guarantees are not enforced across threads.

The clock can roll over, but *rarely*. Assuming 31 bits, a cycle lasts `((2 raisedTo: 31) - 1) milliSeconds days` = 24 days. The clock is also restarted along with the VM. For performance reasons, sampling is accepted in both scenarios, ignoring the interval.
"
Class {
	#name : 'OTTimeIntervalSampler',
	#superclass : 'OTSampler',
	#instVars : [
		'interval',
		'last'
	],
	#category : 'OpenTelemetry-Sampling',
	#package : 'OpenTelemetry-Sampling'
}

{ #category : 'class initialization' }
OTTimeIntervalSampler class >> initialize [
	"See class comment"

	SessionManager default registerToolClassNamed: self name
]

{ #category : 'system startup' }
OTTimeIntervalSampler class >> startUp: resuming [
	"See class comment"

	resuming ifTrue: [
		self allInstancesDo: [ :instance | instance reset ] ]
]

{ #category : 'initialization' }
OTTimeIntervalSampler >> initialize [

	super initialize.
	self reset
]

{ #category : 'accessing' }
OTTimeIntervalSampler >> interval: anInteger [
	"In milliseconds, should be >0.
	Avoid using a 0ms interval, it works but there is no fast path for it."

	interval := anInteger
]

{ #category : 'initialization' }
OTTimeIntervalSampler >> reset [
	"See class comment"

	last := SmallInteger maxVal
]

{ #category : 'asserting' }
OTTimeIntervalSampler >> shouldSample [

	| now elapsed |
	now := Time millisecondClockValue. "optimal(?) primitive for getting a clock input"
	elapsed := now - last.

	(elapsed >= interval or: [ "clock roll over?" elapsed < 0 ]) ifTrue: [
		last := now.
		^ true ].

	^ false
]
