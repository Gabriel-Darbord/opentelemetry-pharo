Class {
	#name : 'OTCompositeSpanProcessorTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'private' }
OTCompositeSpanProcessorTest >> sampledSpanWithSuffix: anInteger [

	| suffix |
	suffix := (anInteger printStringBase: 16 length: 2 padded: true) asLowercase.
	^ (OTSpanContext
		   traceId: '00112233445566778899aabbccddee' , suffix
		   spanId: '11223344556677' , suffix
		   traceFlags: '01'
		   traceState: nil
		   remote: false) asNonRecordingSpan
]

{ #category : 'running' }
OTCompositeSpanProcessorTest >> tearDown [

	[ OTBlockingShutdownSpanProcessor allInstancesDo: [ :each | each allowShutdown ] ] ensure: [ super tearDown ]
]

{ #category : 'tests' }
OTCompositeSpanProcessorTest >> testConcurrentShutdownIsIdempotent [

	| child composite firstDone firstResult secondDone secondResult |
	child := OTBlockingShutdownSpanProcessor new.
	composite := OTCompositeSpanProcessor withAll: { child }.
	firstDone := Semaphore new.
	secondDone := Semaphore new.
	[
		firstResult := composite shutdown.
		firstDone signal ] forkAt: Processor userBackgroundPriority.
	self assert: (child waitForShutdownTimeoutMillis: 200).
	[
		secondResult := composite shutdown.
		secondDone signal ] forkAt: Processor userBackgroundPriority.
	self assert: (secondDone waitTimeoutMilliseconds: 200) not.
	self deny: secondResult.
	child allowShutdown.
	self assert: (firstDone waitTimeoutMilliseconds: 200) not.
	self assert: firstResult.
	self assert: composite isShutdown
]

{ #category : 'tests' }
OTCompositeSpanProcessorTest >> testForceFlushReturnsFalseAfterShutdown [

	| composite |
	composite := OTCompositeSpanProcessor withAll: { OTRecordingSpanProcessor new }.
	self assert: composite shutdown.
	self deny: composite forceFlush
]

{ #category : 'tests' }
OTCompositeSpanProcessorTest >> testForceFlushReturnsFalseWhileShutdownIsInProgress [

	| child composite done shutdownResult |
	child := OTBlockingShutdownSpanProcessor new.
	composite := OTCompositeSpanProcessor withAll: { child }.
	done := Semaphore new.
	[
		shutdownResult := composite shutdown.
		done signal ] forkAt: Processor userBackgroundPriority.
	self assert: (child waitForShutdownTimeoutMillis: 200).
	self deny: composite forceFlush.
	child allowShutdown.
	self assert: (done waitTimeoutMilliseconds: 200) not.
	self assert: shutdownResult.
	self assert: composite isShutdown
]

{ #category : 'tests' }
OTCompositeSpanProcessorTest >> testOnEndAfterShutdownIsIgnored [

	| composite recordingProcessor |
	recordingProcessor := OTRecordingSpanProcessor new.
	composite := OTCompositeSpanProcessor withAll: { recordingProcessor }.
	self assert: composite shutdown.
	self deny: (composite onEnd: (self sampledSpanWithSuffix: 1)).
	self assert: recordingProcessor endedSpans isEmpty
]

{ #category : 'tests' }
OTCompositeSpanProcessorTest >> testOnEndReturnsFalseWhileShutdownIsInProgress [

	| blockingProcessor composite done recordingProcessor shutdownResult |
	blockingProcessor := OTBlockingShutdownSpanProcessor new.
	recordingProcessor := OTRecordingSpanProcessor new.
	composite := OTCompositeSpanProcessor withAll: {
			             blockingProcessor.
			             recordingProcessor }.
	done := Semaphore new.
	[
		shutdownResult := composite shutdown.
		done signal ] forkAt: Processor userBackgroundPriority.
	self assert: (blockingProcessor waitForShutdownTimeoutMillis: 200).
	self deny: (composite onEnd: (self sampledSpanWithSuffix: 1)).
	self assert: recordingProcessor endedSpans isEmpty.
	blockingProcessor allowShutdown.
	self assert: (done waitTimeoutMilliseconds: 200) not.
	self assert: shutdownResult
]

{ #category : 'tests' }
OTCompositeSpanProcessorTest >> testOnStartReturnsFalseWhileShutdownIsInProgress [

	| blockingProcessor composite done recordingProcessor shutdownResult span |
	blockingProcessor := OTBlockingShutdownSpanProcessor new.
	recordingProcessor := OTRecordingSpanProcessor new.
	composite := OTCompositeSpanProcessor withAll: {
			             blockingProcessor.
			             recordingProcessor }.
	span := self sampledSpanWithSuffix: 1.
	done := Semaphore new.
	[
		shutdownResult := composite shutdown.
		done signal ] forkAt: Processor userBackgroundPriority.
	self assert: (blockingProcessor waitForShutdownTimeoutMillis: 200).
	self deny: (composite onStart: span parentContext: OTContext new).
	self assert: recordingProcessor startedSpans isEmpty.
	blockingProcessor allowShutdown.
	self assert: (done waitTimeoutMilliseconds: 200) not.
	self assert: shutdownResult
]
