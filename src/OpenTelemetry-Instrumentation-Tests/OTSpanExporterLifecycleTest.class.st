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

	[
		OTSpanExporter warningSink: nil.
		OTBlockingShutdownSpanExporter allInstancesDo: [ :each | each allowShutdown ] ] ensure: [ super tearDown ]
]

{ #category : 'tests' }
OTSpanExporterLifecycleTest >> testCompositeExportContinuesAfterChildFailure [

	self withExporterWarningsDo: [ :warnings |
			| composite failingExporter succeedingExporter |
			failingExporter := OTFailingSpanExporter failingOperations: { 'export' }.
			succeedingExporter := OTRecordingSpanExporter new.
			composite := OTCompositeSpanExporter withAll: {
					             failingExporter.
					             succeedingExporter }.
			self deny: (composite export: #( first )).
			self assert: succeedingExporter exportedBatches asArray equals: { #( first ) }.
			self
				assert: warnings asArray
				equals: { 'OpenTelemetry span exporter operation failed during export for OTFailingSpanExporter: exporter failure' } ]
]

{ #category : 'tests' }
OTSpanExporterLifecycleTest >> testCompositeForceFlushContinuesAfterChildFailure [

	self withExporterWarningsDo: [ :warnings |
			| composite failingExporter succeedingExporter |
			failingExporter := OTFailingSpanExporter failingOperations: { 'forceFlush' }.
			succeedingExporter := OTRecordingSpanExporter new.
			composite := OTCompositeSpanExporter withAll: {
					             failingExporter.
					             succeedingExporter }.
			self deny: composite forceFlush.
			self assert: succeedingExporter forceFlushCount equals: 1.
			self
				assert: warnings asArray
				equals: { 'OpenTelemetry span exporter operation failed during forceFlush for OTFailingSpanExporter: exporter failure' } ]
]

{ #category : 'tests' }
OTSpanExporterLifecycleTest >> testCompositeShutdownContinuesAfterChildFailure [

	self withExporterWarningsDo: [ :warnings |
			| composite failingExporter succeedingExporter |
			failingExporter := OTFailingSpanExporter failingOperations: { 'forceFlush'. 'shutdown' }.
			succeedingExporter := OTRecordingSpanExporter new.
			composite := OTCompositeSpanExporter withAll: {
					             failingExporter.
					             succeedingExporter }.
			self deny: composite shutdown.
			self assert: composite isShutdown.
			self assert: succeedingExporter forceFlushCount equals: 1.
			self assert: succeedingExporter shutdownCount equals: 1.
			self
				assert: warnings asArray
				equals: { 'OpenTelemetry span exporter operation failed during forceFlush for OTFailingSpanExporter: exporter failure'.
					'OpenTelemetry span exporter operation failed during shutdown for OTFailingSpanExporter: exporter failure' } ]
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
OTSpanExporterLifecycleTest >> testExportIsSerializedAcrossConcurrentCallsOnSameExporterInstance [

	| firstDone firstResult secondDone secondResult |
	exporter := OTBlockingSpanExporter new.
	exporter blockNextExport.
	firstDone := Semaphore new.
	secondDone := Semaphore new.
	[
		firstResult := exporter export: #( first ).
		firstDone signal ] forkAt: Processor userBackgroundPriority.
	self assert: (exporter waitForBlockedExportTimeoutMillis: 200).
	[
		secondResult := exporter export: #( second ).
		secondDone signal ] forkAt: Processor userBackgroundPriority.
	self assert: (secondDone waitTimeoutMilliseconds: 50).
	exporter allowBlockedExport.
	self assert: (firstDone waitTimeoutMilliseconds: 200) not.
	self assert: (secondDone waitTimeoutMilliseconds: 200) not.
	self assert: firstResult.
	self assert: secondResult.
	self assert: exporter exportedBatches size equals: 2
]

{ #category : 'tests' }
OTSpanExporterLifecycleTest >> testExportLockLookupIsSerializedOnFirstConcurrentAccess [

	| firstDone firstLock secondDone secondLock store |
	store := OTCoordinatedDictionary new.
	exporter := OTRecordingSpanExporter new.
	OTClassStateStore valueAt: #otExportLocksByExporter forClass: exporter class put: store.
	OTClassStateStore removeValueAt: #otExportLockStateLock forClass: exporter class ifAbsent: [ ].
	firstDone := Semaphore new.
	secondDone := Semaphore new.
	[
		[
			firstLock := exporter exportLock.
			firstDone signal ] forkAt: Processor userBackgroundPriority.
		self assert: (store waitForLookupTimeoutMillis: 200).
		[
			secondLock := exporter exportLock.
			secondDone signal ] forkAt: Processor userBackgroundPriority.
		self assert: (secondDone waitTimeoutMilliseconds: 50).
		self deny: (store waitForLookupTimeoutMillis: 50).
		store releaseLookup.
		self assert: (firstDone waitTimeoutMilliseconds: 200) not.
		self assert: (store waitForLookupTimeoutMillis: 200).
		store releaseLookup.
		self assert: (secondDone waitTimeoutMilliseconds: 200) not.
		self assert: firstLock identicalTo: secondLock.
		self assert: store lookupCount equals: 2 ] ensure: [
			store releaseLookup.
			store releaseLookup.
			exporter class reset ]
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

{ #category : 'tests' }
OTSpanExporterLifecycleTest >> testForceFlushWaitsForInFlightExportBeforeCompleting [

	| exportDone exportResult flushDone flushResult |
	exporter := OTBlockingSpanExporter new.
	exporter blockNextExport.
	exportDone := Semaphore new.
	flushDone := Semaphore new.
	[
		exportResult := exporter export: #( first ).
		exportDone signal ] forkAt: Processor userBackgroundPriority.
	self assert: (exporter waitForBlockedExportTimeoutMillis: 200).
	[
		flushResult := exporter forceFlush.
		flushDone signal ] forkAt: Processor userBackgroundPriority.
	self assert: (flushDone waitTimeoutMilliseconds: 50).
	exporter allowBlockedExport.
	self assert: (exportDone waitTimeoutMilliseconds: 200) not.
	self assert: (flushDone waitTimeoutMilliseconds: 200) not.
	self assert: exportResult.
	self assert: flushResult
]

{ #category : 'tests' }
OTSpanExporterLifecycleTest >> testShutdownWaitsForInFlightExportBeforeCompleting [

	| exportDone exportResult shutdownDone shutdownResult |
	exporter := OTBlockingSpanExporter new.
	exporter allowExportsAfterShutdown: true.
	exporter blockNextExport.
	exportDone := Semaphore new.
	shutdownDone := Semaphore new.
	[
		exportResult := exporter export: #( first ).
		exportDone signal ] forkAt: Processor userBackgroundPriority.
	self assert: (exporter waitForBlockedExportTimeoutMillis: 200).
	[
		shutdownResult := exporter shutdown.
		shutdownDone signal ] forkAt: Processor userBackgroundPriority.
	self assert: (shutdownDone waitTimeoutMilliseconds: 50).
	exporter allowBlockedExport.
	self assert: (exportDone waitTimeoutMilliseconds: 200) not.
	self assert: (shutdownDone waitTimeoutMilliseconds: 200) not.
	self assert: exportResult.
	self assert: shutdownResult.
	self assert: exporter isShutdown
]

{ #category : 'private' }
OTSpanExporterLifecycleTest >> withExporterWarningsDo: aBlock [

	| warnings |
	warnings := OrderedCollection new.
	OTSpanExporter warningSink: [ :message | warnings add: message ].
	[ ^ aBlock value: warnings ] ensure: [ OTSpanExporter warningSink: nil ]
]
