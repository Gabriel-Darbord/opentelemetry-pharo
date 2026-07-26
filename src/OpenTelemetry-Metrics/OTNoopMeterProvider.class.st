"
A meter provider that always returns stateless no-op meters.

It accepts the metrics API surface without retaining configuration, readers,
views, or operational lifecycle state.
"
Class {
	#name : 'OTNoopMeterProvider',
	#superclass : 'Object',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'accessing' }
OTNoopMeterProvider class >> instance [

	^ OTClassStateStore valueAt: #otInstance forClass: self ifAbsentPut: [ self new ]
]

{ #category : 'accessing' }
OTNoopMeterProvider >> addMetricReader: anOTMetricReader [

	^ anOTMetricReader
]

{ #category : 'configuration' }
OTNoopMeterProvider >> addView: anOTMetricView [

	^ anOTMetricView
]

{ #category : 'collecting' }
OTNoopMeterProvider >> collectMeasurementsFor: anOTMetricReader [

	^ #(  )
]

{ #category : 'accessing' }
OTNoopMeterProvider >> exemplarFilter [

	^ OTMetricExemplarFilter traceBased
]

{ #category : 'accessing' }
OTNoopMeterProvider >> exemplarFilter: anOTMetricExemplarFilter [

	^ self exemplarFilter
]

{ #category : 'lifecycle' }
OTNoopMeterProvider >> forceFlush [

	^ true
]

{ #category : 'testing' }
OTNoopMeterProvider >> isShutdown [

	^ false
]

{ #category : 'configuration' }
OTNoopMeterProvider >> matchingViewsFor: anOTMetricInstrument [

	^ #(  )
]

{ #category : 'recording' }
OTNoopMeterProvider >> measurementFor: anOTMetricInstrument value: aNumber attributes: aCollection [

	^ nil
]

{ #category : 'accessing' }
OTNoopMeterProvider >> measurements [

	^ #(  )
]

{ #category : 'configuration' }
OTNoopMeterProvider >> meterConfigFor: anOTInstrumentationScope [

	^ OTMeterConfig enabled: false
]

{ #category : 'configuration' }
OTNoopMeterProvider >> meterConfigurator [

	^ [ :scope | nil ]
]

{ #category : 'configuration' }
OTNoopMeterProvider >> meterConfigurator: aBlockOrNil [

	^ self meterConfigurator
]

{ #category : 'accessing' }
OTNoopMeterProvider >> meterNamed: aString [

	^ self
		  meterNamed: aString
		  version: ''
		  schemaUrl: ''
		  attributes: #(  )
]

{ #category : 'accessing' }
OTNoopMeterProvider >> meterNamed: aString version: aVersionString schemaUrl: aSchemaUrlString attributes: aCollection [

	^ OTNoopMeter instance
]

{ #category : 'accessing' }
OTNoopMeterProvider >> meters [

	^ #(  )
]

{ #category : 'accessing' }
OTNoopMeterProvider >> metricReaders [

	^ #(  )
]

{ #category : 'accessing' }
OTNoopMeterProvider >> metricReaders: aCollection [

	^ self metricReaders
]

{ #category : 'accessing' }
OTNoopMeterProvider >> resource [

	^ OTResource empty
]

{ #category : 'accessing' }
OTNoopMeterProvider >> resource: anOTResource [

	^ self resource
]

{ #category : 'lifecycle' }
OTNoopMeterProvider >> shutdown [

	^ true
]

{ #category : 'accessing' }
OTNoopMeterProvider >> views [

	^ #(  )
]

{ #category : 'accessing' }
OTNoopMeterProvider >> views: aCollection [

	^ self views
]
