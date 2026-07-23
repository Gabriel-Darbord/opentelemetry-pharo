"
Shared helpers for consistent probability sampling threshold and randomness handling.
"
Class {
	#name : 'OTConsistentProbability',
	#superclass : 'Object',
	#category : 'OpenTelemetry-Sampling',
	#package : 'OpenTelemetry-Sampling'
}

{ #category : 'private' }
OTConsistentProbability class >> defaultThresholdPrecision [

	^ 4
]

{ #category : 'private' }
OTConsistentProbability class >> isLowercaseHexString: aString maxSize: anInteger [

	aString ifNil: [ ^ false ].
	aString isEmpty ifTrue: [ ^ false ].
	aString size <= anInteger ifFalse: [ ^ false ].
	^ aString allSatisfy: [ :each | each isDigit or: [ 'abcdef' includes: each ] ]
]

{ #category : 'accessing' }
OTConsistentProbability class >> minimumProbability [

	^ 1 / self modulus
]

{ #category : 'private' }
OTConsistentProbability class >> modulus [

	^ 1 bitShift: 56
]

{ #category : 'private' }
OTConsistentProbability class >> newRandomnessValue [

	^ Integer
		  readFrom: (String streamContents: [ :stream | 14 timesRepeat: [ stream nextPut: OTSpanContext randomHexDigit ] ]) readStream
		  base: 16
]

{ #category : 'private' }
OTConsistentProbability class >> randomnessValueFromTraceId: aTraceId traceState: aTraceState [

	| explicitRandomness |
	explicitRandomness := aTraceState ifNotNil: [ aTraceState otelValueAt: 'rv' ].
	(self usesExplicitRandomness: explicitRandomness) ifTrue: [ ^ Integer readFrom: explicitRandomness readStream base: 16 ].
	^ Integer readFrom: (aTraceId copyFrom: aTraceId size - 13 to: aTraceId size) readStream base: 16
]

{ #category : 'private' }
OTConsistentProbability class >> roundedThresholdPrefixLengthFor: aThresholdString [

	| leadingFs |
	leadingFs := 0.
	[ leadingFs < aThresholdString size and: [ (aThresholdString at: leadingFs + 1) = $f ] ] whileTrue: [ leadingFs := leadingFs + 1 ].
	^ (self defaultThresholdPrecision + leadingFs max: 1) min: aThresholdString size - 1
]

{ #category : 'private' }
OTConsistentProbability class >> sampledWithRandomness: aRandomnessValue threshold: aThreshold [

	^ aRandomnessValue >= aThreshold
]

{ #category : 'private' }
OTConsistentProbability class >> thresholdForProbability: aNumber [

	| exactThreshold paddedThreshold prefixLength quantizedThreshold roundingUnit roundedPrefix |
	aNumber = 1 ifTrue: [ ^ 0 ].
	exactThreshold := ((1 - aNumber) asFraction * self modulus) floor asInteger.
	paddedThreshold := String streamContents: [ :string | self writeThreshold: exactThreshold on: string ].
	prefixLength := self roundedThresholdPrefixLengthFor: paddedThreshold.
	roundingUnit := 16 raisedToInteger: paddedThreshold size - prefixLength.
	roundedPrefix := exactThreshold + (roundingUnit // 2) // roundingUnit.
	roundedPrefix >= (16 raisedToInteger: prefixLength) ifTrue: [ roundedPrefix := (16 raisedToInteger: prefixLength) - 1 ].
	quantizedThreshold := roundedPrefix * roundingUnit.
	^ quantizedThreshold
]

{ #category : 'private' }
OTConsistentProbability class >> thresholdFromString: aString [

	(self isLowercaseHexString: aString maxSize: 14) ifFalse: [ ^ nil ].
	^ Integer readFrom: (aString , (String new: 14 - aString size withAll: $0)) readStream base: 16
]

{ #category : 'private' }
OTConsistentProbability class >> thresholdFromTraceState: aTraceState [

	aTraceState ifNil: [ ^ nil ].
	^ self thresholdFromString: (aTraceState otelValueAt: 'th')
]

{ #category : 'private' }
OTConsistentProbability class >> thresholdStringFor: anInteger [

	| end padded |
	padded := String streamContents: [ :string | self writeThreshold: anInteger on: string ].
	end := padded size.
	[ end > 1 and: [ (padded at: end) = $0 ] ] whileTrue: [ end := end - 1 ].
	^ padded copyFrom: 1 to: end
]

{ #category : 'private' }
OTConsistentProbability class >> usesExplicitRandomness: aString [

	^ OTSpanContext isLowercaseHexString: aString size: 14
]

{ #category : 'private' }
OTConsistentProbability class >> writeThreshold: anInteger on: aStream [

	| digits |
	digits := '0123456789abcdef'.
	14 to: 1 by: -1 do: [ :index |
			| nibble |
			nibble := (anInteger bitShift: (index - 1 * 4) negated) bitAnd: 16rF.
			aStream nextPut: (digits at: nibble + 1) ]
]
