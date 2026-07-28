"
I am the observer object passed to asynchronous metric callbacks.
Callbacks record observations through me and I accumulate the resulting measurements.
I also keep one callback timestamp so every observation from a single callback shares the same instant.
"
Class {
	#name : 'OTAsynchronousMetricObserver',
	#superclass : 'Object',
	#instVars : [
		'instrument',
		'measurements',
		'timestamp'
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
		measurements: aCollection;
		timestamp: DateAndTime now asUTC.
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

	| measurement provider value |
	value := self instrument recordableMeasurementValueFrom: aNumber.
	value ifNil: [ ^ aNumber ].
	provider := self instrument meter ifNotNil: [ :aMeter | aMeter provider ].
	measurement := (provider
		                ifNil: [ OTMetricMeasurement instrument: self instrument value: value attributes: aCollection ]
		                ifNotNil: [ provider measurementFor: self instrument value: value attributes: aCollection ])
		               timestamp: self timestamp;
		               yourself.
	self measurements add: measurement.
	^ aNumber
]

{ #category : 'accessing' }
OTAsynchronousMetricObserver >> timestamp [

	^ timestamp
]

{ #category : 'accessing' }
OTAsynchronousMetricObserver >> timestamp: aDateAndTime [

	timestamp := aDateAndTime
]
