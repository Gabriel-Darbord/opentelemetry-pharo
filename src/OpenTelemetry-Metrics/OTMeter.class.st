"
A backend-agnostic Meter responsible for creating metric instruments.

The current implementation is a spec-shaped no-op meter.
"
Class {
	#name : 'OTMeter',
	#superclass : 'Object',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTMeter class >> noop [

	^ OTClassStateStore
		valueAt: #otNoopMeter
		forClass: self
		ifAbsent: [
			| meter |
			meter := self new.
			OTClassStateStore valueAt: #otNoopMeter forClass: self put: meter.
			meter ]
]

{ #category : 'accessing' }
OTMeter >> counterNamed: aString [

	^ self counterNamed: aString unit: '' description: '' advice: Dictionary new
]

{ #category : 'accessing' }
OTMeter >> counterNamed: aString unit: aUnitString description: aDescriptionString [

	^ self
		counterNamed: aString
		unit: aUnitString
		description: aDescriptionString
		advice: Dictionary new
]

{ #category : 'accessing' }
OTMeter >> counterNamed: aString unit: aUnitString description: aDescriptionString advice: aDictionary [

	^ OTCounter noop
]

{ #category : 'accessing' }
OTMeter >> gaugeNamed: aString [

	^ self gaugeNamed: aString unit: '' description: '' advice: Dictionary new
]

{ #category : 'accessing' }
OTMeter >> gaugeNamed: aString unit: aUnitString description: aDescriptionString [

	^ self
		gaugeNamed: aString
		unit: aUnitString
		description: aDescriptionString
		advice: Dictionary new
]

{ #category : 'accessing' }
OTMeter >> gaugeNamed: aString unit: aUnitString description: aDescriptionString advice: aDictionary [

	^ OTGauge noop
]

{ #category : 'accessing' }
OTMeter >> histogramNamed: aString [

	^ self histogramNamed: aString unit: '' description: '' advice: Dictionary new
]

{ #category : 'accessing' }
OTMeter >> histogramNamed: aString unit: aUnitString description: aDescriptionString [

	^ self
		histogramNamed: aString
		unit: aUnitString
		description: aDescriptionString
		advice: Dictionary new
]

{ #category : 'accessing' }
OTMeter >> histogramNamed: aString unit: aUnitString description: aDescriptionString advice: aDictionary [

	^ OTHistogram noop
]

{ #category : 'accessing' }
OTMeter >> observableCounterNamed: aString [

	^ self
		observableCounterNamed: aString
		callbacks: #()
		unit: ''
		description: ''
		advice: Dictionary new
]

{ #category : 'accessing' }
OTMeter >> observableCounterNamed: aString callbacks: someCallbacks [

	^ self
		observableCounterNamed: aString
		callbacks: someCallbacks
		unit: ''
		description: ''
		advice: Dictionary new
]

{ #category : 'accessing' }
OTMeter >> observableCounterNamed: aString callbacks: someCallbacks unit: aUnitString description: aDescriptionString advice: aDictionary [

	^ OTObservableCounter noop
]

{ #category : 'accessing' }
OTMeter >> observableGaugeNamed: aString [

	^ self
		observableGaugeNamed: aString
		callbacks: #()
		unit: ''
		description: ''
		advice: Dictionary new
]

{ #category : 'accessing' }
OTMeter >> observableGaugeNamed: aString callbacks: someCallbacks [

	^ self
		observableGaugeNamed: aString
		callbacks: someCallbacks
		unit: ''
		description: ''
		advice: Dictionary new
]

{ #category : 'accessing' }
OTMeter >> observableGaugeNamed: aString callbacks: someCallbacks unit: aUnitString description: aDescriptionString advice: aDictionary [

	^ OTObservableGauge noop
]

{ #category : 'accessing' }
OTMeter >> observableUpDownCounterNamed: aString [

	^ self
		observableUpDownCounterNamed: aString
		callbacks: #()
		unit: ''
		description: ''
		advice: Dictionary new
]

{ #category : 'accessing' }
OTMeter >> observableUpDownCounterNamed: aString callbacks: someCallbacks [

	^ self
		observableUpDownCounterNamed: aString
		callbacks: someCallbacks
		unit: ''
		description: ''
		advice: Dictionary new
]

{ #category : 'accessing' }
OTMeter >> observableUpDownCounterNamed: aString callbacks: someCallbacks unit: aUnitString description: aDescriptionString advice: aDictionary [

	^ OTObservableUpDownCounter noop
]

{ #category : 'accessing' }
OTMeter >> upDownCounterNamed: aString [

	^ self
		upDownCounterNamed: aString
		unit: ''
		description: ''
		advice: Dictionary new
]

{ #category : 'accessing' }
OTMeter >> upDownCounterNamed: aString unit: aUnitString description: aDescriptionString [

	^ self
		upDownCounterNamed: aString
		unit: aUnitString
		description: aDescriptionString
		advice: Dictionary new
]

{ #category : 'accessing' }
OTMeter >> upDownCounterNamed: aString unit: aUnitString description: aDescriptionString advice: aDictionary [

	^ OTUpDownCounter noop
]
