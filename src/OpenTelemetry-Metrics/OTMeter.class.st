"
A backend-agnostic Meter responsible for creating metric instruments.

The current implementation is a spec-shaped no-op meter.
"
Class {
	#name : 'OTMeter',
	#superclass : 'Object',
	#instVars : [
		'provider',
		'instrumentationScope',
		'instruments'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTMeter class >> forProvider: anOTMeterProvider instrumentationScope: anInstrumentationScope [

	| meter |
	meter := self new.
	meter
		provider: anOTMeterProvider;
		instrumentationScope: anInstrumentationScope.
	^ meter
]

{ #category : 'instance creation' }
OTMeter class >> noop [

	^ OTClassStateStore
		valueAt: #otNoopMeter
		forClass: self
		ifAbsent: [
			| meter |
			meter := self
				forProvider: nil
				instrumentationScope: (OTInstrumentationScope named: '').
			OTClassStateStore valueAt: #otNoopMeter forClass: self put: meter.
			meter ]
]

{ #category : 'private - logging' }
OTMeter class >> defaultInstrumentWarningSink [

	^ OTDiagnosticLogger defaultWarningSink
]

{ #category : 'private - logging' }
OTMeter class >> instrumentWarningSink [

	^ OTClassStateStore
		valueAt: #otMeterInstrumentWarningSink
		forClass: self
		ifAbsent: [ self defaultInstrumentWarningSink ]
]

{ #category : 'private - logging' }
OTMeter class >> instrumentWarningSink: aBlock [

	aBlock
		ifNil: [
			OTClassStateStore
				removeValueAt: #otMeterInstrumentWarningSink
				forClass: self
				ifAbsent: [  ] ]
		ifNotNil: [
			OTClassStateStore
				valueAt: #otMeterInstrumentWarningSink
				forClass: self
				put: aBlock ].
	^ self instrumentWarningSink
]

{ #category : 'accessing' }
OTMeter >> instrumentationName [

	^ self instrumentationScope name
]

{ #category : 'accessing' }
OTMeter >> instrumentationScope [

	^ instrumentationScope ifNil: [ OTInstrumentationScope named: '' ]
]

{ #category : 'accessing' }
OTMeter >> instrumentationScope: anInstrumentationScope [

	instrumentationScope := anInstrumentationScope
		ifNil: [ OTInstrumentationScope named: '' ]
		ifNotNil: [ anInstrumentationScope ].
	^ instrumentationScope
]

{ #category : 'accessing' }
OTMeter >> instrumentationVersion [

	^ self instrumentationScope version
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

	^ self
		registerSynchronousInstrumentClass: OTCounter
		named: aString
		unit: aUnitString
		description: aDescriptionString
		advice: aDictionary
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

	^ self
		registerSynchronousInstrumentClass: OTGauge
		named: aString
		unit: aUnitString
		description: aDescriptionString
		advice: aDictionary
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

	^ self
		registerSynchronousInstrumentClass: OTHistogram
		named: aString
		unit: aUnitString
		description: aDescriptionString
		advice: aDictionary
]

{ #category : 'testing' }
OTMeter >> isNoop [

	^ provider isNil
}

{ #category : 'initialization' }
OTMeter >> initialize [

	super initialize.
	instruments := OrderedDictionary new
]

{ #category : 'accessing' }
OTMeter >> instruments [

	^ instruments ifNil: [ instruments := OrderedDictionary new ]
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

	^ self
		registerAsynchronousInstrumentClass: OTObservableCounter
		named: aString
		callbacks: someCallbacks
		unit: aUnitString
		description: aDescriptionString
		advice: aDictionary
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

	^ self
		registerAsynchronousInstrumentClass: OTObservableGauge
		named: aString
		callbacks: someCallbacks
		unit: aUnitString
		description: aDescriptionString
		advice: aDictionary
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

	^ self
		registerAsynchronousInstrumentClass: OTObservableUpDownCounter
		named: aString
		callbacks: someCallbacks
		unit: aUnitString
		description: aDescriptionString
		advice: aDictionary
]

{ #category : 'accessing' }
OTMeter >> provider [

	^ provider
]

{ #category : 'accessing' }
OTMeter >> provider: anOTMeterProvider [

	provider := anOTMeterProvider
]

{ #category : 'accessing' }
OTMeter >> schemaUrl [

	^ self instrumentationScope schemaUrl
]

{ #category : 'accessing' }
OTMeter >> scopeAttributes [

	^ self instrumentationScope allAttributes
]

{ #category : 'accessing' }
OTMeter >> resource [

	^ provider
		ifNil: [ OTResource empty ]
		ifNotNil: [ provider resource ]
]

{ #category : 'private' }
OTMeter >> canonicalInstrumentNameFrom: aString [

	^ aString asLowercase
]

{ #category : 'testing' }
OTMeter >> enablesSynchronousInstruments [

	^ provider notNil and: [ (provider meterConfigFor: self instrumentationScope) enabled ]
]

{ #category : 'private' }
OTMeter >> duplicateCandidateForClass: anInstrumentClass canonicalName: aCanonicalName [

	^ self instruments values
		detect: [ :each |
			each class = anInstrumentClass and: [
				(self canonicalInstrumentNameFrom: each name) = aCanonicalName ] ]
		ifNone: [ nil ]
]

{ #category : 'private - logging' }
OTMeter >> noteDuplicateInstrumentRegistrationBetween: anExistingInstrument requestedName: aString unit: aUnitString description: aDescriptionString [

	self class instrumentWarningSink value:
		'OpenTelemetry metric instrument registration conflicted for meter '
			, self instrumentationName printString
			, '. Existing instrument: '
			, anExistingInstrument class name
			, ' name='
			, anExistingInstrument name printString
			, ' unit='
			, anExistingInstrument unit printString
			, ' description='
			, anExistingInstrument description printString
			, '. Requested instrument: name='
			, aString printString
			, ' unit='
			, aUnitString printString
			, ' description='
			, aDescriptionString printString
]

{ #category : 'private - logging' }
OTMeter >> noteDuplicateInstrumentRegistrationFor: anExistingInstrument conflictingAdvice: aDictionary [

	self class instrumentWarningSink value:
		'OpenTelemetry metric instrument registration reused first-seen advisory parameters for '
			, anExistingInstrument class name
			, ' '
			, anExistingInstrument name printString
			, ': '
			, aDictionary printString
]

{ #category : 'private - logging' }
OTMeter >> noteInvalidInstrumentName: aValue [

	self class instrumentWarningSink value:
		'OpenTelemetry metric instrument name was invalid and has been left unchanged: '
			, (aValue ifNil: [ 'nil' ] ifNotNil: [ aValue printString ])
]

{ #category : 'private' }
OTMeter >> normalizedInstrumentAdviceFrom: aDictionary [

	aDictionary ifNil: [ ^ Dictionary new ].
	^ aDictionary asDictionary copy
]

{ #category : 'private' }
OTMeter >> normalizedInstrumentDescriptionFrom: aValue [

	^ aValue ifNil: [ '' ] ifNotNil: [ aValue asString ]
]

{ #category : 'private' }
OTMeter >> normalizedInstrumentNameFrom: aValue [

	| instrumentName |
	aValue ifNil: [
		self noteInvalidInstrumentName: aValue.
		^ '' ].
	instrumentName := aValue asString.
	instrumentName trimBoth isEmpty ifTrue: [
		self noteInvalidInstrumentName: aValue.
		^ '' ].
	(self validatesInstrumentName: instrumentName) ifFalse: [
		self noteInvalidInstrumentName: aValue ].
	^ instrumentName
]

{ #category : 'private' }
OTMeter >> normalizedInstrumentUnitFrom: aValue [

	^ aValue ifNil: [ '' ] ifNotNil: [ aValue asString ]
]

{ #category : 'private' }
OTMeter >> registerAsynchronousInstrumentClass: anInstrumentClass named: aValue callbacks: someCallbacks unit: aUnitString description: aDescriptionString advice: aDictionary [

	^ self
		registerInstrumentKeyedByClass: anInstrumentClass
		named: aValue
		unit: aUnitString
		description: aDescriptionString
		advice: aDictionary
		ifAbsent: [ :instrumentName :unitString :descriptionString :adviceDictionary |
			anInstrumentClass
				forMeter: self
				name: instrumentName
				callbacks: someCallbacks
				unit: unitString
				description: descriptionString
				advice: adviceDictionary ]
]

{ #category : 'private' }
OTMeter >> registerInstrumentKeyedByClass: anInstrumentClass named: aValue unit: aUnitString description: aDescriptionString advice: aDictionary ifAbsent: anInstrumentBlock [

	| adviceByIdentity canonicalName candidate descriptionString identityKey instrument instrumentName unitString |
	instrumentName := self normalizedInstrumentNameFrom: aValue.
	unitString := self normalizedInstrumentUnitFrom: aUnitString.
	descriptionString := self normalizedInstrumentDescriptionFrom: aDescriptionString.
	adviceByIdentity := self normalizedInstrumentAdviceFrom: aDictionary.
	canonicalName := self canonicalInstrumentNameFrom: instrumentName.
	identityKey := { anInstrumentClass. canonicalName. unitString. descriptionString }.
	instrument := self instruments at: identityKey ifAbsent: [ nil ].
	instrument ifNotNil: [
		(instrument name ~= instrumentName and: [
			(self canonicalInstrumentNameFrom: instrument name) = canonicalName ]) ifTrue: [
			self
				noteDuplicateInstrumentRegistrationBetween: instrument
				requestedName: instrumentName
				unit: unitString
				description: descriptionString ].
		instrument advice = adviceByIdentity ifFalse: [
			self
				noteDuplicateInstrumentRegistrationFor: instrument
				conflictingAdvice: adviceByIdentity ].
		^ instrument ].
	candidate := self
		duplicateCandidateForClass: anInstrumentClass
		canonicalName: canonicalName.
	candidate ifNotNil: [
		self
			noteDuplicateInstrumentRegistrationBetween: candidate
			requestedName: instrumentName
			unit: unitString
			description: descriptionString ].
	instrument := anInstrumentBlock
		value: instrumentName
		value: unitString
		value: descriptionString
		value: adviceByIdentity.
	self instruments at: identityKey put: instrument.
	^ instrument
]

{ #category : 'private' }
OTMeter >> registerSynchronousInstrumentClass: anInstrumentClass named: aValue unit: aUnitString description: aDescriptionString advice: aDictionary [

	^ self
		registerInstrumentKeyedByClass: anInstrumentClass
		named: aValue
		unit: aUnitString
		description: aDescriptionString
		advice: aDictionary
		ifAbsent: [ :instrumentName :unitString :descriptionString :adviceDictionary |
			anInstrumentClass
				forMeter: self
				name: instrumentName
				unit: unitString
				description: descriptionString
				advice: adviceDictionary ]
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

	^ self
		registerSynchronousInstrumentClass: OTUpDownCounter
		named: aString
		unit: aUnitString
		description: aDescriptionString
		advice: aDictionary
]

{ #category : 'private' }
OTMeter >> validatesInstrumentName: aString [

	aString isEmpty ifTrue: [ ^ false ].
	aString size > 255 ifTrue: [ ^ false ].
	(aString first isLetter and: [ aString first asciiValue <= 127 ]) ifFalse: [ ^ false ].
	^ aString allSatisfy: [ :each |
		each asciiValue <= 127 and: [
			each isAlphaNumeric or: [
				#( $_ $. $- $/ ) includes: each ] ] ]
]
