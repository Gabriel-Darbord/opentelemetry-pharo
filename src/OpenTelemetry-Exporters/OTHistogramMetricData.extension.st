Extension { #name : 'OTHistogramMetricData' }

{ #category : '*OpenTelemetry-Exporters' }
OTHistogramMetricData >> prometheusMetricTypeWith: anEncoder format: aFormatSymbol [

	^ #histogram
]

{ #category : '*OpenTelemetry-Exporters' }
OTHistogramMetricData >> prometheusSampleSpecificationsWith: anEncoder type: aTypeSymbol format: aFormatSymbol [

	^ anEncoder sampleSpecificationsForHistogram: self
]

{ #category : '*OpenTelemetry-Exporters' }
OTHistogramMetricData >> writePrometheusWith: anEncoder type: aTypeSymbol format: aFormatSymbol on: aStream [

	^ anEncoder writeHistogram: self on: aStream
]
