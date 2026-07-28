Class {
	#name : 'OTSummaryQuantileValueTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Metrics-Tests',
	#package : 'OpenTelemetry-Metrics-Tests'
}

{ #category : 'tests' }
OTSummaryQuantileValueTest >> testValueNormalizesInvalidNumbersToZero [

	| quantile |
	quantile := OTSummaryQuantileValue quantile: 0.9 value: Float negativeInfinity.
	self assert: quantile value equals: 0.0.
	quantile value: -3.5.
	self assert: quantile value equals: 0.0.
	quantile value: Float nan.
	self assert: quantile value equals: 0.0
]

{ #category : 'tests' }
OTSummaryQuantileValueTest >> testValuePreservesNonNegativeNumbers [

	| quantile |
	quantile := OTSummaryQuantileValue quantile: 0.5 value: 1.5.
	self assert: quantile value equals: 1.5.
	quantile value: Float infinity.
	self assert: quantile value equals: Float infinity.
	quantile value: 0.0.
	self assert: quantile value equals: 0.0
]
