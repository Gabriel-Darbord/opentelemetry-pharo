Class {
	#name : 'OTMetricMeasurementTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Metrics-Tests',
	#package : 'OpenTelemetry-Metrics-Tests'
}

{ #category : 'tests' }
OTMetricMeasurementTest >> testCopiedMeasurementKeepsLazyExemplarFallbackWhenNoExplicitExemplarAttributesExist [

	| copy instrument measurement provider |
	provider := OTMeterProvider new.
	instrument := (provider meterNamed: 'demo.metrics') counterNamed: 'requests.total'.
	measurement := OTMetricMeasurement instrument: instrument value: 1 attributes: { ('status' -> '200') }.
	copy := measurement withAttributes: { ('status' -> '500') }.
	self assert: copy exemplarAttributes identicalTo: copy attributes
]

{ #category : 'tests' }
OTMetricMeasurementTest >> testCopiedMeasurementPreservesExplicitExemplarAttributes [

	| copy instrument measurement provider |
	provider := OTMeterProvider new.
	instrument := (provider meterNamed: 'demo.metrics') counterNamed: 'requests.total'.
	measurement := OTMetricMeasurement instrument: instrument value: 1 attributes: { ('status' -> '200') }.
	measurement exemplarAttributes: {
			('status' -> '200').
			('user' -> 'alice') }.
	copy := measurement withAttributes: { ('status' -> '500') }.
	self deny: copy exemplarAttributes identicalTo: copy attributes.
	self assert: copy exemplarAttributes size equals: 2.
	self assert: (copy exemplarAttributes at: 'user') equals: 'alice'
]

{ #category : 'tests' }
OTMetricMeasurementTest >> testDefaultMeasurementUsesAttributesAsLazyExemplarFallback [

	| instrument measurement provider |
	provider := OTMeterProvider new.
	instrument := (provider meterNamed: 'demo.metrics') counterNamed: 'requests.total'.
	measurement := OTMetricMeasurement instrument: instrument value: 1 attributes: { ('status' -> '200') }.
	self assert: measurement exemplarAttributes identicalTo: measurement attributes
]

{ #category : 'tests' }
OTMetricMeasurementTest >> testProviderCapturedMeasurementReusesNormalizedExemplarAttributesAcrossCopies [

	| copy instrument measurement provider |
	provider := OTMeterProvider new.
	provider exemplarFilter: OTMetricExemplarFilter alwaysOn.
	instrument := (provider meterNamed: 'demo.metrics') counterNamed: 'requests.total'.
	measurement := provider measurementFor: instrument value: 1 attributes: {
			               ('status' -> '200').
			               ('user' -> 'alice') }.
	copy := measurement withAttributes: { ('status' -> '200') }.
	self assert: measurement exemplarAttributes identicalTo: measurement attributes.
	self assert: copy exemplarAttributes identicalTo: measurement exemplarAttributes.
	self deny: copy exemplarAttributes identicalTo: copy attributes.
	self assert: (copy exemplarAttributes at: 'user') equals: 'alice'
]
