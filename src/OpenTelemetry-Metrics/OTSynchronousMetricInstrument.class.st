"
Abstract no-op synchronous metric instrument.
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
