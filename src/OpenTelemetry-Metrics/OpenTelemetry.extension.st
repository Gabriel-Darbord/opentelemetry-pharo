Extension { #name : 'OpenTelemetry' }

{ #category : '*OpenTelemetry-Metrics' }
OpenTelemetry class >> meterNamed: aString [

	^ self meterProvider meterNamed: aString
]

{ #category : '*OpenTelemetry-Metrics' }
OpenTelemetry class >> meterNamed: aString version: aVersionString schemaUrl: aSchemaUrlString attributes: aCollection [

	^ self meterProvider
		  meterNamed: aString
		  version: aVersionString
		  schemaUrl: aSchemaUrlString
		  attributes: aCollection
]

{ #category : '*OpenTelemetry-Metrics' }
OpenTelemetry class >> meterProvider [

	^ OTMeterProvider current
]

{ #category : '*OpenTelemetry-Metrics' }
OpenTelemetry class >> meterProvider: anOTMeterProvider [

	OTMeterProvider current: anOTMeterProvider.
	^ anOTMeterProvider
]
