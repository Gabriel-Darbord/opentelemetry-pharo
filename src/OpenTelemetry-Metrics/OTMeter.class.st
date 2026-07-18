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
]

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
OTMeter >> registeredMetricInstruments [

	^ self instruments values asArray
]

{ #category : 'collecting' }
OTMeter >> collectMeasurementsFor: anOTMetricReader into: aCollection [

	self instruments valuesDo: [ :each | each collectFor: anOTMetricReader into: aCollection ]
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

	^ self enablesMetricCollection
]

{ #category : 'testing' }
OTMeter >> enablesMetricCollection [

	^ provider notNil and: [ (provider meterConfigFor: self instrumentationScope) enabled ]
]

{ #category : 'testing' }
OTMeter >> enablesSynchronousInstrument: anOTMetricInstrument [

	| matchingViews resolvedViews |
	self enablesMetricCollection ifFalse: [ ^ false ].
	provider ifNil: [ ^ false ].
	matchingViews := provider matchingViewsFor: anOTMetricInstrument.
	matchingViews ifEmpty: [ ^ true ].
	resolvedViews := matchingViews select: [ :each |
		anOTMetricInstrument supportsAggregation: each aggregation ].
	resolvedViews ifEmpty: [ ^ true ].
	^ resolvedViews anySatisfy: [ :each | each aggregation ~= #drop ]
]

{ #category : 'private' }
OTMeter >> duplicateCandidateForCanonicalName: aCanonicalName [

	^ self instruments values
		detect: [ :each |
			(self canonicalInstrumentNameFrom: each name) = aCanonicalName ]
		ifNone: [ nil ]
]

{ #category : 'private - logging' }
OTMeter >> hasViewCorrectingDescriptionConflictFor: anOTMetricInstrument [

	provider ifNil: [ ^ false ].
	^ (provider matchingViewsFor: anOTMetricInstrument)
		anySatisfy: [ :each | each streamDescription notNil ]
]

{ #category : 'private - logging' }
OTMeter >> duplicateRegistrationResolutionHintFor: anExistingInstrument requestedInstrumentClass: anInstrumentClass name: aString unit: aUnitString description: aDescriptionString [

	| requestedType |
	anExistingInstrument class ~= anInstrumentClass ifTrue: [
		requestedType := OTMetricView normalizedInstrumentTypeFrom: anInstrumentClass.
		^ String streamContents: [ :stream |
			stream
				nextPutAll: '. A renaming view can resolve this, for example: ';
				nextPutAll: '((OTMetricView named: ';
				print: aString;
				nextPutAll: ') instrumentType: ';
				print: requestedType;
				nextPutAll: '; streamName: ';
				print: aString , '.' , requestedType asString;
				nextPutAll: '; yourself)' ] ].
	(anExistingInstrument unit = aUnitString
		and: [ anExistingInstrument description ~= aDescriptionString ]) ifTrue: [
		^ String streamContents: [ :stream |
			stream
				nextPutAll: '. A view can align descriptions, for example: ';
				nextPutAll: '((OTMetricView named: ';
				print: aString;
				nextPutAll: ') streamDescription: ';
				print: aDescriptionString;
				nextPutAll: '; yourself)' ] ].
	^ ''
]

{ #category : 'private - logging' }
OTMeter >> noteDuplicateInstrumentRegistrationBetween: anExistingInstrument requestedInstrumentClass: anInstrumentClass requestedName: aString unit: aUnitString description: aDescriptionString [

	| warning |
	warning := String streamContents: [ :stream |
		stream
			nextPutAll: 'OpenTelemetry metric instrument registration conflicted for meter ';
			print: self instrumentationName;
			nextPutAll: '. Existing instrument: ';
			nextPutAll: anExistingInstrument class name;
			nextPutAll: ' name=';
			print: anExistingInstrument name;
			nextPutAll: ' unit=';
			print: anExistingInstrument unit;
			nextPutAll: ' description=';
			print: anExistingInstrument description;
			nextPutAll: '. Requested instrument: class=';
			nextPutAll: anInstrumentClass name;
			nextPutAll: ' name=';
			print: aString;
			nextPutAll: ' unit=';
			print: aUnitString;
			nextPutAll: ' description=';
			print: aDescriptionString;
			nextPutAll:
				(self
					duplicateRegistrationResolutionHintFor: anExistingInstrument
					requestedInstrumentClass: anInstrumentClass
					name: aString
					unit: aUnitString
					description: aDescriptionString) ].
	self class instrumentWarningSink value: warning
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
				requestedInstrumentClass: anInstrumentClass
				requestedName: instrumentName
				unit: unitString
				description: descriptionString ].
		instrument advice = adviceByIdentity ifFalse: [
			self
				noteDuplicateInstrumentRegistrationFor: instrument
				conflictingAdvice: adviceByIdentity ].
		^ instrument ].
	candidate := self duplicateCandidateForCanonicalName: canonicalName.
	candidate ifNotNil: [
		((candidate class = anInstrumentClass
			and: [ candidate unit = unitString ])
			and: [ candidate description ~= descriptionString ]) ifTrue: [
			(self hasViewCorrectingDescriptionConflictFor: candidate) ifFalse: [
				self
					noteDuplicateInstrumentRegistrationBetween: candidate
					requestedInstrumentClass: anInstrumentClass
					requestedName: instrumentName
					unit: unitString
					description: descriptionString ] ]
		ifFalse: [
			self
				noteDuplicateInstrumentRegistrationBetween: candidate
				requestedInstrumentClass: anInstrumentClass
				requestedName: instrumentName
				unit: unitString
				description: descriptionString ] ].
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
