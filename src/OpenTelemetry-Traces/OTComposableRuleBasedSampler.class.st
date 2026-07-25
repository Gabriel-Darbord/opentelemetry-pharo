"
I evaluate predicate-to-sampler rules in order and delegate to the first matching composable sampler.
"
Class {
	#name : 'OTComposableRuleBasedSampler',
	#superclass : 'OTComposableSampler',
	#instVars : [
		'rules'
	],
	#category : 'OpenTelemetry-Traces',
	#package : 'OpenTelemetry-Traces'
}

{ #category : 'accessing' }
OTComposableRuleBasedSampler >> description [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'ComposableRuleBased{';
				  print: rules size;
				  nextPutAll: ' rules}' ]
]

{ #category : 'initialization' }
OTComposableRuleBasedSampler >> initialize [

	super initialize.
	rules := OrderedCollection new
]

{ #category : 'private' }
OTComposableRuleBasedSampler >> matches: aPredicate in: aContext name: aString kind: aSpanKind attributes: someAttributes links: someLinks [

	| arguments |
	aPredicate numArgs = 0 ifTrue: [ ^ aPredicate value ].
	(aPredicate numArgs between: 1 and: 5) ifFalse: [
		self error: 'ComposableRuleBased predicates must accept between 0 and 5 arguments' ].
	arguments := {
		             aContext.
		             aString.
		             aSpanKind.
		             someAttributes.
		             someLinks }.
	^ aPredicate valueWithArguments: (arguments copyFrom: 1 to: aPredicate numArgs)
]

{ #category : 'accessing' }
OTComposableRuleBasedSampler >> rules [

	^ rules
]

{ #category : 'accessing' }
OTComposableRuleBasedSampler >> rules: aCollection [

	rules := aCollection
		         collect: [ :each |
				         each isAssociation ifFalse: [ self error: 'ComposableRuleBased rules must be predicate->sampler associations' ].
				         each key ifNil: [ self error: 'ComposableRuleBased rules require a predicate block' ].
				         each value ifNil: [ self error: 'ComposableRuleBased rules require a delegate sampler' ].
				         each key -> each value ]
		         as: OrderedCollection
]

{ #category : 'sampling' }
OTComposableRuleBasedSampler >> samplingIntentIn: aContext name: aString kind: aSpanKind attributes: someAttributes links: someLinks [

	rules do: [ :each |
			(self
				 matches: each key
				 in: aContext
				 name: aString
				 kind: aSpanKind
				 attributes: someAttributes
				 links: someLinks) ifTrue: [
					^ each value
						  samplingIntentIn: aContext
						  name: aString
						  kind: aSpanKind
						  attributes: someAttributes
						  links: someLinks ] ].
	^ OTSamplingIntent drop
]

{ #category : 'lifecycle' }
OTComposableRuleBasedSampler >> shutdown [

	| allShutdown |
	allShutdown := true.
	rules do: [ :each | allShutdown := each value shutdown & allShutdown ].
	^ allShutdown
]

{ #category : 'lifecycle' }
OTComposableRuleBasedSampler >> start [

	rules do: [ :each | each value start ]
]
