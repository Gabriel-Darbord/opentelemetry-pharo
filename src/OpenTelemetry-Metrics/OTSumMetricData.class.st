"
I hold sum metric points ready for export.
I also keep monotonicity and temporality metadata needed by OTLP and Prometheus encoders.
"
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

{ #category : 'otlp - encoding' }
OTSumMetricData >> addOtlpJsonDataTo: aDictionary encoder: anEncoder [

	aDictionary at: 'sum' put: (anEncoder sumDataFor: self)
]

{ #category : 'accessing' }
OTSumMetricData >> kind [

	^ #sum
]

{ #category : 'accessing' }
OTSumMetricData >> monotonic [

	^ monotonic ifNil: [ false ] ifNotNil: [ monotonic ]
]

{ #category : 'accessing' }
OTSumMetricData >> monotonic: aBoolean [

	monotonic := aBoolean ifNil: [ false ] ifNotNil: [ aBoolean ]
]

{ #category : 'prometheus - encoding' }
OTSumMetricData >> prometheusMetricTypeWith: anEncoder format: aFormatSymbol [

	^ self monotonic
		  ifTrue: [ #counter ]
		  ifFalse: [ anEncoder prometheusGaugeLikeMetricTypeFor: self format: aFormatSymbol ]
]

{ #category : 'prometheus - encoding' }
OTSumMetricData >> prometheusSampleSpecificationsWith: anEncoder type: aTypeSymbol format: aFormatSymbol [

	^ anEncoder sampleSpecificationsForSum: self type: aTypeSymbol format: aFormatSymbol
]

{ #category : 'accessing' }
OTSumMetricData >> temporality [

	^ temporality ifNil: [ #cumulative ]
]

{ #category : 'accessing' }
OTSumMetricData >> temporality: aSymbol [

	temporality := aSymbol ifNil: [ #cumulative ] ifNotNil: [ aSymbol ]
]

{ #category : 'otlp - encoding' }
OTSumMetricData >> writeOtlpProtobufDataOn: aWriter encoder: anEncoder [

	aWriter
		writeTag: 7 wireType: 2;
		writeEmbedded: [ :sum | anEncoder writeSum: self on: sum ]
]

{ #category : 'prometheus - encoding' }
OTSumMetricData >> writePrometheusWith: anEncoder type: aTypeSymbol format: aFormatSymbol on: aStream [

	^ anEncoder
		  writeSum: self
		  type: aTypeSymbol
		  format: aFormatSymbol
		  on: aStream
]
