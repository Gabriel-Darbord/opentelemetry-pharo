"
I decorate a composable sampler by appending attributes to the sampling intent produced by a delegate sampler.
"
Class {
	#name : 'OTComposableAnnotatingSampler',
	#superclass : 'OTComposableSampler',
	#instVars : [
		'attributes',
		'delegate'
	],
	#category : 'OpenTelemetry-Sampling',
	#package : 'OpenTelemetry-Sampling'
}

{ #category : 'accessing' }
OTComposableAnnotatingSampler >> attributes [

	^ attributes ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
OTComposableAnnotatingSampler >> attributes: aCollection [

	attributes := aCollection asArray
]

{ #category : 'accessing' }
OTComposableAnnotatingSampler >> delegate [

	^ delegate
]

{ #category : 'accessing' }
OTComposableAnnotatingSampler >> delegate: aComposableSampler [

	aComposableSampler ifNil: [ self error: 'ComposableAnnotating requires a delegate sampler' ].
	delegate := aComposableSampler
]

{ #category : 'accessing' }
OTComposableAnnotatingSampler >> description [

	^ String streamContents: [ :s | s << 'ComposableAnnotating{' << delegate description << '}' ]
]

{ #category : 'sampling' }
OTComposableAnnotatingSampler >> samplingIntentIn: aContext name: aString kind: aSpanKind attributes: someAttributes links: someLinks [

	| delegateIntent extraAttributes |
	delegateIntent := delegate
		                  samplingIntentIn: aContext
		                  name: aString
		                  kind: aSpanKind
		                  attributes: someAttributes
		                  links: someLinks.
	extraAttributes := self attributes.
	^ OTSamplingIntent
		  threshold: delegateIntent threshold
		  adjustedCountReliable: delegateIntent adjustedCountReliable
		  attributesProvider: [ delegateIntent attributes , extraAttributes ]
		  traceStateProvider: [ :traceState :decision | delegateIntent traceStateForParent: traceState decision: decision ]
]

{ #category : 'lifecycle' }
OTComposableAnnotatingSampler >> shutdown [

	^ delegate shutdown
]

{ #category : 'lifecycle' }
OTComposableAnnotatingSampler >> start [

	delegate start
]
