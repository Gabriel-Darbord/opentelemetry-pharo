Class {
	#name : 'OTHistogramMetricData',
	#superclass : 'OTMetricData',
	#instVars : [
		'temporality'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTHistogramMetricData class >> instrument: anOTMetricInstrument points: aCollection [

	| metric |
	metric := super instrument: anOTMetricInstrument points: aCollection.
	metric temporality: #cumulative.
	^ metric
]

{ #category : 'accessing' }
OTHistogramMetricData >> temporality [

	^ temporality ifNil: [ #cumulative ]
]

{ #category : 'accessing' }
OTHistogramMetricData >> temporality: aSymbol [

	temporality := aSymbol ifNil: [ #cumulative ] ifNotNil: [ aSymbol ]
]
