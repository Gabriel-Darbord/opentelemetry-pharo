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

{ #category : 'tests' }
OTMetricCallbackIsolationTest >> testReaderDoesNotEmitStaleDeltaSeriesAfterFailedAsynchronousCallback [

	| callbackState firstPoint provider reader snapshot warnings |
	warnings := OrderedCollection new.
	OTMetricReader callbackWarningSink: [ :message | warnings add: message ].
	callbackState := #first.
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	reader temporalitySelector: [ :instrument | #delta ].
	provider addMetricReader: reader.
	(provider meterNamed: 'demo.metrics')
		observableCounterNamed: 'runtime.page_faults'
		callbacks: { [ :observer |
				callbackState = #failed ifTrue: [ Error signal: 'boom' ].
				observer observe: 5 attributes: { ('pid' -> '1001') } ] }
		unit: '1'
		description: 'Page faults'
		advice: Dictionary new.
	firstPoint := reader collectSnapshot metrics first points first.
	callbackState := #failed.
	snapshot := reader collectSnapshot.
	self assert: firstPoint value equals: 5.
	self assert: snapshot metrics isEmpty.
	self assert: warnings size equals: 1.
	self assert: (warnings first includesSubstring: 'failed')
]

{ #category : 'tests' }
OTMetricCallbackIsolationTest >> testReaderDoesNotEmitStaleDeltaSeriesForAttributeSetsMissingFromNextSuccessfulCallback [

	| callbackValues firstMetric provider reader secondMetric |
	callbackValues := OrderedDictionary new
		                  at: '1001' put: 5;
		                  at: '1002' put: 7;
		                  yourself.
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	reader temporalitySelector: [ :instrument | #delta ].
	provider addMetricReader: reader.
	(provider meterNamed: 'demo.metrics')
		observableCounterNamed: 'runtime.page_faults'
		callbacks: { [ :observer |
				callbackValues associationsDo: [ :each |
					observer observe: each value attributes: { ('pid' -> each key) } ] ] }
		unit: '1'
		description: 'Page faults'
		advice: Dictionary new.
	firstMetric := reader collectSnapshot metrics first.
	callbackValues := OrderedDictionary new
		                  at: '1001' put: 8;
		                  yourself.
	secondMetric := reader collectSnapshot metrics first.
	self assert: firstMetric points size equals: 2.
	self assert: secondMetric points size equals: 1.
	self assert: (secondMetric points first attributes at: 'pid') equals: '1001'.
	self assert: secondMetric points first value equals: 3
]
