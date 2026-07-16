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
OTSummaryQuantileValue >> value: aNumber [

	value := aNumber ifNil: [ 0.0 ] ifNotNil: [ aNumber ]
]
