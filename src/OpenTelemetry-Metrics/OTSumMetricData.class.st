Class {
	#name : 'OTSumMetricData',
	#superclass : 'OTMetricData',
	#instVars : [
		'monotonic',
		'temporality'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTSumMetricData class >> instrument: anOTMetricInstrument points: aCollection monotonic: aBoolean [

	| metric |
	metric := self instrument: anOTMetricInstrument points: aCollection.
	metric monotonic: aBoolean.
	metric temporality: #cumulative.
	^ metric
]

{ #category : 'accessing' }
OTSumMetricData >> monotonic [

	^ monotonic = true
]

{ #category : 'accessing' }
OTSumMetricData >> monotonic: aBoolean [

	monotonic := aBoolean = true
]

{ #category : 'accessing' }
OTSumMetricData >> temporality [

	^ temporality ifNil: [ #cumulative ]
]

{ #category : 'accessing' }
OTSumMetricData >> temporality: aSymbol [

	temporality := aSymbol ifNil: [ #cumulative ] ifNotNil: [ aSymbol ]
]
