Class {
	#name : 'OTOnEndingShutdownTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'private' }
OTOnEndingShutdownTest >> assertShutdownSkipsLaterCallbacksUsingComposite: useComposite [

	| first second provider span done process errors |
	first := OTBlockingOnEndingSpanProcessor new.
	second := OTRecordingSpanProcessor new.
	provider := OTTracerProvider new.
	useComposite
		ifTrue: [
				provider spanProcessor: (OTCompositeSpanProcessor withAll: {
							 first.
							 second }) ]
		ifFalse: [
				provider
					spanProcessor: first;
					addSpanProcessor: second ].
	span := ((provider tracerNamed: 'shutdown') spanBuilderNamed: 'operation') startSpan.
	done := Semaphore new.
	errors := OrderedCollection new.
	process := [
		           [ span end ]
			           on: Error
			           do: [ :error | errors add: error ].
		           done signal ] fork.
	[
		self assert: (first waitForOnEndingTimeoutMillis: 1000).
		self assert: provider shutdown.
		first allowOnEnding.
		self deny: (done waitTimeoutMilliseconds: 1000).
		self assert: errors isEmpty.
		self assert: second endingSpans isEmpty ] ensure: [
			first allowOnEnding.
			process terminate.
			provider shutdown ]
]

{ #category : 'tests' }
OTOnEndingShutdownTest >> testCompositeSkipsOnEndingAfterShutdownDuringAnEarlierCallback [

	self assertShutdownSkipsLaterCallbacksUsingComposite: true
]

{ #category : 'tests' }
OTOnEndingShutdownTest >> testProviderSkipsOnEndingAfterShutdownDuringAnEarlierCallback [

	self assertShutdownSkipsLaterCallbacksUsingComposite: false
]
