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

{ #category : 'otlp - encoding' }
OTHistogramMetricData >> addOtlpJsonDataTo: aDictionary encoder: anEncoder [

	aDictionary at: 'histogram' put: (anEncoder histogramDataFor: self)
]

{ #category : 'otlp - encoding' }
OTHistogramMetricData >> writeOtlpProtobufDataOn: aWriter encoder: anEncoder [

	aWriter
		writeTag: 9 wireType: 2;
		writeEmbedded: [ :histogram |
			anEncoder writeHistogram: self on: histogram ]
]

{ #category : 'prometheus' }
OTHistogramMetricData >> prometheusMetricTypeWith: anEncoder format: aFormatSymbol [

	^ #histogram
]

{ #category : 'prometheus' }
OTHistogramMetricData >> prometheusSampleSpecificationsWith: anEncoder type: aTypeSymbol format: aFormatSymbol [

	^ anEncoder sampleSpecificationsForHistogram: self
]

{ #category : 'prometheus' }
OTHistogramMetricData >> writePrometheusWith: anEncoder type: aTypeSymbol format: aFormatSymbol on: aStream [

	^ anEncoder writeHistogram: self on: aStream
]
