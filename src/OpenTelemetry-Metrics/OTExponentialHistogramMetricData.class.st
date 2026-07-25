"
I hold exponential histogram metric points ready for export.
I also know how to encode that stream for OTLP.
"
Class {
	#name : 'OTExponentialHistogramMetricData',
	#superclass : 'OTMetricData',
	#instVars : [
		'temporality'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTExponentialHistogramMetricData class >> instrument: anOTMetricInstrument points: aCollection [

	| metric |
	metric := super instrument: anOTMetricInstrument points: aCollection.
	metric temporality: #cumulative.
	^ metric
]

{ #category : 'otlp - encoding' }
OTExponentialHistogramMetricData >> addOtlpJsonDataTo: aDictionary encoder: anEncoder [

	aDictionary at: 'exponentialHistogram' put: (anEncoder exponentialHistogramDataFor: self)
]

{ #category : 'accessing' }
OTExponentialHistogramMetricData >> temporality [

	^ temporality ifNil: [ #cumulative ]
]

{ #category : 'accessing' }
OTExponentialHistogramMetricData >> temporality: aSymbol [

	temporality := aSymbol ifNil: [ #cumulative ] ifNotNil: [ aSymbol ]
]

{ #category : 'otlp - encoding' }
OTExponentialHistogramMetricData >> writeOtlpProtobufDataOn: aWriter encoder: anEncoder [

	aWriter
		writeTag: 10 wireType: 2;
		writeEmbedded: [ :histogram | anEncoder writeExponentialHistogram: self on: histogram ]
]
