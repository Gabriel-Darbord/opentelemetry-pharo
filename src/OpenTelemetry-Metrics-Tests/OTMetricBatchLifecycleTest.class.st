Class {
	#name : 'OTMetricBatchLifecycleTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Metrics-Tests',
	#package : 'OpenTelemetry-Metrics-Tests'
}

{ #category : 'private' }
OTMetricBatchLifecycleTest >> assertOperation: anOperation failureMode: aMode flushCount: aCount [

	| exporter provider reader counter result |
	exporter := OTFirstBatchFailingMetricExporter new
		            failureMode: aMode;
		            yourself.
	provider := OTMeterProvider new.
	reader := OTPeriodicExportingMetricReader exporter: exporter.
	reader
		exportIntervalMillis: 1000000;
		exportTimeoutMillis: 150;
		maxExportBatchSize: 1.
	provider addMetricReader: reader.
	counter := (provider meterNamed: 'batching') counterNamed: 'requests'.
	1 to: 3 do: [ :index | counter add: index attributes: { ('index' -> index) } ].
	[
		result := anOperation value: reader.
		self assert: result isSuccess equals: aMode = #delay.
		aMode = #timeout ifTrue: [ self assert: result isTimeout ].
		self assert: exporter exports size equals: 3.
		self assert: (exporter exports collect: [ :snapshot | snapshot metrics first points first value ]) asArray equals: #( 1 2 3 ).
		self assert: exporter forceFlushCount equals: aCount ] ensure: [ provider shutdown ]
]

{ #category : 'tests' }
OTMetricBatchLifecycleTest >> testAnErrorWhileNotingAFailedCollectionLeavesTheExportLoopGoing [

	| deadline logger notes provider reader |
	notes := 0.
	logger := OTDiagnosticLogger current.
	OTDiagnosticLogger current: (OTDiagnosticLogger new
			 errorHandler: [ :error :message |
					 notes := notes + 1.
					 Error signal: 'noting failed' ];
			 yourself).
	provider := OTMeterProvider new.
	reader := OTFailingOnceMetricReader exporter: OTInMemoryMetricExporter new.
	reader exportIntervalMillis: 10.
	[
		provider addMetricReader: reader.
		deadline := Time millisecondClockValue + 2000.
		[ reader collectCount < 2 and: [ Time millisecondClockValue < deadline ] ] whileTrue: [ (Delay forMilliseconds: 10) wait ].
		self assert: reader collectCount >= 2.
		self assert: notes equals: 1 ] ensure: [
			provider shutdown.
			OTDiagnosticLogger current: logger ]
]

{ #category : 'tests' }
OTMetricBatchLifecycleTest >> testCollectionContinuesAfterFailedBatches [

	#( failure error timeout ) do: [ :mode |
		self assertOperation: [ :reader | reader collectResult ] failureMode: mode flushCount: 0 ]
]

{ #category : 'tests' }
OTMetricBatchLifecycleTest >> testEachBatchGetsItsOwnExportTimeout [

	self assertOperation: [ :reader | reader forceFlushResult ] failureMode: #delay flushCount: 1
]

{ #category : 'tests' }
OTMetricBatchLifecycleTest >> testFlushWithinMillisecondsGivesUpOnAnExportThatBlocks [

	| exporter provider reader flushed elapsed startedAt |
	exporter := OTBlockingMetricExporter new.
	provider := OTMeterProvider new.
	reader := OTPeriodicExportingMetricReader exporter: exporter.
	reader
		exportIntervalMillis: 1000000;
		exportTimeoutMillis: 30000.
	[
		provider addMetricReader: reader.
		((provider meterNamed: 'demo') counterNamed: 'requests') add: 1.
		startedAt := Time millisecondClockValue.
		flushed := provider flushWithinMilliseconds: 50.
		elapsed := Time millisecondClockValue - startedAt.
		self deny: flushed.
		self assert: elapsed < 1000 ] ensure: [
			exporter
				allowExportToContinue;
				allowExportToContinue.
			provider shutdown ]
]

{ #category : 'tests' }
OTMetricBatchLifecycleTest >> testForceFlushContinuesAfterFailedBatches [

	#( failure error timeout ) do: [ :mode |
		self assertOperation: [ :reader | reader forceFlushResult ] failureMode: mode flushCount: 1 ]
]

{ #category : 'tests' }
OTMetricBatchLifecycleTest >> testForgetEarlierSessionEndsThePeriodicExportInProgress [
	"The export a periodic reader was saved in the middle of belongs to the session that saved it: an image started from that save ends it rather than finish it, and starts the export loop again."

	| exporter provider reader blocked |
	exporter := OTBlockingMetricExporter new.
	provider := OTMeterProvider new.
	reader := OTPeriodicExportingMetricReader exporter: exporter.
	reader exportIntervalMillis: 10.
	[
		provider addMetricReader: reader.
		((provider meterNamed: 'demo') counterNamed: 'requests') add: 1.
		self assert: (exporter waitForExportEntryWithin: 2000).
		blocked := reader exportProcess.
		provider forgetEarlierSession.
		self assert: blocked isTerminated.
		self deny: reader exportProcess identicalTo: blocked.
		self deny: reader exportProcess isTerminated ] ensure: [
			exporter
				shutdown;
				allowExportToContinue.
			provider shutdown ]
]

{ #category : 'tests' }
OTMetricBatchLifecycleTest >> testShutdownContinuesAfterFailedBatches [

	#( failure error timeout ) do: [ :mode |
		self assertOperation: [ :reader | reader shutdownResult ] failureMode: mode flushCount: 1 ]
]

{ #category : 'tests' }
OTMetricBatchLifecycleTest >> testTheExportLoopGoesOnAfterACollectionFails [

	| deadline logger provider reader warnings |
	warnings := OrderedCollection new.
	logger := OTDiagnosticLogger current.
	OTDiagnosticLogger current: OTDiagnosticLogger new.
	OTMetricReader metricWarningSink: [ :message | warnings add: message ].
	provider := OTMeterProvider new.
	reader := OTFailingOnceMetricReader exporter: OTInMemoryMetricExporter new.
	reader exportIntervalMillis: 10.
	[
		provider addMetricReader: reader.
		deadline := Time millisecondClockValue + 2000.
		[ reader collectCount < 2 and: [ Time millisecondClockValue < deadline ] ] whileTrue: [ (Delay forMilliseconds: 10) wait ].
		self assert: reader collectCount >= 2.
		self assert: warnings size equals: 1.
		self assert: (warnings first includesSubstring: 'collection failed') ] ensure: [
			provider shutdown.
			OTMetricReader metricWarningSink: nil.
			OTDiagnosticLogger current: logger ]
]
