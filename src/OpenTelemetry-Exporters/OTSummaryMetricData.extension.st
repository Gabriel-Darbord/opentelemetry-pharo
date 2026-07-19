Extension { #name : 'OTSummaryMetricData' }

{ #category : '*OpenTelemetry-Exporters' }
OTSummaryMetricData >> prometheusMetricTypeWith: anEncoder format: aFormatSymbol [

	^ #summary
]

{ #category : '*OpenTelemetry-Exporters' }
OTSummaryMetricData >> prometheusSampleSpecificationsWith: anEncoder type: aTypeSymbol format: aFormatSymbol [

	^ anEncoder sampleSpecificationsForSummary: self
]

{ #category : '*OpenTelemetry-Exporters' }
OTSummaryMetricData >> writePrometheusWith: anEncoder type: aTypeSymbol format: aFormatSymbol on: aStream [

	^ anEncoder writeSummary: self on: aStream
]
