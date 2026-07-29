"
Abstract asynchronous metric instrument.

Concrete subclasses manage callback registration and turn callback observations
into measurements during collection.
"
Class {
	#name : 'OTAsynchronousMetricInstrument',
	#superclass : 'OTMetricInstrument',
	#instVars : [
		'callbacks'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTAsynchronousMetricInstrument class >> forMeter: anOTMeter name: aString callbacks: someCallbacks unit: aUnitString description: aDescriptionString advice: aDictionary [

	| instrument |
	instrument := self
		              forMeter: anOTMeter
		              name: aString
		              unit: aUnitString
		              description: aDescriptionString
		              advice: aDictionary.
	instrument callbacks: someCallbacks.
	^ instrument
]

{ #category : 'instance creation' }
OTAsynchronousMetricInstrument class >> noop [

	self subclassResponsibility
]

{ #category : 'accessing' }
OTAsynchronousMetricInstrument >> callbacks [

	^ callbacks ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
OTAsynchronousMetricInstrument >> callbacks: someCallbacks [

	callbacks := someCallbacks ifNil: [ #(  ) ] ifNotNil: [ someCallbacks asArray ]
]

{ #category : 'collecting' }
OTAsynchronousMetricInstrument >> collectFor: anOTMetricReader into: aCollection [

	self collectsMeasurements ifFalse: [ ^ self ].
	self callbacks do: [ :each | anOTMetricReader collectAsynchronousCallback: each for: self into: aCollection ]
]

{ #category : 'collecting' }
OTAsynchronousMetricInstrument >> collectsMeasurements [

	^ meter notNil and: [ meter enablesMetricCollection ]
]

{ #category : 'collecting' }
OTAsynchronousMetricInstrument >> invokeCallback: aBlock with: anOTAsynchronousMetricObserver [

	aBlock numArgs = 0
		ifTrue: [ aBlock value ]
		ifFalse: [ aBlock value: anOTAsynchronousMetricObserver ]
]

{ #category : 'collecting' }
OTAsynchronousMetricInstrument >> newObserverOn: aCollection [

	^ OTAsynchronousMetricObserver instrument: self measurements: aCollection
]

{ #category : 'recording' }
OTAsynchronousMetricInstrument >> observe: aNumber [

	^ self observe: aNumber attributes: #(  )
]

{ #category : 'recording' }
OTAsynchronousMetricInstrument >> observe: aNumber attributes: aCollection [

	self
]

{ #category : 'collecting' }
OTAsynchronousMetricInstrument >> startTimestampForPreviousCollection: aDateAndTime temporality: aTemporalitySymbol [

	^ aTemporalitySymbol = #delta
		  ifTrue: [ aDateAndTime ifNil: [ self creationTimestamp ] ]
		  ifFalse: [ self creationTimestamp ]
]
