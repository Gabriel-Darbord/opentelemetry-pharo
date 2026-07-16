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

	^ OTClassStateStore
		valueAt: #otNoopMetricInstrument
		forClass: self
		ifAbsent: [
			| instrument |
			instrument := self new.
			OTClassStateStore
				valueAt: #otNoopMetricInstrument
				forClass: self
				put: instrument.
			instrument ]
]

{ #category : 'binding' }
OTSynchronousMetricInstrument >> bind: aCollection [

	meter ifNil: [ ^ self ].
	^ OTBoundMetricInstrument instrument: self attributes: aCollection
]

{ #category : 'testing' }
OTSynchronousMetricInstrument >> enabled [

	^ meter notNil and: [ meter enablesSynchronousInstruments ]
]
