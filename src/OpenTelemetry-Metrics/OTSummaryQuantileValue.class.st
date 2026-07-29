"
I represent one quantile entry inside a summary data point.
I store the quantile rank and its observed value.
"
Class {
	#name : 'OTSummaryQuantileValue',
	#superclass : 'Object',
	#instVars : [
		'quantile',
		'value'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTSummaryQuantileValue class >> quantile: aNumber value: anotherNumber [

	| quantileValue |
	quantileValue := self new.
	quantileValue
		quantile: aNumber;
		value: anotherNumber.
	^ quantileValue
]

{ #category : 'accessing' }
OTSummaryQuantileValue >> quantile [

	^ quantile ifNil: [ 0.0 ]
]

{ #category : 'accessing' }
OTSummaryQuantileValue >> quantile: aNumber [

	quantile := aNumber ifNil: [ 0.0 ] ifNotNil: [ aNumber ]
]

{ #category : 'accessing' }
OTSummaryQuantileValue >> value [

	^ value ifNil: [ 0.0 ]
]

{ #category : 'accessing' }
OTSummaryQuantileValue >> value: anObject [

	value := anObject ifNil: [ 0.0 ] ifNotNil: [
			         anObject isNumber
				         ifFalse: [ 0.0 ]
				         ifTrue: [
						         | numericValue |
						         numericValue := anObject asFloat.
						         (numericValue isNaN or: [ numericValue negative ])
							         ifTrue: [ 0.0 ]
							         ifFalse: [ anObject ] ] ]
]
