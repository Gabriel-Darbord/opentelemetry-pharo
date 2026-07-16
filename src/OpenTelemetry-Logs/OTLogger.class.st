"
A backend-agnostic logger responsible for one instrumentation scope.
"
Class {
	#name : 'OTLogger',
	#superclass : 'Object',
	#instVars : [
		'provider',
		'instrumentationScope'
	],
	#category : 'OpenTelemetry-Logs',
	#package : 'OpenTelemetry-Logs'
}

{ #category : 'instance creation' }
OTLogger class >> forProvider: anOTLoggerProvider instrumentationScope: anInstrumentationScope [

	| logger |
	logger := self new.
	logger
		provider: anOTLoggerProvider;
		instrumentationScope: anInstrumentationScope.
	^ logger
]

{ #category : 'adapting' }
OTLogger >> asTinyLoggerBridge [

	^ OTTinyLoggerBridge forLogger: self
]

{ #category : 'logging' }
OTLogger >> emitBody: anObject [

	^ self
		emitTimestamp: nil
		observedTimestamp: nil
		in: nil
		severityNumber: OTSeverity undefined
		severityText: nil
		body: anObject
		attributes: #()
		eventName: nil
		exception: nil
]

{ #category : 'logging' }
OTLogger >> emitTimestamp: aTimestamp observedTimestamp: anObservedTimestamp in: anOTContext severityNumber: aSeverityNumber severityText: aSeverityText body: aBody attributes: someAttributes eventName: anEventName exception: anException [

	^ provider
		ifNil: [ false ]
		ifNotNil: [
			provider
				emitForLogger: self
				timestamp: aTimestamp
				observedTimestamp: anObservedTimestamp
				context: anOTContext
				severityNumber: aSeverityNumber
				severityText: aSeverityText
				body: aBody
				attributes: someAttributes
				eventName: anEventName
				exception: anException ]
]

{ #category : 'testing' }
OTLogger >> enabled [

	^ self enabledIn: nil severityNumber: OTSeverity undefined eventName: nil
]

{ #category : 'testing' }
OTLogger >> enabledIn: anOTContext severityNumber: aSeverityNumber eventName: aString [

	^ provider
		ifNil: [ false ]
		ifNotNil: [
			provider
				loggerEnabled: self
				inContext: anOTContext
				severityNumber: aSeverityNumber
				eventName: aString ]
]

{ #category : 'accessing' }
OTLogger >> instrumentationName [

	^ self instrumentationScope name
]

{ #category : 'accessing' }
OTLogger >> instrumentationScope [

	^ instrumentationScope ifNil: [ OTInstrumentationScope named: '' ]
]

{ #category : 'accessing' }
OTLogger >> instrumentationScope: anInstrumentationScope [

	instrumentationScope := anInstrumentationScope
		ifNil: [ OTInstrumentationScope named: '' ]
		ifNotNil: [ anInstrumentationScope ].
	^ instrumentationScope
]

{ #category : 'accessing' }
OTLogger >> instrumentationVersion [

	^ self instrumentationScope version
]

{ #category : 'logging' }
OTLogger >> logRecordBuilder [

	^ OTLogRecordBuilder forLogger: self
]

{ #category : 'accessing' }
OTLogger >> provider [

	^ provider
]

{ #category : 'accessing' }
OTLogger >> provider: anOTLoggerProvider [

	provider := anOTLoggerProvider
]

{ #category : 'accessing' }
OTLogger >> schemaUrl [

	^ self instrumentationScope schemaUrl
]

{ #category : 'accessing' }
OTLogger >> scopeAttributes [

	^ self instrumentationScope allAttributes
]
