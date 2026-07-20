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

{ #category : 'private - logging' }
OTTraceIdRatioBasedSampler >> childSamplerCompatibilityWarningMessage [

	^ 'WARNING: The TraceIdRatioBased sampler is operating as a child sampler; the behavior is subject to change. Please upgrade this SDK configuration to use ProbabilitySampler.'
]

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

{ #category : 'private - logging' }
OTTraceIdRatioBasedSampler >> probabilityParentCompatibilityWarningMessage [

	^ 'WARNING: The TraceIdRatioBased sampler is operating as a child sampler and a parent is using ProbabilitySampler. Please upgrade this SDK configuration to use ProbabilitySampler.'
]

{ #category : 'private - logging' }
OTTraceIdRatioBasedSampler >> shouldEmitCompatibilityWarningForParentSpan: aSpan [

	^ aSpan notNil and: [ aSpan spanContext isValid ]
]

{ #category : 'asserting' }
OTTraceIdRatioBasedSampler >> shouldSample [

	^ self shouldSampleTraceId: OTSpanContext newTraceId
]

{ #category : 'sampling' }
OTTraceIdRatioBasedSampler >> shouldSampleIn: aContext traceId: aTraceId name: aString kind: aSpanKind attributes: someAttributes links: someLinks [

	| parentSpan |
	parentSpan := aContext ifNotNil: [ aContext span ].
	(self shouldEmitCompatibilityWarningForParentSpan: parentSpan) ifTrue: [
		self class
			noteCompatibilityWarning: (self warningMessageForParentSpan: parentSpan)
			kind: #childSampler
			for: self ].
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

{ #category : 'private - logging' }
OTTraceIdRatioBasedSampler >> usesProbabilitySamplerTraceState: aTraceState [

	aTraceState ifNil: [ ^ false ].
	^ (aTraceState otelValueAt: 'rv') notNil
		or: [ (aTraceState otelValueAt: 'th') notNil ]
]

{ #category : 'private - logging' }
OTTraceIdRatioBasedSampler >> warningMessageForParentSpan: aSpan [

	^ (self usesProbabilitySamplerTraceState: aSpan spanContext traceState)
		  ifTrue: [ self probabilityParentCompatibilityWarningMessage ]
		  ifFalse: [ self childSamplerCompatibilityWarningMessage ]
]
