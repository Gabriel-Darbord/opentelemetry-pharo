"
A backend-agnostic entry point to the metrics API.

The current implementation is a spec-shaped no-op foundation.
"
Class {
	#name : 'OTMeterProvider',
	#superclass : 'Object',
	#classVars : [
		'Current'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'accessing' }
OTMeterProvider class >> current [

	^ Current ifNil: [ Current := self new ]
]

{ #category : 'accessing' }
OTMeterProvider class >> current: anOTMeterProvider [

	Current := anOTMeterProvider
]

{ #category : 'class initialization' }
OTMeterProvider class >> reset [

	Current := nil
]

{ #category : 'accessing' }
OTMeterProvider >> meterNamed: aString [

	^ self
		meterNamed: aString
		version: ''
		schemaUrl: ''
		attributes: #()
]

{ #category : 'accessing' }
OTMeterProvider >> meterNamed: aString version: aVersionString schemaUrl: aSchemaUrlString attributes: aCollection [

	^ OTMeter noop
]
