Extension { #name : 'OTMetricData' }

{ #category : '*OpenTelemetry-Exporters' }
OTMetricData >> prometheusMetricTypeWith: anEncoder format: aFormatSymbol [

	^ #drop
]

{ #category : '*OpenTelemetry-Exporters' }
OTMetricData >> prometheusSampleSpecificationsWith: anEncoder type: aTypeSymbol format: aFormatSymbol [

	^ #(  )
]

{ #category : '*OpenTelemetry-Exporters' }
OTMetricData >> writePrometheusWith: anEncoder type: aTypeSymbol format: aFormatSymbol on: aStream [

	self
]
