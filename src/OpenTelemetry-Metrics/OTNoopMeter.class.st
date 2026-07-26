"
A stateless meter that always creates no-op metric instruments.

It accepts meter and instrument creation requests without caching instruments or
remembering instrumentation scope details.
"
Class {
	#name : 'OTNoopMeter',
	#superclass : 'Object',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'accessing' }
OTNoopMeter class >> instance [

	^ OTClassStateStore valueAt: #otInstance forClass: self ifAbsentPut: [ self new ]
]

{ #category : 'private' }
OTNoopMeter >> collectMeasurementsFor: anOTMetricReader into: aCollection [

	self
]

{ #category : 'accessing' }
OTNoopMeter >> counterNamed: aString [

	^ OTNoopCounter instance
]

{ #category : 'accessing' }
OTNoopMeter >> counterNamed: aString unit: aUnitString description: aDescriptionString [

	^ OTNoopCounter instance
]

{ #category : 'accessing' }
OTNoopMeter >> counterNamed: aString unit: aUnitString description: aDescriptionString advice: aDictionary [

	^ OTNoopCounter instance
]

{ #category : 'testing' }
OTNoopMeter >> enablesMetricCollection [

	^ false
]

{ #category : 'testing' }
OTNoopMeter >> enablesSynchronousInstrument: anOTMetricInstrument [

	^ false
]

{ #category : 'testing' }
OTNoopMeter >> enablesSynchronousInstruments [

	^ false
]

{ #category : 'accessing' }
OTNoopMeter >> gaugeNamed: aString [

	^ OTNoopGauge instance
]

{ #category : 'accessing' }
OTNoopMeter >> gaugeNamed: aString unit: aUnitString description: aDescriptionString [

	^ OTNoopGauge instance
]

{ #category : 'accessing' }
OTNoopMeter >> gaugeNamed: aString unit: aUnitString description: aDescriptionString advice: aDictionary [

	^ OTNoopGauge instance
]

{ #category : 'accessing' }
OTNoopMeter >> histogramNamed: aString [

	^ OTNoopHistogram instance
]

{ #category : 'accessing' }
OTNoopMeter >> histogramNamed: aString unit: aUnitString description: aDescriptionString [

	^ OTNoopHistogram instance
]

{ #category : 'accessing' }
OTNoopMeter >> histogramNamed: aString unit: aUnitString description: aDescriptionString advice: aDictionary [

	^ OTNoopHistogram instance
]

{ #category : 'initialization' }
OTNoopMeter >> initialize [

	self
]

{ #category : 'accessing' }
OTNoopMeter >> instrumentationName [

	^ ''
]

{ #category : 'accessing' }
OTNoopMeter >> instrumentationScope [

	^ OTInstrumentationScope named: ''
]

{ #category : 'accessing' }
OTNoopMeter >> instrumentationVersion [

	^ ''
]

{ #category : 'testing' }
OTNoopMeter >> isNoop [

	^ true
]

{ #category : 'accessing' }
OTNoopMeter >> observableCounterNamed: aString [

	^ OTNoopObservableCounter instance
]

{ #category : 'accessing' }
OTNoopMeter >> observableCounterNamed: aString callbacks: someCallbacks [

	^ OTNoopObservableCounter instance
]

{ #category : 'accessing' }
OTNoopMeter >> observableCounterNamed: aString callbacks: someCallbacks unit: aUnitString description: aDescriptionString advice: aDictionary [

	^ OTNoopObservableCounter instance
]

{ #category : 'accessing' }
OTNoopMeter >> observableGaugeNamed: aString [

	^ OTNoopObservableGauge instance
]

{ #category : 'accessing' }
OTNoopMeter >> observableGaugeNamed: aString callbacks: someCallbacks [

	^ OTNoopObservableGauge instance
]

{ #category : 'accessing' }
OTNoopMeter >> observableGaugeNamed: aString callbacks: someCallbacks unit: aUnitString description: aDescriptionString advice: aDictionary [

	^ OTNoopObservableGauge instance
]

{ #category : 'accessing' }
OTNoopMeter >> observableUpDownCounterNamed: aString [

	^ OTNoopObservableUpDownCounter instance
]

{ #category : 'accessing' }
OTNoopMeter >> observableUpDownCounterNamed: aString callbacks: someCallbacks [

	^ OTNoopObservableUpDownCounter instance
]

{ #category : 'accessing' }
OTNoopMeter >> observableUpDownCounterNamed: aString callbacks: someCallbacks unit: aUnitString description: aDescriptionString advice: aDictionary [

	^ OTNoopObservableUpDownCounter instance
]

{ #category : 'accessing' }
OTNoopMeter >> provider [

	^ nil
]

{ #category : 'accessing' }
OTNoopMeter >> registeredMetricInstruments [

	^ #(  )
]

{ #category : 'accessing' }
OTNoopMeter >> resource [

	^ OTResource empty
]

{ #category : 'accessing' }
OTNoopMeter >> schemaUrl [

	^ ''
]

{ #category : 'accessing' }
OTNoopMeter >> scopeAttributes [

	^ #(  )
]

{ #category : 'accessing' }
OTNoopMeter >> upDownCounterNamed: aString [

	^ OTNoopUpDownCounter instance
]

{ #category : 'accessing' }
OTNoopMeter >> upDownCounterNamed: aString unit: aUnitString description: aDescriptionString [

	^ OTNoopUpDownCounter instance
]

{ #category : 'accessing' }
OTNoopMeter >> upDownCounterNamed: aString unit: aUnitString description: aDescriptionString advice: aDictionary [

	^ OTNoopUpDownCounter instance
]
