"
Abstract no-op asynchronous metric instrument.
"
Class {
	#name : 'OTAsynchronousMetricInstrument',
	#superclass : 'OTMetricInstrument',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTAsynchronousMetricInstrument class >> noop [

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

{ #category : 'recording' }
OTAsynchronousMetricInstrument >> observe: aNumber [

	^ self observe: aNumber attributes: #()
]

{ #category : 'recording' }
OTAsynchronousMetricInstrument >> observe: aNumber attributes: aCollection [

	self
]
