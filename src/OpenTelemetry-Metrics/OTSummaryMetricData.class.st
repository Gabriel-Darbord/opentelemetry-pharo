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

{ #category : 'otlp - encoding' }
OTSummaryMetricData >> writeOtlpProtobufDataOn: aWriter encoder: anEncoder [

	aWriter
		writeTag: 11 wireType: 2;
		writeEmbedded: [ :summary |
			anEncoder writeSummary: self on: summary ]
]
