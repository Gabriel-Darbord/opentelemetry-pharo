Extension { #name : 'OTGaugeMetricData' }

{ #category : '*OpenTelemetry-Exporters' }
OTGaugeMetricData >> prometheusMetricTypeWith: anEncoder format: aFormatSymbol [

	^ anEncoder prometheusGaugeLikeMetricTypeFor: self format: aFormatSymbol
]

{ #category : '*OpenTelemetry-Exporters' }
OTGaugeMetricData >> prometheusSampleSpecificationsWith: anEncoder type: aTypeSymbol format: aFormatSymbol [

	^ anEncoder sampleSpecificationsForGauge: self type: aTypeSymbol format: aFormatSymbol
]

{ #category : '*OpenTelemetry-Exporters' }
OTGaugeMetricData >> writePrometheusWith: anEncoder type: aTypeSymbol format: aFormatSymbol on: aStream [

	^ anEncoder
		  writeGauge: self
		  type: aTypeSymbol
		  format: aFormatSymbol
		  on: aStream
]
