"
A text-map propagator that composes multiple propagators in order.
"
Class {
	#name : 'OTCompositeTextMapPropagator',
	#superclass : 'OTTextMapPropagator',
	#instVars : [
		'propagators'
	],
	#category : 'OpenTelemetry-Instrumentation',
	#package : 'OpenTelemetry-Instrumentation'
}

{ #category : 'instance creation' }
OTCompositeTextMapPropagator class >> withAll: aCollection [

	| normalizedPropagators |
	normalizedPropagators := aCollection
		ifNil: [ #() ]
		ifNotNil: [ aCollection asArray ].
	normalizedPropagators isEmpty ifTrue: [ ^ OTTextMapPropagator noop ].
	normalizedPropagators size = 1 ifTrue: [ ^ normalizedPropagators first ].
	^ self new propagators: normalizedPropagators
]

{ #category : 'extracting' }
OTCompositeTextMapPropagator >> extract: aContext from: aCarrier getter: aGetter [

	| context |
	context := aContext ifNil: [ OTContext new ] ifNotNil: [ aContext ].
	aGetter ifNil: [ ^ context ].
	propagators do: [ :eachPropagator |
		context := eachPropagator extract: context from: aCarrier getter: aGetter ].
	^ context
]

{ #category : 'accessing' }
OTCompositeTextMapPropagator >> fields [

	| orderedFields seen |
	orderedFields := OrderedCollection new.
	seen := Set new.
	propagators do: [ :eachPropagator |
		eachPropagator fields do: [ :eachField |
			(seen includes: eachField) ifFalse: [
				seen add: eachField.
				orderedFields add: eachField ] ] ].
	^ orderedFields asArray
]

{ #category : 'injecting' }
OTCompositeTextMapPropagator >> inject: aContext into: aCarrier setter: aSetter [

	(aContext isNil or: [ aSetter isNil ]) ifTrue: [ ^ self ].
	propagators do: [ :eachPropagator |
		eachPropagator inject: aContext into: aCarrier setter: aSetter ].
	^ self
]

{ #category : 'private' }
OTCompositeTextMapPropagator >> propagators: aCollection [

	propagators := aCollection
]
