"
A backend-agnostic entry point to the metrics API.

The current implementation is a spec-shaped no-op foundation.
"
Class {
	#name : 'OTMeterProvider',
	#superclass : 'Object',
	#instVars : [
		'meters',
		'shutdown',
		'meterConfigurator'
	],
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

{ #category : 'private - logging' }
OTMeterProvider class >> defaultMeterNameWarningSink [

	^ OTDiagnosticLogger defaultWarningSink
]

{ #category : 'private' }
OTMeterProvider class >> meterNameWarningSink [

	^ OTClassStateStore
		valueAt: #otMeterNameWarningSink
		forClass: self
		ifAbsent: [ self defaultMeterNameWarningSink ]
]

{ #category : 'private' }
OTMeterProvider class >> meterNameWarningSink: aBlock [

	aBlock
		ifNil: [
			OTClassStateStore
				removeValueAt: #otMeterNameWarningSink
				forClass: self
				ifAbsent: [  ] ]
		ifNotNil: [
			OTClassStateStore
				valueAt: #otMeterNameWarningSink
				forClass: self
				put: aBlock ].
	^ self meterNameWarningSink
]

{ #category : 'private - logging' }
OTMeterProvider class >> noteInvalidMeterName: aValue [

	self meterNameWarningSink value:
		'OpenTelemetry meter name was invalid and has been normalized to an empty string: '
			, (aValue ifNil: [ 'nil' ] ifNotNil: [ aValue printString ])
]

{ #category : 'private' }
OTMeterProvider class >> normalizedMeterNameFrom: aValue [

	| meterName |
	aValue ifNil: [
		self noteInvalidMeterName: aValue.
		^ '' ].
	meterName := aValue asString.
	meterName trimBoth isEmpty ifTrue: [
		self noteInvalidMeterName: aValue.
		^ '' ].
	^ meterName
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

	| scope |
	scope := OTInstrumentationScope
		named: (self class normalizedMeterNameFrom: aString)
		version: (aVersionString ifNil: [ '' ] ifNotNil: [ aVersionString asString ])
		schemaUrl: (aSchemaUrlString ifNil: [ '' ] ifNotNil: [ aSchemaUrlString asString ])
		attributes: aCollection.
	self isShutdown ifTrue: [ ^ OTMeter forProvider: nil instrumentationScope: scope ].
	^ self meters
		at: scope
		ifAbsentPut: [ OTMeter forProvider: self instrumentationScope: scope ]
]

{ #category : 'lifecycle' }
OTMeterProvider >> forceFlush [

	^ true
]

{ #category : 'initialization' }
OTMeterProvider >> initialize [

	super initialize.
	meters := OrderedDictionary new.
	shutdown := false.
	meterConfigurator := nil
]

{ #category : 'testing' }
OTMeterProvider >> isShutdown [

	^ shutdown
]

{ #category : 'accessing' }
OTMeterProvider >> meters [

	^ meters ifNil: [ meters := OrderedDictionary new ]
]

{ #category : 'configuration' }
OTMeterProvider >> meterConfigFor: anOTInstrumentationScope [

	| configured |
	meterConfigurator ifNil: [ ^ OTMeterConfig default ].
	configured := meterConfigurator value: anOTInstrumentationScope.
	configured ifNil: [ ^ OTMeterConfig default ].
	configured class = OTMeterConfig ifTrue: [ ^ configured copy ].
	((configured == true) or: [ configured == false ]) ifTrue: [
		^ OTMeterConfig enabled: configured ].
	^ OTMeterConfig default
]

{ #category : 'configuration' }
OTMeterProvider >> meterConfigurator [

	^ meterConfigurator
]

{ #category : 'configuration' }
OTMeterProvider >> meterConfigurator: aBlockOrNil [

	meterConfigurator := aBlockOrNil
]

{ #category : 'lifecycle' }
OTMeterProvider >> shutdown [

	shutdown := true.
	^ true
]
