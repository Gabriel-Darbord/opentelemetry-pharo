"
Abstract no-op asynchronous metric instrument.
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

{ #category : 'accessing' }
OTAsynchronousMetricInstrument >> callbacks [

	^ callbacks ifNil: [ #() ]
]

{ #category : 'accessing' }
OTAsynchronousMetricInstrument >> callbacks: someCallbacks [

	callbacks := someCallbacks ifNil: [ #() ] ifNotNil: [ someCallbacks asArray ]
]

{ #category : 'recording' }
OTAsynchronousMetricInstrument >> observe: aNumber [

	^ self observe: aNumber attributes: #()
]

{ #category : 'recording' }
OTAsynchronousMetricInstrument >> observe: aNumber attributes: aCollection [

	self
]
