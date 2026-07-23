Class {
	#name : 'OTGaugeMetricData',
	#superclass : 'OTMetricData',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'otlp - encoding' }
OTGaugeMetricData >> addOtlpJsonDataTo: aDictionary encoder: anEncoder [

	aDictionary at: 'gauge' put: (anEncoder gaugeDataFor: self)
]

{ #category : 'otlp - encoding' }
OTGaugeMetricData >> writeOtlpProtobufDataOn: aWriter encoder: anEncoder [

	aWriter
		writeTag: 5 wireType: 2;
		writeEmbedded: [ :gauge |
			anEncoder writeGauge: self on: gauge ]
]

{ #category : 'prometheus' }
OTGaugeMetricData >> prometheusMetricTypeWith: anEncoder format: aFormatSymbol [

	^ anEncoder prometheusGaugeLikeMetricTypeFor: self format: aFormatSymbol
]

{ #category : 'prometheus' }
OTGaugeMetricData >> prometheusSampleSpecificationsWith: anEncoder type: aTypeSymbol format: aFormatSymbol [

	^ anEncoder sampleSpecificationsForGauge: self type: aTypeSymbol format: aFormatSymbol
]

{ #category : 'prometheus' }
OTGaugeMetricData >> writePrometheusWith: anEncoder type: aTypeSymbol format: aFormatSymbol on: aStream [

	^ anEncoder
		  writeGauge: self
		  type: aTypeSymbol
		  format: aFormatSymbol
		  on: aStream
]
