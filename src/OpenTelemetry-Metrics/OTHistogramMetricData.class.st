"
I hold explicit-bucket histogram metric points ready for export.
I also provide OTLP and Prometheus encoding hooks for histogram streams.
"
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

{ #category : 'otlp - encoding' }
OTHistogramMetricData >> addOtlpJsonDataTo: aDictionary encoder: anEncoder [

	aDictionary at: 'histogram' put: (anEncoder histogramDataFor: self)
]

{ #category : 'prometheus - encoding' }
OTHistogramMetricData >> prometheusMetricTypeWith: anEncoder format: aFormatSymbol [

	^ #histogram
]

{ #category : 'prometheus - encoding' }
OTHistogramMetricData >> prometheusSampleSpecificationsWith: anEncoder type: aTypeSymbol format: aFormatSymbol [

	^ anEncoder sampleSpecificationsForHistogram: self
]

{ #category : 'accessing' }
OTHistogramMetricData >> temporality [

	^ temporality ifNil: [ #cumulative ]
]

{ #category : 'accessing' }
OTHistogramMetricData >> temporality: aSymbol [

	temporality := aSymbol ifNil: [ #cumulative ] ifNotNil: [ aSymbol ]
]

{ #category : 'otlp - encoding' }
OTHistogramMetricData >> writeOtlpProtobufDataOn: aWriter encoder: anEncoder [

	aWriter
		writeTag: 9 wireType: 2;
		writeEmbedded: [ :histogram | anEncoder writeHistogram: self on: histogram ]
]

{ #category : 'prometheus - encoding' }
OTHistogramMetricData >> writePrometheusWith: anEncoder type: aTypeSymbol format: aFormatSymbol on: aStream [

	^ anEncoder writeHistogram: self on: aStream
]
