"
I make trace sampling decisions based on a probability rate, allowing traces to be sampled randomly.

For example, with a probability of 0.1, approximately 10% of traces are expected to be sampled.
"
Class {
	#name : 'OTProbabilisticSampler',
	#superclass : 'OTSampler',
	#instVars : [
		'probability',
		'threshold'
	],
	#category : 'OpenTelemetry-Sampling',
	#package : 'OpenTelemetry-Sampling'
}

{ #category : 'accessing' }
OTProbabilisticSampler >> description [

	^ 'ProbabilitySampler{', self probability printString, '}'
]

{ #category : 'initialization' }
OTProbabilisticSampler >> initialize [

	super initialize.
	self probability: 1
]

{ #category : 'accessing' }
OTProbabilisticSampler >> probability [

	^ probability
]

{ #category : 'accessing' }
OTProbabilisticSampler >> probability: aNumber [

	(aNumber isNumber and: [ aNumber >= 0 and: [ aNumber <= 1 ] ]) ifFalse: [
		Error signal: 'Sampling probability must be a number between 0 and 1' ].
	probability := aNumber.
	threshold := self thresholdForProbability: probability.
	^ self
]

{ #category : 'private' }
OTProbabilisticSampler >> randomnessValueFromTraceId: aTraceId traceState: aTraceState [

	| explicitRandomness |
	explicitRandomness := aTraceState ifNotNil: [ aTraceState otelValueAt: 'rv' ].
	(self usesExplicitRandomness: explicitRandomness) ifTrue: [
		^ Integer readFrom: explicitRandomness readStream base: 16 ].
	^ Integer
		readFrom: ((aTraceId copyFrom: aTraceId size - 13 to: aTraceId size) readStream)
		base: 16
]

{ #category : 'sampling' }
OTProbabilisticSampler >> shouldSample [

	^ self
		shouldSampleTraceId: OTSpanContext newTraceId
		traceState: nil
]

{ #category : 'sampling' }
OTProbabilisticSampler >> shouldSampleIn: aContext traceId: aTraceId name: aString kind: aSpanKind attributes: someAttributes links: someLinks [

	| parentSpan resultTraceState sampled traceState |
	parentSpan := aContext ifNotNil: [ aContext span ].
	traceState := parentSpan ifNotNil: [ parentSpan traceState ].
	sampled := self shouldSampleTraceId: aTraceId traceState: traceState.
	resultTraceState := sampled
		ifTrue: [ self traceStateWithThresholdFrom: traceState ]
		ifFalse: [ traceState ].
	^ OTSamplingResult
		decision: (sampled
				ifTrue: [ #recordAndSample ]
				ifFalse: [ #drop ])
		attributes: #()
		traceState: resultTraceState
]

{ #category : 'private' }
OTProbabilisticSampler >> shouldSampleTraceId: aTraceId traceState: aTraceState [

	| randomness |
	threshold = 0 ifTrue: [ ^ true ].
	threshold = (1 bitShift: 56) ifTrue: [ ^ false ].
	randomness := self
		randomnessValueFromTraceId: aTraceId
		traceState: aTraceState.
	^ randomness >= threshold
]

{ #category : 'private' }
OTProbabilisticSampler >> thresholdForProbability: aNumber [

	aNumber = 1 ifTrue: [ ^ 0 ].
	aNumber = 0 ifTrue: [ ^ 1 bitShift: 56 ].
	^ (((1 - aNumber) asFraction * (1 bitShift: 56)) floor) asInteger
]

{ #category : 'private' }
OTProbabilisticSampler >> thresholdString [

	| end padded |
	padded := String streamContents: [ :string |
		self
			writeThreshold: self threshold
			on: string ].
	end := padded size.
	[ end > 1 and: [ (padded at: end) = $0 ] ] whileTrue: [ end := end - 1 ].
	^ padded copyFrom: 1 to: end
]

{ #category : 'private' }
OTProbabilisticSampler >> traceStateWithThresholdFrom: aTraceState [

	| baseState |
	baseState := aTraceState ifNil: [ OTTraceState empty ] ifNotNil: [ aTraceState ].
	^ baseState
		withOtelValueAt: 'th'
		put: self thresholdString
]

{ #category : 'private' }
OTProbabilisticSampler >> usesExplicitRandomness: aString [

	^ OTSpanContext isLowercaseHexString: aString size: 14
]

{ #category : 'accessing' }
OTProbabilisticSampler >> threshold [

	^ threshold
]

{ #category : 'private' }
OTProbabilisticSampler >> writeThreshold: anInteger on: aStream [

	| digits |
	digits := '0123456789abcdef'.
	14 to: 1 by: -1 do: [ :index |
		| nibble |
		nibble := (anInteger bitShift: ((index - 1) * 4) negated) bitAnd: 16rF.
		aStream nextPut: (digits at: nibble + 1) ]
]
