Class {
	#name : 'OTMetricExporterTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Metrics-Tests',
	#package : 'OpenTelemetry-Metrics-Tests'
}

{ #category : 'tests' }
OTMetricExporterTest >> testConcurrentForceFlushAndShutdownAreSafe [

	| done errors exporter gate lock operations results |
	exporter := OTInMemoryMetricExporter new.
	operations := #( forceFlush forceFlush forceFlush forceFlush shutdown shutdown shutdown shutdown ).
	results := OrderedCollection new.
	errors := OrderedCollection new.
	lock := Semaphore forMutualExclusion.
	gate := Semaphore new.
	done := Semaphore new.
	operations do: [ :eachOperation |
			[
				[
					gate wait.
					lock critical: [ results add: eachOperation -> (exporter perform: eachOperation) ] ]
					on: Error
					do: [ :anError | lock critical: [ errors add: anError ] ].
				done signal ] forkAt: Processor userBackgroundPriority ].
	operations size timesRepeat: [ gate signal ].
	operations size timesRepeat: [ self assert: (done waitTimeoutMilliseconds: 1000) not ].
	self assert: errors isEmpty.
	self assert: ((results select: [ :each | each key = #shutdown ]) count: [ :each | each value = true ]) equals: 1.
	self assert: ((results select: [ :each | each key = #shutdown ]) count: [ :each | each value = false ]) equals: 3.
	self assert:
		((results select: [ :each | each key = #forceFlush ]) allSatisfy: [ :each | each value = true or: [ each value = false ] ]).
	self assert: exporter isShutdown.
	self assert: exporter forceFlushCount <= 4
]

{ #category : 'tests' }
OTMetricExporterTest >> testConcurrentShutdownReturnsTrueOnce [

	| done exporter gate lock results workerCount |
	exporter := OTInMemoryMetricExporter new.
	results := OrderedCollection new.
	lock := Semaphore forMutualExclusion.
	gate := Semaphore new.
	done := Semaphore new.
	workerCount := 8.
	workerCount timesRepeat: [
			[
				gate wait.
				lock critical: [ results add: exporter shutdown ].
				done signal ] forkAt: Processor userBackgroundPriority ].
	workerCount timesRepeat: [ gate signal ].
	workerCount timesRepeat: [ self assert: (done waitTimeoutMilliseconds: 1000) not ].
	self assert: (results count: [ :each | each = true ]) equals: 1.
	self assert: (results count: [ :each | each = false ]) equals: workerCount - 1.
	self assert: exporter isShutdown
]

{ #category : 'tests' }
OTMetricExporterTest >> testExportReturnsFalseAfterShutdown [

	| exporter |
	exporter := OTInMemoryMetricExporter new.
	self assert: exporter shutdown.
	self deny: (exporter export: OTMetricSnapshot empty)
]

{ #category : 'tests' }
OTMetricExporterTest >> testForceFlushReturnsFalseAfterShutdown [

	| exporter |
	exporter := OTInMemoryMetricExporter new.
	self assert: exporter shutdown.
	self deny: exporter forceFlush
]
