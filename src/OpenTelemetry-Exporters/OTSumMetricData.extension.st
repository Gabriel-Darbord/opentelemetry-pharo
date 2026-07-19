Extension { #name : 'OTSumMetricData' }

{ #category : '*OpenTelemetry-Exporters' }
OTSumMetricData >> prometheusMetricTypeWith: anEncoder format: aFormatSymbol [

	^ self monotonic
		  ifTrue: [ #counter ]
		  ifFalse: [ anEncoder prometheusGaugeLikeMetricTypeFor: self format: aFormatSymbol ]
]

{ #category : '*OpenTelemetry-Exporters' }
OTSumMetricData >> prometheusSampleSpecificationsWith: anEncoder type: aTypeSymbol format: aFormatSymbol [

	^ anEncoder sampleSpecificationsForSum: self type: aTypeSymbol format: aFormatSymbol
]

{ #category : '*OpenTelemetry-Exporters' }
OTSumMetricData >> writePrometheusWith: anEncoder type: aTypeSymbol format: aFormatSymbol on: aStream [

	^ anEncoder
		  writeSum: self
		  type: aTypeSymbol
		  format: aFormatSymbol
		  on: aStream
]
