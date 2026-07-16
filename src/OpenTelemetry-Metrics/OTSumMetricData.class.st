Class {
	#name : 'OTSumMetricData',
	#superclass : 'OTMetricData',
	#instVars : [
		'monotonic'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTSumMetricData class >> instrument: anOTMetricInstrument points: aCollection monotonic: aBoolean [

	| metric |
	metric := self instrument: anOTMetricInstrument points: aCollection.
	metric monotonic: aBoolean.
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
