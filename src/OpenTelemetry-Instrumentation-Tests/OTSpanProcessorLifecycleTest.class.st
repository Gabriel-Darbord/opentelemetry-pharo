Class {
	#name : 'OTSpanProcessorLifecycleTest',
	#superclass : 'TestCase',
	#instVars : [
		'processor'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'running' }
OTSpanProcessorLifecycleTest >> tearDown [

	[
		processor ifNotNil: [ processor shutdown ].
		OTSpanProcessor current: nil.
		OTTracerProvider current: nil.
		OTSpanExporter current: nil ] ensure: [ super tearDown ]
]

{ #category : 'tests' }
OTSpanProcessorLifecycleTest >> testInheritedShutdownInvokesFlushAndMarksProcessorShutdown [

	processor := OTFlushTrackingSpanProcessor new.
	self assert: processor shutdown.
	self assert: processor flushCount equals: 1.
	self assert: processor isShutdown.
	self deny: processor forceFlush
]

{ #category : 'tests' }
OTSpanProcessorLifecycleTest >> testInheritedShutdownResultInvokesFlushAndMarksProcessorShutdown [

	| result |
	processor := OTFlushTrackingSpanProcessor new.
	result := processor shutdownResult.
	self assert: result isSuccess.
	self assert: processor flushCount equals: 1.
	self assert: processor isShutdown.
	self deny: processor forceFlush
]

{ #category : 'tests' }
OTSpanProcessorLifecycleTest >> testProviderShutdownResultSucceedsWithProcessorUsingInheritedLifecycle [

	| provider result |
	provider := OTTracerProvider new.
	processor := OTFlushTrackingSpanProcessor new.
	provider spanProcessor: processor.
	result := provider shutdownResult.
	self assert: result isSuccess.
	self assert: processor flushCount equals: 1.
	self assert: processor isShutdown
]

{ #category : 'tests' }
OTSpanProcessorLifecycleTest >> testProviderShutdownSucceedsWithProcessorUsingInheritedLifecycle [

	| provider |
	provider := OTTracerProvider new.
	processor := OTFlushTrackingSpanProcessor new.
	provider spanProcessor: processor.
	self assert: provider shutdown.
	self assert: processor flushCount equals: 1.
	self assert: processor isShutdown
]
