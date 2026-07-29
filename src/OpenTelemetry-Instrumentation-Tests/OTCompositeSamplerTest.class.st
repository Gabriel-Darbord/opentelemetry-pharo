Class {
	#name : 'OTCompositeSamplerTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'private' }
OTCompositeSamplerTest >> contextWithTraceFlags: aTraceFlags traceState: aTraceState [

	^ OTContext new withSpan: (OTSpanContext
			   traceId: '00112233445566778899aabbccddeeff'
			   spanId: '1122334455667788'
			   traceFlags: aTraceFlags
			   traceState: aTraceState
			   remote: false) asNonRecordingSpan
]

{ #category : 'private' }
OTCompositeSamplerTest >> fullThresholdStringFor: aThreshold [

	^ String streamContents: [ :stream | OTConsistentProbability writeThreshold: aThreshold on: stream ]
]

{ #category : 'private' }
OTCompositeSamplerTest >> sampleWith: aSampler traceFlags: aTraceFlags otelTraceState: otelTraceState traceId: aTraceId [

	| traceState |
	traceState := otelTraceState ifNotNil: [ 'ot=' , otelTraceState ].
	^ aSampler
		  shouldSampleIn: (self contextWithTraceFlags: aTraceFlags traceState: traceState)
		  traceId: aTraceId
		  name: 'operation'
		  kind: OTSpan internal
		  attributes: #(  )
		  links: #(  )
]

{ #category : 'tests' }
OTCompositeSamplerTest >> testComposableProbabilityZeroReturnsComposableAlwaysOff [

	self assert: (OTComposableSampler probability: 0) class identicalTo: OTComposableAlwaysOffSampler
]

{ #category : 'tests' }
OTCompositeSamplerTest >> testCompositeAnnotatingAddsAttributesOnlyWhenSampled [

	| result sampler |
	sampler := OTSampler composite:
		           (OTComposableSampler annotating: { ('sampler.rule' -> 'checkout') } delegate: OTComposableSampler alwaysOn).
	result := sampler
		          shouldSampleIn: OTContext new
		          traceId: '00112233445566778899aabbccddeeff'
		          name: 'checkout'
		          kind: OTSpan internal
		          attributes: #(  )
		          links: #(  ).
	self assert: result isRecordAndSample.
	self assert: result attributes equals: { ('sampler.rule' -> 'checkout') }
]

{ #category : 'tests' }
OTCompositeSamplerTest >> testCompositeParentThresholdDropsUnsampledParentWithoutThreshold [

	| result sampler |
	sampler := OTSampler composite: (OTComposableSampler parentThreshold: OTComposableSampler alwaysOn).
	result := sampler
		          shouldSampleIn: (self contextWithTraceFlags: '00' traceState: nil)
		          traceId: '00112233445566778899aabbccddeeff'
		          name: 'child'
		          kind: OTSpan internal
		          attributes: #(  )
		          links: #(  ).
	self assert: result isDrop.
	self assert: result traceState equals: nil
]

{ #category : 'tests' }
OTCompositeSamplerTest >> testCompositeParentThresholdUsesParentThresholdWithoutRevalidatingSampledFlag [

	| result sampler |
	sampler := OTSampler composite: (OTComposableSampler parentThreshold: OTComposableSampler alwaysOn).
	result := sampler
		          shouldSampleIn: (self contextWithTraceFlags: '00' traceState: 'ot=rv:7f99aa40c02744;th:7f99aa40c02744')
		          traceId: '00112233445566778899aabbccddeeff'
		          name: 'child'
		          kind: OTSpan internal
		          attributes: #(  )
		          links: #(  ).
	self assert: result isRecordAndSample.
	self assert: (result traceState otelValueAt: 'rv') equals: '7f99aa40c02744'.
	self assert: (result traceState otelValueAt: 'th') equals: '7f99aa40c02744'
]

{ #category : 'tests' }
OTCompositeSamplerTest >> testCompositeParentThresholdUsesRootSamplerWithoutParent [

	| result sampler |
	sampler := OTSampler composite: (OTComposableSampler parentThreshold: OTComposableSampler alwaysOff).
	result := sampler
		          shouldSampleIn: OTContext new
		          traceId: '00112233445566778899aabbccddeeff'
		          name: 'root'
		          kind: OTSpan internal
		          attributes: #(  )
		          links: #(  ).
	self assert: result isDrop
]

{ #category : 'tests' }
OTCompositeSamplerTest >> testCompositeParentThresholdUsesSampledParentThresholdWhenAvailable [

	| result sampler |
	sampler := OTSampler composite: (OTComposableSampler parentThreshold: OTComposableSampler alwaysOff).
	result := sampler
		          shouldSampleIn: (self contextWithTraceFlags: '01' traceState: 'ot=rv:80000000000000;th:8')
		          traceId: '00112233445566778899aabbccddeeff'
		          name: 'child'
		          kind: OTSpan internal
		          attributes: #(  )
		          links: #(  ).
	self assert: result isRecordAndSample.
	self assert: (result traceState otelValueAt: 'rv') equals: '80000000000000'.
	self assert: (result traceState otelValueAt: 'th') equals: '8'
]

{ #category : 'tests' }
OTCompositeSamplerTest >> testCompositeProbabilitySamplerAddsThresholdAndPreservesExplicitRandomness [

	| result sampler |
	sampler := OTSampler composite: (OTComposableSampler probability: 0.5).
	result := sampler
		          shouldSampleIn: (self contextWithTraceFlags: '00' traceState: 'ot=rv:80000000000000')
		          traceId: '00112233445566778899aabbccddeeff'
		          name: 'operation'
		          kind: OTSpan internal
		          attributes: #(  )
		          links: #(  ).
	self assert: result isRecordAndSample.
	self assert: (result traceState otelValueAt: 'rv') equals: '80000000000000'.
	self assert: (result traceState otelValueAt: 'th') equals: '8'
]

{ #category : 'tests' }
OTCompositeSamplerTest >> testCompositeProbabilitySamplerMatchesJavaExactThresholdExamples [

	| examples traceId |
	traceId := '00112233445566778800000000000000'.
	examples := {
		            { 1.0. 0 }.
		            { 0.5. 36028797018963968 }.
		            { 0.25. 54043195528445952 }.
		            { 0.125. 63050394783186944 } }.
	examples do: [ :each |
			| droppedResult droppedRv expectedThreshold expectedThresholdString probability sampledResult sampledRv sampler |
			probability := each first.
			expectedThreshold := each second.
			expectedThresholdString := OTConsistentProbability thresholdStringFor: expectedThreshold.
			self assert: (OTConsistentProbability thresholdForProbability: probability) equals: expectedThreshold.
			sampler := OTSampler composite: (OTComposableSampler probability: probability).
			sampledRv := self fullThresholdStringFor: expectedThreshold.
			sampledResult := self
				                 sampleWith: sampler
				                 traceFlags: '00'
				                 otelTraceState: 'rv:' , sampledRv
				                 traceId: traceId.
			self assert: sampledResult isRecordAndSample.
			self assert: (sampledResult traceState otelValueAt: 'rv') equals: sampledRv.
			self assert: (sampledResult traceState otelValueAt: 'th') equals: expectedThresholdString.
			expectedThreshold = 0 ifFalse: [
					droppedRv := self fullThresholdStringFor: expectedThreshold - 1.
					droppedResult := self
						                 sampleWith: sampler
						                 traceFlags: '00'
						                 otelTraceState: 'rv:' , droppedRv
						                 traceId: traceId.
					self assert: droppedResult isDrop.
					self assert: (droppedResult traceState otelValueAt: 'rv') equals: droppedRv.
					self assert: (droppedResult traceState otelValueAt: 'th') equals: nil ] ]
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
OTCompositeSamplerTest >> testCompositeProbabilitySamplerMatchesPublishedThresholdTableExamples [

	| examples |
	examples := {
		            (0.5 -> '8').
		            (0.25 -> 'c').
		            (1.0 / 3.0 -> 'aaab').
		            (0.1 -> 'e666').
		            (0.01 -> 'fd70a') }.
	examples do: [ :each |
			| threshold droppedResult droppedRv sampledResult sampledRv sampler |
			threshold := OTConsistentProbability thresholdFromString: each value.
			sampledRv := String streamContents: [ :stream | OTConsistentProbability writeThreshold: threshold on: stream ].
			droppedRv := String streamContents: [ :stream | OTConsistentProbability writeThreshold: threshold - 1 on: stream ].
			sampler := OTSampler composite: (OTComposableSampler probability: each key).
			sampledResult := sampler
				                 shouldSampleIn: (self contextWithTraceFlags: '00' traceState: 'ot=rv:' , sampledRv)
				                 traceId: '00112233445566778899aabbccddeeff'
				                 name: 'operation'
				                 kind: OTSpan internal
				                 attributes: #(  )
				                 links: #(  ).
			self assert: sampledResult isRecordAndSample.
			self assert: (sampledResult traceState otelValueAt: 'rv') equals: sampledRv.
			self assert: (sampledResult traceState otelValueAt: 'th') equals: each value.
			droppedResult := sampler
				                 shouldSampleIn: (self contextWithTraceFlags: '00' traceState: 'ot=rv:' , droppedRv)
				                 traceId: '00112233445566778899aabbccddeeff'
				                 name: 'operation'
				                 kind: OTSpan internal
				                 attributes: #(  )
				                 links: #(  ).
			self assert: droppedResult isDrop.
			self assert: (droppedResult traceState otelValueAt: 'rv') equals: droppedRv.
			self assert: (droppedResult traceState otelValueAt: 'th') equals: nil ]
]

{ #category : 'tests' }
OTCompositeSamplerTest >> testCompositeProbabilitySamplerUsesRecommendedDefaultThresholdPrecisionExamples [

	| examples |
	examples := {
		            (0.1 -> 'e666').
		            (0.01 -> 'fd70a').
		            (1.0 / 3.0 -> 'aaab') }.
	examples do: [ :each |
			| result sampler |
			sampler := OTSampler composite: (OTComposableSampler probability: each key).
			result := sampler
				          shouldSampleIn: (self contextWithTraceFlags: '00' traceState: 'ot=rv:ffffffffffffff')
				          traceId: '00112233445566778899aabbccddeeff'
				          name: 'operation'
				          kind: OTSpan internal
				          attributes: #(  )
				          links: #(  ).
			self assert: (result traceState otelValueAt: 'th') equals: each value ]
]

{ #category : 'tests' }
OTCompositeSamplerTest >> testCompositeRuleBasedUsesFirstMatchingRule [

	| healthResult sampler traceResult |
	sampler := OTSampler composite: (OTComposableSampler ruleBased: {
				            ([ :context :name | name = 'healthcheck' ] -> OTComposableSampler alwaysOff).
				            ([ true ] -> OTComposableSampler alwaysOn) }).
	healthResult := sampler
		                shouldSampleIn: OTContext new
		                traceId: '00112233445566778899aabbccddeeff'
		                name: 'healthcheck'
		                kind: OTSpan internal
		                attributes: #(  )
		                links: #(  ).
	traceResult := sampler
		               shouldSampleIn: OTContext new
		               traceId: '00112233445566778899aabbccddeeff'
		               name: 'checkout'
		               kind: OTSpan internal
		               attributes: #(  )
		               links: #(  ).
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
OTCompositeSamplerTest >> testCompositeSamplerMatchesJavaReferenceVectors [

	| cases traceId |
	traceId := '00112233445566778800000000000000'.
	cases := {
		         {
			         [ OTSampler composite: OTComposableSampler alwaysOn ].
			         '01'.
			         nil.
			         true.
			         'th:0' }.
		         {
			         [ OTSampler composite: OTComposableSampler alwaysOn ].
			         '01'.
			         'rv:7f99aa40c02744'.
			         true.
			         'th:0;rv:7f99aa40c02744' }.
		         {
			         [ OTSampler composite: OTComposableSampler alwaysOff ].
			         '01'.
			         nil.
			         false.
			         nil }.
		         {
			         [ OTSampler composite: (OTComposableSampler parentThreshold: OTComposableSampler alwaysOn) ].
			         '00'.
			         'th:7f99aa40c02744;rv:7f99aa40c02744'.
			         true.
			         'th:7f99aa40c02744;rv:7f99aa40c02744' }.
		         {
			         [ OTSampler composite: (OTComposableSampler parentThreshold: OTComposableSampler alwaysOn) ].
			         '01'.
			         nil.
			         true.
			         nil }.
		         {
			         [ OTSampler composite: (OTComposableSampler parentThreshold: OTComposableSampler alwaysOn) ].
			         '00'.
			         nil.
			         false.
			         nil }.
		         {
			         [ OTSampler composite: (OTComposableSampler probability: 0.5) ].
			         '01'.
			         'rv:7fffffffffffff'.
			         false.
			         'rv:7fffffffffffff' }.
		         {
			         [ OTSampler composite: (OTComposableSampler probability: 0.5) ].
			         '00'.
			         'rv:80000000000000'.
			         true.
			         'th:8;rv:80000000000000' }.
		         {
			         [ OTSampler composite: (OTComposableSampler probability: 0.25) ].
			         '00'.
			         'rv:bfffffffffffff'.
			         false.
			         'rv:bfffffffffffff' }.
		         {
			         [ OTSampler composite: (OTComposableSampler probability: 0.25) ].
			         '00'.
			         'rv:c0000000000000'.
			         true.
			         'th:c;rv:c0000000000000' }.
		         {
			         [ OTSampler composite: (OTComposableSampler probability: 1.0) ].
			         '00'.
			         'th:80000000000000;rv:80000000000000'.
			         true.
			         'th:0;rv:80000000000000' } }.
	cases do: [ :each |
			| expectedTraceState result sampler |
			sampler := each first value.
			result := self
				          sampleWith: sampler
				          traceFlags: each second
				          otelTraceState: each third
				          traceId: traceId.
			each fourth
				ifTrue: [ self assert: result isRecordAndSample ]
				ifFalse: [ self assert: result isDrop ].
			each fifth ifNil: [ self assert: result traceState equals: nil ] ifNotNil: [
					expectedTraceState := OTTraceState fromHeader: 'ot=' , each fifth.
					self assert: result traceState otelEntries equals: expectedTraceState otelEntries ] ]
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

{ #category : 'tests' }
OTCompositeSamplerTest >> testCompositeSamplerRemovesThresholdOnDropEvenWithoutExplicitRandomness [

	| cases traceId |
	traceId := '00112233445566778800000000000000'.
	cases := {
		         {
			         (OTSampler composite: OTComposableSampler alwaysOff).
			         '00' }.
		         {
			         (OTSampler composite: OTComposableSampler alwaysOff).
			         '01' }.
		         {
			         (OTSampler composite: (OTComposableSampler parentThreshold: OTComposableSampler alwaysOn)).
			         '00' }.
		         {
			         (OTSampler composite: (OTComposableSampler parentThreshold: OTComposableSampler alwaysOn)).
			         '01' }.
		         {
			         (OTSampler composite: (OTComposableSampler probability: 0.5)).
			         '00' }.
		         {
			         (OTSampler composite: (OTComposableSampler probability: 0.5)).
			         '01' } }.
	cases do: [ :each |
			| result |
			result := each first
				          shouldSampleIn: (self contextWithTraceFlags: each second traceState: 'ot=th:8')
				          traceId: traceId
				          name: 'operation'
				          kind: OTSpan internal
				          attributes: #(  )
				          links: #(  ).
			self assert: result isDrop.
			self assert: (result traceState otelValueAt: 'th') equals: nil.
			self assert: (result traceState valueAt: 'ot' ifAbsent: [ nil ]) equals: nil ]
]
