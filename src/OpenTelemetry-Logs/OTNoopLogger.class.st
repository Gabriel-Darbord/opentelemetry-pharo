"
A logger that accepts the full logs API surface but never emits records and is never enabled.

It is safe for concurrent enabled checks and emit calls because it holds no operational state.
"
Class {
	#name : 'OTNoopLogger',
	#superclass : 'Object',
	#category : 'OpenTelemetry-Logs',
	#package : 'OpenTelemetry-Logs'
}

{ #category : 'adapting' }
OTNoopLogger >> asBeaconSignalLogger [

	^ OTBeaconSignalLogger forLogger: self
]

{ #category : 'adapting' }
OTNoopLogger >> asTinyLoggerBridge [

	^ OTTinyLoggerBridge forLogger: self
]

{ #category : 'logging' }
OTNoopLogger >> emitBody: anObject [

	^ false
]

{ #category : 'logging' }
OTNoopLogger >> emitTimestamp: aTimestamp observedTimestamp: anObservedTimestamp in: anOTContext severityNumber: aSeverityNumber severityText: aSeverityText body: aBody attributes: someAttributes eventName: anEventName exception: anException [

	^ false
]

{ #category : 'testing' }
OTNoopLogger >> enabled [

	^ false
]

{ #category : 'testing' }
OTNoopLogger >> enabledIn: anOTContext severityNumber: aSeverityNumber eventName: aString [

	^ false
]

{ #category : 'accessing' }
OTNoopLogger >> instrumentationName [

	^ ''
]

{ #category : 'accessing' }
OTNoopLogger >> instrumentationScope [

	^ OTInstrumentationScope named: ''
]

{ #category : 'accessing' }
OTNoopLogger >> instrumentationVersion [

	^ ''
]

{ #category : 'logging' }
OTNoopLogger >> logRecordBuilder [

	^ OTLogRecordBuilder forLogger: self
]

{ #category : 'accessing' }
OTNoopLogger >> provider [

	^ nil
]

{ #category : 'accessing' }
OTNoopLogger >> schemaUrl [

	^ ''
]

{ #category : 'accessing' }
OTNoopLogger >> scopeAttributes [

	^ #(  )
]
