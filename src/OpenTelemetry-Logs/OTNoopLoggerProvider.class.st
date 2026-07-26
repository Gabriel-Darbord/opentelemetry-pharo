"
A logger provider that always returns no-op loggers and ignores SDK configuration state.

It accepts the full logs API surface without validating arguments, recording telemetry, or retaining operational state.
"
Class {
	#name : 'OTNoopLoggerProvider',
	#superclass : 'Object',
	#category : 'OpenTelemetry-Logs',
	#package : 'OpenTelemetry-Logs'
}

{ #category : 'accessing' }
OTNoopLoggerProvider >> addLogRecordProcessor: anOTLogRecordProcessor [

	^ anOTLogRecordProcessor
]

{ #category : 'processing' }
OTNoopLoggerProvider >> forceFlush [

	^ true
]

{ #category : 'initialization' }
OTNoopLoggerProvider >> initialize [

	self
]

{ #category : 'testing' }
OTNoopLoggerProvider >> isShutdown [

	^ false
]

{ #category : 'accessing' }
OTNoopLoggerProvider >> logRecordLimits [

	^ OTLogRecordLimits default copy
]

{ #category : 'accessing' }
OTNoopLoggerProvider >> logRecordLimits: anOTLogRecordLimits [

	^ self logRecordLimits
]

{ #category : 'accessing' }
OTNoopLoggerProvider >> logRecordProcessors [

	^ #(  )
]

{ #category : 'accessing' }
OTNoopLoggerProvider >> logRecordProcessors: aCollection [

	^ self logRecordProcessors
]

{ #category : 'accessing' }
OTNoopLoggerProvider >> loggerConfigurator [

	^ [ :scope | nil ]
]

{ #category : 'accessing' }
OTNoopLoggerProvider >> loggerConfigurator: aBlock [

	^ self loggerConfigurator
]

{ #category : 'logging' }
OTNoopLoggerProvider >> loggerNamed: aString [

	^ self
		  loggerNamed: aString
		  version: ''
		  schemaUrl: ''
		  attributes: #(  )
]

{ #category : 'logging' }
OTNoopLoggerProvider >> loggerNamed: aString version: aVersionString schemaUrl: aSchemaUrlString attributes: aCollection [

	^ OTNoopLogger new
]

{ #category : 'accessing' }
OTNoopLoggerProvider >> resource [

	^ OTResource empty
]

{ #category : 'accessing' }
OTNoopLoggerProvider >> resource: anOTResource [

	^ self resource
]

{ #category : 'processing' }
OTNoopLoggerProvider >> shutdown [

	^ true
]
