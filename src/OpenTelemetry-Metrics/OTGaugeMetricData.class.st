"
I hold gauge metric points ready for export.
I also provide OTLP and Prometheus encoding hooks for gauge streams.
"
Class {
	#name : 'OTGaugeMetricData',
	#superclass : 'OTMetricData',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'accessing' }
OTGaugeMetricData >> kind [

	^ #gauge
]

{ #category : 'otlp - encoding' }
OTGaugeMetricData >> addOtlpJsonDataTo: aDictionary encoder: anEncoder [

	aDictionary at: 'gauge' put: (anEncoder gaugeDataFor: self)
]

{ #category : 'prometheus - encoding' }
OTGaugeMetricData >> prometheusMetricTypeWith: anEncoder format: aFormatSymbol [

	^ anEncoder prometheusGaugeLikeMetricTypeFor: self format: aFormatSymbol
]

{ #category : 'prometheus - encoding' }
OTGaugeMetricData >> prometheusSampleSpecificationsWith: anEncoder type: aTypeSymbol format: aFormatSymbol [

	^ anEncoder sampleSpecificationsForGauge: self type: aTypeSymbol format: aFormatSymbol
]

{ #category : 'otlp - encoding' }
OTGaugeMetricData >> writeOtlpProtobufDataOn: aWriter encoder: anEncoder [

	aWriter
		writeTag: 5 wireType: 2;
		writeEmbedded: [ :gauge | anEncoder writeGauge: self on: gauge ]
]

{ #category : 'prometheus - encoding' }
OTGaugeMetricData >> writePrometheusWith: anEncoder type: aTypeSymbol format: aFormatSymbol on: aStream [

	^ anEncoder
		  writeGauge: self
		  type: aTypeSymbol
		  format: aFormatSymbol
		  on: aStream
]
