Class {
	#name : 'OTMetricExporterTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Metrics-Tests',
	#package : 'OpenTelemetry-Metrics-Tests'
}

{ #category : 'tests' }
OTMetricExporterTest >> testConcurrentForceFlushAndShutdownAreSafe [

	| done errors exporter forceFlushResults gate lock operations results shutdownResults |
	exporter := OTInMemoryMetricExporter new.
	operations := {
		              (#forceFlush -> [ exporter forceFlush ]).
		              (#forceFlush -> [ exporter forceFlush ]).
		              (#forceFlush -> [ exporter forceFlush ]).
		              (#forceFlush -> [ exporter forceFlush ]).
		              (#shutdown -> [ exporter shutdown ]).
		              (#shutdown -> [ exporter shutdown ]).
		              (#shutdown -> [ exporter shutdown ]).
		              (#shutdown -> [ exporter shutdown ]) }.
	results := OrderedCollection new.
	errors := OrderedCollection new.
	lock := Semaphore forMutualExclusion.
	gate := Semaphore new.
	done := Semaphore new.
	operations do: [ :eachOperation |
			[
				[
					gate wait.
					lock critical: [ results add: eachOperation key -> eachOperation value value ] ]
					on: Error
					do: [ :anError | lock critical: [ errors add: anError ] ].
				done signal ] forkAt: Processor userBackgroundPriority ].
	operations size timesRepeat: [ gate signal ].
	operations size timesRepeat: [ self assert: (done waitTimeoutMilliseconds: 1000) not ].
	shutdownResults := results select: [ :each | each key = #shutdown ].
	forceFlushResults := results select: [ :each | each key = #forceFlush ].
	self assert: errors isEmpty.
	self assert: (shutdownResults count: [ :each | each value ]) equals: 1.
	self assert: (shutdownResults count: [ :each | each value not ]) equals: 3.
	self assert: (forceFlushResults allSatisfy: [ :each | each value isKindOf: Boolean ]).
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
	self assert: (results count: [ :each | each ]) equals: 1.
	self assert: (results count: [ :each | each not ]) equals: workerCount - 1.
	self assert: exporter isShutdown
]

{ #category : 'tests' }
OTMetricExporterTest >> testConsoleExporterReturnsFalseAfterShutdownAndWritesNothing [

	| exporter stream |
	exporter := OTConsoleMetricExporter new.
	stream := String new writeStream.
	exporter outputStream: stream.
	self assert: exporter shutdown.
	self deny: (exporter export: OTMetricSnapshot empty).
	self assert: stream contents isEmpty
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

{ #category : 'tests' }
OTMetricExporterTest >> testNoopExporterReturnsFalseAfterShutdown [

	| exporter |
	exporter := OTNoopMetricExporter new.
	self assert: exporter shutdown.
	self deny: (exporter export: OTMetricSnapshot empty)
]
