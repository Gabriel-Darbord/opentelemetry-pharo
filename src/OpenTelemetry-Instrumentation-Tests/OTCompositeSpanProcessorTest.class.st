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
OTCompositeSpanProcessorTest >> testForceFlushContinuesAfterChildFailure [

	self withSpanProcessorWarningsDo: [ :warnings |
			| composite failingProcessor succeedingProcessor |
			failingProcessor := OTFailingSpanProcessor failingOperations: { 'forceFlush' }.
			succeedingProcessor := OTFailingSpanProcessor new.
			composite := OTCompositeSpanProcessor withAll: {
					             failingProcessor.
					             succeedingProcessor }.
			self deny: composite forceFlush.
			self assert: succeedingProcessor forceFlushCount equals: 1.
			self
				assert: warnings asArray
				equals: { 'OpenTelemetry span processor callback failed during forceFlush for OTFailingSpanProcessor: processor failure' } ]
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
OTCompositeSpanProcessorTest >> testInvalidProcessorConfigurationIsIgnoredAndWarned [

	self withConfigurationWarningsDo: [ :warnings |
			| composite invalidComposite processorOne processorTwo |
			processorOne := OTRecordingSpanProcessor new.
			processorTwo := OTRecordingSpanProcessor new.
			invalidComposite := OTCompositeSpanProcessor withAll: 42.
			self assert: invalidComposite componentProcessors isEmpty.
			composite := OTCompositeSpanProcessor withAll: { processorOne }.
			composite processors: 42.
			self assert: composite componentProcessors asArray equals: { processorOne }.
			composite processors: {
					processorTwo.
					42.
					nil }.
			self assert: composite componentProcessors asArray equals: { processorTwo }.
			self
				assert: warnings asArray
				equals: { 'OpenTelemetry span processor configuration was invalid and has been ignored for ''processors:'': 42'.
					'OpenTelemetry span processor configuration was invalid and has been ignored for ''processors:'': 42'.
					'OpenTelemetry span processor configuration was invalid and has been ignored for ''processors:'': 42'.
					'OpenTelemetry span processor configuration was invalid and has been ignored for ''processors:'': nil' } ]
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
OTCompositeSpanProcessorTest >> testOnEndContinuesAfterChildFailure [

	self withSpanProcessorWarningsDo: [ :warnings |
			| composite failingProcessor recordingProcessor span |
			failingProcessor := OTFailingSpanProcessor failingOperations: { 'onEnd' }.
			recordingProcessor := OTRecordingSpanProcessor new.
			composite := OTCompositeSpanProcessor withAll: {
					             failingProcessor.
					             recordingProcessor }.
			span := self sampledSpanWithSuffix: 1.
			self deny: (composite onEnd: span).
			self assert: recordingProcessor endedSpans asArray equals: { span }.
			self
				assert: warnings asArray
				equals: { 'OpenTelemetry span processor callback failed during onEnd for OTFailingSpanProcessor: processor failure' } ]
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
OTCompositeSpanProcessorTest >> testOnEndingContinuesAfterChildFailure [

	self withSpanProcessorWarningsDo: [ :warnings |
			| composite exportRecord failingProcessor provider recordingProcessor span tracer |
			provider := OTTracerProvider new.
			provider spanProcessor: OTSimpleSpanProcessor new.
			tracer := provider tracerNamed: 'demo.scope'.
			span := (tracer spanBuilderNamed: 'operation') startSpan.
			failingProcessor := OTFailingSpanProcessor failingOperations: { 'onEnding' }.
			recordingProcessor := OTRecordingSpanProcessor new.
			composite := OTCompositeSpanProcessor withAll: {
					             failingProcessor.
					             recordingProcessor }.
			self deny: (composite onEnding: span).
			exportRecord := span asExportRecord.
			self assert: recordingProcessor endingSpans asArray equals: { span }.
			self assert: ((exportRecord at: #attributes) at: 'processor.onEnding') equals: true.
			self
				assert: warnings asArray
				equals: { 'OpenTelemetry span processor callback failed during onEnding for OTFailingSpanProcessor: processor failure' } ]
]

{ #category : 'tests' }
OTCompositeSpanProcessorTest >> testOnEndingReturnsFalseWhileShutdownIsInProgress [

	| blockingProcessor composite done recordingProcessor shutdownResult span tracer provider |
	blockingProcessor := OTBlockingShutdownSpanProcessor new.
	recordingProcessor := OTRecordingSpanProcessor new.
	composite := OTCompositeSpanProcessor withAll: {
			             blockingProcessor.
			             recordingProcessor }.
	provider := OTTracerProvider new.
	tracer := provider tracerNamed: 'demo.scope'.
	span := (tracer spanBuilderNamed: 'operation') startSpan.
	done := Semaphore new.
	[
		shutdownResult := composite shutdown.
		done signal ] forkAt: Processor userBackgroundPriority.
	self assert: (blockingProcessor waitForShutdownTimeoutMillis: 200).
	self deny: (composite onEnding: span).
	self assert: recordingProcessor endingSpans isEmpty.
	blockingProcessor allowShutdown.
	self assert: (done waitTimeoutMilliseconds: 200) not.
	self assert: shutdownResult
]

{ #category : 'tests' }
OTCompositeSpanProcessorTest >> testOnStartContinuesAfterChildFailure [

	self withSpanProcessorWarningsDo: [ :warnings |
			| composite failingProcessor recordingProcessor span |
			failingProcessor := OTFailingSpanProcessor failingOperations: { 'onStart' }.
			recordingProcessor := OTRecordingSpanProcessor new.
			composite := OTCompositeSpanProcessor withAll: {
					             failingProcessor.
					             recordingProcessor }.
			span := self sampledSpanWithSuffix: 1.
			self deny: (composite onStart: span parentContext: OTContext new).
			self assert: recordingProcessor startedSpans asArray equals: { span }.
			self assert: recordingProcessor startedParentContexts size equals: 1.
			self
				assert: warnings asArray
				equals: { 'OpenTelemetry span processor callback failed during onStart for OTFailingSpanProcessor: processor failure' } ]
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

{ #category : 'tests' }
OTCompositeSpanProcessorTest >> testShutdownContinuesAfterChildFailure [

	self withSpanProcessorWarningsDo: [ :warnings |
			| composite failingProcessor succeedingProcessor |
			failingProcessor := OTFailingSpanProcessor failingOperations: { 'forceFlush'. 'shutdown' }.
			succeedingProcessor := OTFailingSpanProcessor new.
			composite := OTCompositeSpanProcessor withAll: {
					             failingProcessor.
					             succeedingProcessor }.
			self deny: composite shutdown.
			self assert: composite isShutdown.
			self assert: succeedingProcessor forceFlushCount equals: 1.
			self assert: succeedingProcessor shutdownCount equals: 1.
			self
				assert: warnings asArray
				equals: { 'OpenTelemetry span processor callback failed during forceFlush for OTFailingSpanProcessor: processor failure'.
					'OpenTelemetry span processor callback failed during shutdown for OTFailingSpanProcessor: processor failure' } ]
]

{ #category : 'private' }
OTCompositeSpanProcessorTest >> withConfigurationWarningsDo: aBlock [

	| warnings |
	warnings := OrderedCollection new.
	OTSpanProcessor configurationWarningSink: [ :message | warnings add: message ].
	[ ^ aBlock value: warnings ] ensure: [ OTSpanProcessor configurationWarningSink: nil ]
]

{ #category : 'private' }
OTCompositeSpanProcessorTest >> withSpanProcessorWarningsDo: aBlock [

	| warnings |
	warnings := OrderedCollection new.
	OTTracerProvider spanProcessorWarningSink: [ :message | warnings add: message ].
	[ ^ aBlock value: warnings ] ensure: [ OTTracerProvider spanProcessorWarningSink: nil ]
]
