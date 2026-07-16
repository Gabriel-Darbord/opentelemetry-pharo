Extension { #name : 'OpenTelemetry' }

{ #category : '*OpenTelemetry-Logs' }
OpenTelemetry class >> loggerNamed: aString [

	^ self loggerProvider loggerNamed: aString
]

{ #category : '*OpenTelemetry-Logs' }
OpenTelemetry class >> loggerNamed: aString version: aVersionString schemaUrl: aSchemaUrlString attributes: aCollection [

	^ self loggerProvider
		loggerNamed: aString
		version: aVersionString
		schemaUrl: aSchemaUrlString
		attributes: aCollection
]

{ #category : '*OpenTelemetry-Logs' }
OpenTelemetry class >> loggerProvider [

	^ OTLoggerProvider current
]

{ #category : '*OpenTelemetry-Logs' }
OpenTelemetry class >> loggerProvider: anOTLoggerProvider [

	OTLoggerProvider current: anOTLoggerProvider.
	^ anOTLoggerProvider
]
