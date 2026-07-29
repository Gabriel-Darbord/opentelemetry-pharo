"
Abstract synchronous metric instrument.

Concrete subclasses accept direct recordings and can also create bound
instruments for pre-bound attributes.
"
Class {
	#name : 'OTSynchronousMetricInstrument',
	#superclass : 'OTMetricInstrument',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTSynchronousMetricInstrument class >> noop [

	self subclassResponsibility
]

{ #category : 'binding' }
OTSynchronousMetricInstrument >> bind: aCollection [

	meter ifNil: [ ^ self ].
	^ OTBoundMetricInstrument instrument: self attributes: aCollection
]

{ #category : 'testing' }
OTSynchronousMetricInstrument >> enabled [

	^ meter notNil and: [ meter enablesSynchronousInstrument: self ]
]

{ #category : 'recording' }
OTSynchronousMetricInstrument >> recordMeasurementValue: aNumber attributes: aCollection [

	| value |
	meter ifNil: [ ^ self ].
	value := self recordableMeasurementValueFrom: aNumber.
	value ifNil: [ ^ self ].
	meter provider ifNotNil: [ meter provider recordMeasurementFor: self value: value attributes: aCollection ].
	self
]
