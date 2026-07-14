Class {
	#name : 'OTTraceIdRatioBasedSampler',
	#superclass : 'OTSampler',
	#instVars : [
		'probability',
		'threshold'
	],
	#category : 'OpenTelemetry-Sampling',
	#package : 'OpenTelemetry-Sampling'
}

{ #category : 'private' }
OTTraceIdRatioBasedSampler >> decisionValueFromTraceId: aTraceId [

	| offset highBits lowBits |
	offset := aTraceId size - 15.
	highBits := Integer readFrom: ((aTraceId copyFrom: 1 to: 16) readStream) base: 16.
	lowBits := Integer readFrom: ((aTraceId copyFrom: offset to: aTraceId size) readStream) base: 16.
	^ highBits bitXor: lowBits
]

{ #category : 'accessing' }
OTTraceIdRatioBasedSampler >> description [

	^ 'TraceIdRatioBased{', self probability printString, '}'
]

{ #category : 'initialization' }
OTTraceIdRatioBasedSampler >> initialize [

	super initialize.
	self probability: 1
]

{ #category : 'accessing' }
OTTraceIdRatioBasedSampler >> probability [

	^ probability
]

{ #category : 'accessing' }
OTTraceIdRatioBasedSampler >> probability: aNumber [

	(aNumber isNumber and: [ aNumber >= 0 and: [ aNumber <= 1 ] ]) ifFalse: [
		Error signal: 'Sampling probability must be a number between 0 and 1' ].
	probability := aNumber.
	threshold := self thresholdForProbability: probability.
	^ self
]

{ #category : 'asserting' }
OTTraceIdRatioBasedSampler >> shouldSample [

	^ self shouldSampleTraceId: OTSpan newTraceId
]

{ #category : 'sampling' }
OTTraceIdRatioBasedSampler >> shouldSampleIn: aContext traceId: aTraceId name: aString kind: aSpanKind attributes: someAttributes links: someLinks [

	^ (self shouldSampleTraceId: aTraceId)
		ifTrue: [ OTSamplingResult recordAndSample ]
		ifFalse: [ OTSamplingResult drop ]
]

{ #category : 'private' }
OTTraceIdRatioBasedSampler >> shouldSampleTraceId: aTraceId [

	threshold = 0 ifTrue: [ ^ false ].
	threshold = (1 bitShift: 64) ifTrue: [ ^ true ].
	^ (self decisionValueFromTraceId: aTraceId) < threshold
]

{ #category : 'private' }
OTTraceIdRatioBasedSampler >> thresholdForProbability: aNumber [

	aNumber = 0 ifTrue: [ ^ 0 ].
	aNumber = 1 ifTrue: [ ^ 1 bitShift: 64 ].
	^ ((aNumber asFraction * (1 bitShift: 64)) ceiling) asInteger
]
