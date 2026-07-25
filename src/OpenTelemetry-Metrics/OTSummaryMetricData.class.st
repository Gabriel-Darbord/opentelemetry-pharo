"
I hold summary metric points ready for export.
I also provide OTLP and Prometheus encoding hooks for summary streams.
"
Class {
	#name : 'OTSummaryMetricData',
	#superclass : 'OTMetricData',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'otlp - encoding' }
OTSummaryMetricData >> addOtlpJsonDataTo: aDictionary encoder: anEncoder [

	aDictionary at: 'summary' put: (anEncoder summaryDataFor: self)
]

{ #category : 'prometheus - encoding' }
OTSummaryMetricData >> prometheusMetricTypeWith: anEncoder format: aFormatSymbol [

	^ #summary
]

{ #category : 'prometheus - encoding' }
OTSummaryMetricData >> prometheusSampleSpecificationsWith: anEncoder type: aTypeSymbol format: aFormatSymbol [

	^ anEncoder sampleSpecificationsForSummary: self
]

{ #category : 'otlp - encoding' }
OTSummaryMetricData >> writeOtlpProtobufDataOn: aWriter encoder: anEncoder [

	aWriter
		writeTag: 11 wireType: 2;
		writeEmbedded: [ :summary | anEncoder writeSummary: self on: summary ]
]

{ #category : 'prometheus - encoding' }
OTSummaryMetricData >> writePrometheusWith: anEncoder type: aTypeSymbol format: aFormatSymbol on: aStream [

	^ anEncoder writeSummary: self on: aStream
]
