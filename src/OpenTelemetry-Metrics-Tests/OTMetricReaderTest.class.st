Class {
	#name : 'OTMetricReaderTest',
	#superclass : 'TestCase',
	#instVars : [
		'provider'
	],
	#category : 'OpenTelemetry-Metrics-Tests',
	#package : 'OpenTelemetry-Metrics-Tests'
}

{ #category : 'running' }
OTMetricReaderTest >> tearDown [

	[ provider ifNotNil: [ provider shutdown ] ] ensure: [ super tearDown ]
]

{ #category : 'tests' }
OTMetricReaderTest >> testConcurrentDeltaCollectSnapshotIsSafe [

	| done errors gate instrument lock reader results workerCount |
	provider := OTMeterProvider new.
	reader := OTInMemoryMetricReader new.
	reader temporalitySelector: [ :metricInstrument | #delta ].
	provider addMetricReader: reader.
	instrument := (provider meterNamed: 'demo.metrics')
		              observableCounterNamed: 'runtime.page_faults'
		              callbacks: { [ :observer | observer observe: 42 attributes: { ('pid' -> '1001') } ] }.
	results := OrderedCollection new.
	errors := OrderedCollection new.
	lock := Semaphore forMutualExclusion.
	gate := Semaphore new.
	done := Semaphore new.
	workerCount := 8.
	workerCount timesRepeat: [
			[
				[
					gate wait.
					lock critical: [ results add: reader collectSnapshot ] ]
					on: Error
					do: [ :anError | lock critical: [ errors add: anError ] ].
				done signal ] forkAt: Processor userBackgroundPriority ].
	workerCount timesRepeat: [ gate signal ].
	workerCount timesRepeat: [ self assert: (done waitTimeoutMilliseconds: 1000) not ].
	self assert: instrument class identicalTo: OTObservableCounter.
	self assert: errors isEmpty.
	self assert: results size equals: workerCount.
	self assert: (results allSatisfy: [ :each | each class = OTMetricSnapshot ])
]

{ #category : 'tests' }
OTMetricReaderTest >> testConcurrentShutdownReturnsTrueOnce [

	| done gate lock reader results workerCount |
	reader := OTRecordingMetricReader new.
	results := OrderedCollection new.
	lock := Semaphore forMutualExclusion.
	gate := Semaphore new.
	done := Semaphore new.
	workerCount := 8.
	workerCount timesRepeat: [
			[
				gate wait.
				lock critical: [ results add: reader shutdown ].
				done signal ] forkAt: Processor userBackgroundPriority ].
	workerCount timesRepeat: [ gate signal ].
	workerCount timesRepeat: [ self assert: (done waitTimeoutMilliseconds: 1000) not ].
	self assert: (results count: [ :each | each = true ]) equals: 1.
	self assert: (results count: [ :each | each = false ]) equals: workerCount - 1.
	self assert: reader isShutdown.
	self assert: reader shutdownCount equals: 1
]

{ #category : 'tests' }
OTMetricReaderTest >> testForceFlushReturnsFalseAfterShutdown [

	| reader |
	reader := OTInMemoryMetricReader new.
	self assert: reader shutdown.
	self deny: reader forceFlush
]
