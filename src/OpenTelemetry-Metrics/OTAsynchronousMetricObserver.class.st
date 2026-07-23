Class {
	#name : 'OTAsynchronousMetricObserver',
	#superclass : 'Object',
	#instVars : [
		'instrument',
		'measurements'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTAsynchronousMetricObserver class >> instrument: anOTMetricInstrument measurements: aCollection [

	| observer |
	observer := self new.
	observer
		instrument: anOTMetricInstrument;
		measurements: aCollection.
	^ observer
]

{ #category : 'accessing' }
OTAsynchronousMetricObserver >> instrument [

	^ instrument
]

{ #category : 'accessing' }
OTAsynchronousMetricObserver >> instrument: anOTMetricInstrument [

	instrument := anOTMetricInstrument
]

{ #category : 'accessing' }
OTAsynchronousMetricObserver >> measurements [

	^ measurements ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
OTAsynchronousMetricObserver >> measurements: aCollection [

	measurements := aCollection ifNil: [ OrderedCollection new ] ifNotNil: [ aCollection ]
]

{ #category : 'recording' }
OTAsynchronousMetricObserver >> observe: aNumber [

	^ self observe: aNumber attributes: #(  )
]

{ #category : 'recording' }
OTAsynchronousMetricObserver >> observe: aNumber attributes: aCollection [

	| measurement provider |
	provider := self instrument meter ifNil: [ nil ] ifNotNil: [ :aMeter | aMeter provider ].
	measurement := provider
		               ifNil: [ OTMetricMeasurement instrument: self instrument value: aNumber attributes: aCollection ]
		               ifNotNil: [ provider measurementFor: self instrument value: aNumber attributes: aCollection ].
	self measurements add: measurement.
	^ aNumber
]
