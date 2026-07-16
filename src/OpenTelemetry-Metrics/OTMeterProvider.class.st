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
		'meterConfigurator',
		'resource',
		'measurements',
		'metricReaders'
	],
	#classVars : [
		'Current'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'accessing' }
OTMeterProvider class >> current [

	^ Current ifNil: [ Current := self readConfiguration ]
]

{ #category : 'accessing' }
OTMeterProvider class >> current: anOTMeterProvider [

	Current := anOTMeterProvider
]

{ #category : 'class initialization' }
OTMeterProvider class >> reset [

	Current := nil
]

{ #category : 'instance creation' }
OTMeterProvider class >> readConfiguration [

	^ self new
		resource: OTTracerProvider configuredResource;
		yourself
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

	^ self metricReaders allSatisfy: [ :each | each forceFlush ]
]

{ #category : 'collecting' }
OTMeterProvider >> collectMeasurementsFor: anOTMetricReader [

	| collected |
	collected := self measurements copy.
	self meters valuesDo: [ :each |
		each collectMeasurementsFor: anOTMetricReader into: collected ].
	^ collected
]

{ #category : 'initialization' }
OTMeterProvider >> initialize [

	super initialize.
	meters := OrderedDictionary new.
	measurements := OrderedCollection new.
	metricReaders := OrderedCollection new.
	shutdown := false.
	meterConfigurator := nil.
	resource := OTResource empty
]

{ #category : 'testing' }
OTMeterProvider >> isShutdown [

	^ shutdown
]

{ #category : 'accessing' }
OTMeterProvider >> meters [

	^ meters ifNil: [ meters := OrderedDictionary new ]
]

{ #category : 'accessing' }
OTMeterProvider >> measurements [

	^ measurements ifNil: [ measurements := OrderedCollection new ]
]

{ #category : 'accessing' }
OTMeterProvider >> metricReaders [

	^ metricReaders ifNil: [ metricReaders := OrderedCollection new ]
]

{ #category : 'accessing' }
OTMeterProvider >> resource [

	^ resource ifNil: [ OTResource empty ]
]

{ #category : 'accessing' }
OTMeterProvider >> resource: anOTResource [

	resource := anOTResource ifNil: [ OTResource empty ] ifNotNil: [ anOTResource ].
	^ self resource
]

{ #category : 'accessing' }
OTMeterProvider >> registeredMetricInstruments [

	| instruments |
	instruments := OrderedCollection new.
	self meters valuesDo: [ :each |
		instruments addAll: each registeredMetricInstruments ].
	^ instruments asArray
]

{ #category : 'recording' }
OTMeterProvider >> recordMeasurementFor: anOTMetricInstrument value: aNumber attributes: aCollection [

	anOTMetricInstrument enabled ifFalse: [ ^ false ].
	self measurements add:
		(OTMetricMeasurement
			instrument: anOTMetricInstrument
			value: aNumber
			attributes: aCollection).
	^ true
]

{ #category : 'accessing' }
OTMeterProvider >> addMetricReader: anOTMetricReader [

	anOTMetricReader ifNil: [ ^ self metricReaders ].
	anOTMetricReader attachToProvider: self.
	anOTMetricReader didRegisterWithProvider.
	self metricReaders add: anOTMetricReader.
	^ self metricReaders
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

	self metricReaders do: [ :each | each shutdown ].
	shutdown := true.
	^ true
]
