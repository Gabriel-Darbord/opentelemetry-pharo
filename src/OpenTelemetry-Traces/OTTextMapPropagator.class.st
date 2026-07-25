"
Abstract text-map propagator entry point with a configurable global default.
"
Class {
	#name : 'OTTextMapPropagator',
	#superclass : 'Object',
	#classVars : [
		'Current'
	],
	#category : 'OpenTelemetry-Traces',
	#package : 'OpenTelemetry-Traces'
}

{ #category : 'instance creation' }
OTTextMapPropagator class >> compositeAll: aCollection [

	^ OTCompositeTextMapPropagator withAll: aCollection
]

{ #category : 'accessing' }
OTTextMapPropagator class >> current [

	^ OTClassStateStore currentValueForClass: self ifAbsentPut: [ OTNoopTextMapPropagator new ]
]

{ #category : 'accessing' }
OTTextMapPropagator class >> current: aPropagator [

	^ OTClassStateStore
		  valueAt: #otCurrent
		  forClass: self
		  putOrRemoveIfNil: aPropagator
]

{ #category : 'accessing' }
OTTextMapPropagator class >> currentOrNil [

	^ OTClassStateStore currentValueForClass: self ifAbsent: [ nil ]
]

{ #category : 'instance creation' }
OTTextMapPropagator class >> noop [

	^ OTNoopTextMapPropagator new
]

{ #category : 'class initialization' }
OTTextMapPropagator class >> reset [

	OTClassStateStore removeCurrentValueForClass: self ifAbsent: [ ]
]

{ #category : 'accessing' }
OTTextMapPropagator >> componentPropagators [

	^ { self }
]

{ #category : 'extracting' }
OTTextMapPropagator >> extract: aContext from: aCarrier [

	^ self extract: aContext from: aCarrier getter: OTDictionaryTextMapGetter current
]

{ #category : 'extracting' }
OTTextMapPropagator >> extract: aContext from: aCarrier getter: aGetter [

	^ aContext ifNil: [ OTContext new ] ifNotNil: [ aContext ]
]

{ #category : 'accessing' }
OTTextMapPropagator >> fields [

	^ #(  )
]

{ #category : 'injecting' }
OTTextMapPropagator >> inject: aContext into: aCarrier [

	^ self inject: aContext into: aCarrier setter: OTDictionaryTextMapSetter current
]

{ #category : 'injecting' }
OTTextMapPropagator >> inject: aContext into: aCarrier setter: aSetter [

	^ self
]
