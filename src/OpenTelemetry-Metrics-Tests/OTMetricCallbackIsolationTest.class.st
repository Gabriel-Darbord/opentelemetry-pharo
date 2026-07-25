Class {
	#name : 'OTMetricCallbackIsolationTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Metrics-Tests',
	#package : 'OpenTelemetry-Metrics-Tests'
}

{ #category : 'running' }
OTMetricCallbackIsolationTest >> tearDown [

	[
		OTMetricReader callbackWarningSink: nil.
		OTMeterProvider current: nil.
		OTMeterProvider reset ] ensure: [ super tearDown ]
]

{ #category : 'tests' }
OTMetricCallbackIsolationTest >> testReaderSkipsFailedAsynchronousCallbacksAndContinuesCollecting [

	| measurements provider reader warnings |
	warnings := OrderedCollection new.
	OTMetricReader callbackWarningSink: [ :message | warnings add: message ].
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	provider addMetricReader: reader.
	(provider meterNamed: 'demo.metrics')
		observableGaugeNamed: 'runtime.memory'
		callbacks: {
				[ Error signal: 'boom' ].
				[ :observer | observer observe: 42 attributes: { ('state' -> 'used') } ] }
		unit: 'By'
		description: 'Runtime memory'
		advice: Dictionary new.
	measurements := reader collect.
	self assert: measurements size equals: 1.
	self assert: warnings size equals: 1.
	self assert: (warnings first includesSubstring: 'failed').
	self assert: (measurements first attributes at: 'state') equals: 'used'
]

{ #category : 'tests' }
OTMetricCallbackIsolationTest >> testReaderSkipsTimedOutAsynchronousCallbacks [

	| provider reader warnings |
	warnings := OrderedCollection new.
	OTMetricReader callbackWarningSink: [ :message | warnings add: message ].
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	reader callbackTimeoutMillis: 10.
	provider addMetricReader: reader.
	(provider meterNamed: 'demo.metrics')
		observableGaugeNamed: 'runtime.memory'
		callbacks: { [ :observer |
				(Delay forMilliseconds: 50) wait.
				observer observe: 42 attributes: { ('state' -> 'used') } ] }
		unit: 'By'
		description: 'Runtime memory'
		advice: Dictionary new.
	self assert: reader collect isEmpty.
	self assert: warnings size equals: 1.
	self assert: (warnings first includesSubstring: 'timed out')
]
