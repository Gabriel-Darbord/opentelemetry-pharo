Class {
	#name : 'OTSpanExporterLifecycleTest',
	#superclass : 'TestCase',
	#instVars : [
		'exporter'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'running' }
OTSpanExporterLifecycleTest >> tearDown [

	[ OTBlockingShutdownSpanExporter allInstancesDo: [ :each | each allowShutdown ] ] ensure: [ super tearDown ]
]

{ #category : 'tests' }
OTSpanExporterLifecycleTest >> testCompositeShutdownIsIdempotentUnderConcurrentCalls [

	| child firstDone firstResult secondDone secondResult |
	child := OTBlockingShutdownSpanExporter new.
	exporter := OTCompositeSpanExporter withAll: { child }.
	firstDone := Semaphore new.
	secondDone := Semaphore new.
	[
		firstResult := exporter shutdown.
		firstDone signal ] forkAt: Processor userBackgroundPriority.
	self assert: (child waitForShutdownTimeoutMillis: 200).
	[
		secondResult := exporter shutdown.
		secondDone signal ] forkAt: Processor userBackgroundPriority.
	self assert: (secondDone waitTimeoutMilliseconds: 200) not.
	self deny: secondResult.
	child allowShutdown.
	self assert: (firstDone waitTimeoutMilliseconds: 200) not.
	self assert: firstResult.
	self assert: exporter isShutdown.
	self assert: child shutdownCount equals: 1
]

{ #category : 'tests' }
OTSpanExporterLifecycleTest >> testConcurrentShutdownIsIdempotent [

	| firstDone firstResult secondDone secondResult |
	exporter := OTBlockingShutdownSpanExporter new.
	firstDone := Semaphore new.
	secondDone := Semaphore new.
	[
		firstResult := exporter shutdown.
		firstDone signal ] forkAt: Processor userBackgroundPriority.
	self assert: (exporter waitForShutdownTimeoutMillis: 200).
	[
		secondResult := exporter shutdown.
		secondDone signal ] forkAt: Processor userBackgroundPriority.
	self assert: (secondDone waitTimeoutMilliseconds: 200) not.
	self deny: secondResult.
	exporter allowShutdown.
	self assert: (firstDone waitTimeoutMilliseconds: 200) not.
	self assert: firstResult.
	self assert: exporter isShutdown.
	self assert: exporter shutdownCount equals: 1
]

{ #category : 'tests' }
OTSpanExporterLifecycleTest >> testExportReturnsFalseAfterShutdown [

	exporter := OTRecordingSpanExporter new.
	self assert: exporter shutdown.
	self deny: (exporter export: #(  ))
]

{ #category : 'tests' }
OTSpanExporterLifecycleTest >> testForceFlushReturnsFalseWhileShutdownIsInProgress [

	| done shutdownResult |
	exporter := OTBlockingShutdownSpanExporter new.
	done := Semaphore new.
	[
		shutdownResult := exporter shutdown.
		done signal ] forkAt: Processor userBackgroundPriority.
	self assert: (exporter waitForShutdownTimeoutMillis: 200).
	self deny: exporter forceFlush.
	exporter allowShutdown.
	self assert: (done waitTimeoutMilliseconds: 200) not.
	self assert: shutdownResult
]
