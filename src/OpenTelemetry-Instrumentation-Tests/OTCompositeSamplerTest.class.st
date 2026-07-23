Class {
	#name : 'OTCompositeSamplerTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'private' }
OTCompositeSamplerTest >> contextWithTraceFlags: aTraceFlags traceState: aTraceState [

	^ OTContext new
		withSpan: ((OTSpanContext
			traceId: '00112233445566778899aabbccddeeff'
			spanId: '1122334455667788'
			traceFlags: aTraceFlags
			traceState: aTraceState
			remote: false) asNonRecordingSpan)
]

{ #category : 'tests' }
OTCompositeSamplerTest >> testComposableProbabilityZeroReturnsComposableAlwaysOff [

	self
		assert: (OTComposableSampler probability: 0) class
		identicalTo: OTComposableAlwaysOffSampler
]

{ #category : 'tests' }
OTCompositeSamplerTest >> testCompositeAnnotatingAddsAttributesOnlyWhenSampled [

	| result sampler |
	sampler := OTSampler composite: (OTComposableSampler
		annotating: { 'sampler.rule' -> 'checkout' }
		delegate: OTComposableSampler alwaysOn).
	result := sampler
		shouldSampleIn: OTContext new
		traceId: '00112233445566778899aabbccddeeff'
		name: 'checkout'
		kind: OTSpan internal
		attributes: #()
		links: #().
	self assert: result isRecordAndSample.
	self
		assert: result attributes
		equals: { 'sampler.rule' -> 'checkout' }
]

{ #category : 'tests' }
OTCompositeSamplerTest >> testCompositeParentThresholdDropsUnsampledParentWithoutThreshold [

	| result sampler |
	sampler := OTSampler composite: (OTComposableSampler
		parentThreshold: OTComposableSampler alwaysOn).
	result := sampler
		shouldSampleIn: (self
				contextWithTraceFlags: '00'
				traceState: nil)
		traceId: '00112233445566778899aabbccddeeff'
		name: 'child'
		kind: OTSpan internal
		attributes: #()
		links: #().
	self assert: result isDrop.
	self assert: result traceState equals: nil
]

{ #category : 'tests' }
OTCompositeSamplerTest >> testCompositeParentThresholdErasesInconsistentParentThreshold [

	| result sampler |
	sampler := OTSampler composite: (OTComposableSampler
		parentThreshold: OTComposableSampler alwaysOff).
	result := sampler
		shouldSampleIn: (self
				contextWithTraceFlags: '01'
				traceState: 'ot=rv:7fffffffffffff;th:8')
		traceId: '00112233445566778899aabbccddeeff'
		name: 'child'
		kind: OTSpan internal
		attributes: #()
		links: #().
	self assert: result isRecordAndSample.
	self assert: (result traceState otelValueAt: 'rv') equals: '7fffffffffffff'.
	self assert: (result traceState otelValueAt: 'th') equals: nil
]

{ #category : 'tests' }
OTCompositeSamplerTest >> testCompositeParentThresholdUsesRootSamplerWithoutParent [

	| result sampler |
	sampler := OTSampler composite: (OTComposableSampler
		parentThreshold: OTComposableSampler alwaysOff).
	result := sampler
		shouldSampleIn: OTContext new
		traceId: '00112233445566778899aabbccddeeff'
		name: 'root'
		kind: OTSpan internal
		attributes: #()
		links: #().
	self assert: result isDrop
]

{ #category : 'tests' }
OTCompositeSamplerTest >> testCompositeParentThresholdUsesSampledParentThresholdWhenAvailable [

	| result sampler |
	sampler := OTSampler composite: (OTComposableSampler
		parentThreshold: OTComposableSampler alwaysOff).
	result := sampler
		shouldSampleIn: (self
				contextWithTraceFlags: '01'
				traceState: 'ot=rv:80000000000000;th:8')
		traceId: '00112233445566778899aabbccddeeff'
		name: 'child'
		kind: OTSpan internal
		attributes: #()
		links: #().
	self assert: result isRecordAndSample.
	self assert: (result traceState otelValueAt: 'rv') equals: '80000000000000'.
	self assert: (result traceState otelValueAt: 'th') equals: '8'
]

{ #category : 'tests' }
OTCompositeSamplerTest >> testCompositeProbabilitySamplerAddsThresholdAndPreservesExplicitRandomness [

	| result sampler |
	sampler := OTSampler composite: (OTComposableSampler probability: 0.5).
	result := sampler
		shouldSampleIn: (self
				contextWithTraceFlags: '00'
				traceState: 'ot=rv:80000000000000')
		traceId: '00112233445566778899aabbccddeeff'
		name: 'operation'
		kind: OTSpan internal
		attributes: #()
		links: #().
	self assert: result isRecordAndSample.
	self assert: (result traceState otelValueAt: 'rv') equals: '80000000000000'.
	self assert: (result traceState otelValueAt: 'th') equals: '8'
]

{ #category : 'tests' }
OTCompositeSamplerTest >> testCompositeProbabilitySamplerMatchesPublishedQuarterSamplingExample [

	| droppedResult sampledResult sampler |
	sampler := OTSampler composite: (OTComposableSampler probability: 0.25).
	sampledResult := sampler
		                 shouldSampleIn: (self contextWithTraceFlags: '00' traceState: 'ot=rv:c0000000000000')
		                 traceId: '00112233445566778899aabbccddeeff'
		                 name: 'operation'
		                 kind: OTSpan internal
		                 attributes: #(  )
		                 links: #(  ).
	self assert: sampledResult isRecordAndSample.
	self assert: (sampledResult traceState otelValueAt: 'rv') equals: 'c0000000000000'.
	self assert: (sampledResult traceState otelValueAt: 'th') equals: 'c'.
	droppedResult := sampler
		                 shouldSampleIn: (self contextWithTraceFlags: '00' traceState: 'ot=rv:bfffffffffffff')
		                 traceId: '00112233445566778899aabbccddeeff'
		                 name: 'operation'
		                 kind: OTSpan internal
		                 attributes: #(  )
		                 links: #(  ).
	self assert: droppedResult isDrop.
	self assert: (droppedResult traceState otelValueAt: 'rv') equals: 'bfffffffffffff'.
	self assert: (droppedResult traceState otelValueAt: 'th') equals: nil
]

{ #category : 'tests' }
OTCompositeSamplerTest >> testCompositeRuleBasedUsesFirstMatchingRule [

	| healthResult sampler traceResult |
	sampler := OTSampler composite: (OTComposableSampler ruleBased: {
		[ :context :name | name = 'healthcheck' ] -> OTComposableSampler alwaysOff.
		[ true ] -> OTComposableSampler alwaysOn }).
	healthResult := sampler
		shouldSampleIn: OTContext new
		traceId: '00112233445566778899aabbccddeeff'
		name: 'healthcheck'
		kind: OTSpan internal
		attributes: #()
		links: #().
	traceResult := sampler
		shouldSampleIn: OTContext new
		traceId: '00112233445566778899aabbccddeeff'
		name: 'checkout'
		kind: OTSpan internal
		attributes: #()
		links: #().
	self assert: healthResult isDrop.
	self assert: traceResult isRecordAndSample.
	self assert: (traceResult traceState otelValueAt: 'th') equals: '0'
]

{ #category : 'tests' }
OTCompositeSamplerTest >> testCompositeSamplerIgnoresInjectedOtelEntriesWhenNoParentProvidesThem [

	| intent result sampler |
	intent := OTSamplingIntent
		          threshold: 0
		          adjustedCountReliable: true
		          attributesProvider: nil
		          traceStateProvider: [ :traceState :decision | OTTraceState from: 'vendor=two,ot=rv:00000000000000;th:1' ].
	sampler := OTSampler composite: (OTFixedSamplingIntentComposableSampler intent: intent).
	result := sampler
		          shouldSampleIn: OTContext new
		          traceId: '00112233445566778899aabbccddeeff'
		          name: 'operation'
		          kind: OTSpan internal
		          attributes: #(  )
		          links: #(  ).
	self assert: result isRecordAndSample.
	self assert: (result traceState valueAt: 'vendor') equals: 'two'.
	self assert: (result traceState otelValueAt: 'rv') equals: nil.
	self assert: (result traceState otelValueAt: 'th') equals: '0'
]

{ #category : 'tests' }
OTCompositeSamplerTest >> testCompositeSamplerPreservesParentOtelEntriesWhenComposableMutatesThem [

	| intent result sampler |
	intent := OTSamplingIntent
		          threshold: 0
		          adjustedCountReliable: true
		          attributesProvider: nil
		          traceStateProvider: [ :traceState :decision | OTTraceState from: 'vendor=two,ot=rv:00000000000000;th:1' ].
	sampler := OTSampler composite: (OTFixedSamplingIntentComposableSampler intent: intent).
	result := sampler
		          shouldSampleIn: (self contextWithTraceFlags: '00' traceState: 'vendor=one,ot=rv:80000000000000;th:9')
		          traceId: '00112233445566778899aabbccddeeff'
		          name: 'operation'
		          kind: OTSpan internal
		          attributes: #(  )
		          links: #(  ).
	self assert: result isRecordAndSample.
	self assert: (result traceState valueAt: 'vendor') equals: 'two'.
	self assert: (result traceState otelValueAt: 'rv') equals: '80000000000000'.
	self assert: (result traceState otelValueAt: 'th') equals: '0'
]
