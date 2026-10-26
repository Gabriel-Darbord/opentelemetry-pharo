Class {
	#name : 'OTSamplerShutdownTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'tests' }
OTSamplerShutdownTest >> testCleanupContinuesAfterOneDelegateFails [

	| delegate sampler |
	delegate := OTShutdownCountingSampler new.
	sampler := OTParentBasedSampler root: (OTFailingSampler failingOperations: #( 'shutdown' )).
	sampler localParentSampledSampler: delegate.
	self deny: sampler shutdown.
	self assert: delegate shutdownCount equals: 1
]

{ #category : 'tests' }
OTSamplerShutdownTest >> testConcurrentShutdownInvokesCleanupOnce [

	| delegate sampler done gate results lock |
	delegate := OTShutdownCountingSampler new.
	sampler := OTSampler alwaysRecord: delegate.
	done := Semaphore new.
	gate := Semaphore new.
	lock := Semaphore forMutualExclusion.
	results := OrderedCollection new.
	8 timesRepeat: [
			[
				| result |
				gate wait.
				result := sampler shutdown.
				lock critical: [ results add: result ].
				done signal ] fork ].
	8 timesRepeat: [ gate signal ].
	8 timesRepeat: [ self deny: (done waitTimeoutMilliseconds: 1000) ].
	self assert: (results count: [ :each | each ]) equals: 1.
	self assert: delegate shutdownCount equals: 1
]

{ #category : 'tests' }
OTSamplerShutdownTest >> testRemoteSamplersDropAfterShutdown [

	{
		OTJaegerRemoteSampler new.
		OTXRayRemoteSampler new } do: [ :sampler |
			self assert: sampler shutdown.
			self
				assert: (sampler
						 shouldSampleIn: OTContext new
						 traceId: '12345678876543211234567887654321'
						 name: 'closed'
						 kind: #internal
						 attributes: #(  )
						 links: #(  )) decision
				equals: #drop ]
]

{ #category : 'tests' }
OTSamplerShutdownTest >> testWrappersDoNotRepeatCleanupOrSampleAfterShutdown [

	| delegate wrappers |
	delegate := OTShutdownCountingSampler new.
	wrappers := {
		            (OTSampler alwaysRecord: delegate).
		            (OTParentBasedSampler root: delegate).
		            (OTSampler composite: delegate).
		            (OTComposableSampler annotating: #(  ) delegate: delegate).
		            (OTComposableSampler parentThreshold: delegate).
		            (OTComposableSampler ruleBased: {
				             ([ true ] -> delegate).
				             ([ true ] -> delegate) }).
		            (OTPerOperationSampler new
			             defaultSampler: delegate;
			             perOperationSamplers: {
					             ('one' -> delegate).
					             ('two' -> delegate) };
			             yourself).
		            (OTJaegerRemoteSampler new
			             initialSampler: delegate;
			             yourself) }.
	wrappers withIndexDo: [ :wrapper :index |
			self assert: wrapper shutdown.
			self deny: wrapper shutdown.
			self assert: wrapper isShutdown.
			self assert: delegate shutdownCount equals: index.
			(wrapper isKindOf: OTSampler)
				ifTrue: [
						self
							assert: (wrapper
									 shouldSampleIn: OTContext new
									 traceId: '12345678876543211234567887654321'
									 name: 'closed'
									 kind: #internal
									 attributes: #(  )
									 links: #(  )) decision
							equals: #drop ]
				ifFalse: [
						self assert: (wrapper
								 samplingIntentIn: OTContext new
								 name: 'closed'
								 kind: #internal
								 attributes: #(  )
								 links: #(  )) threshold isNil ] ].
	self assert: delegate samplingCount equals: 0
]
