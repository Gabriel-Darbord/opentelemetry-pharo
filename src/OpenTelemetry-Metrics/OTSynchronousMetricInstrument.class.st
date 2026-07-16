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
