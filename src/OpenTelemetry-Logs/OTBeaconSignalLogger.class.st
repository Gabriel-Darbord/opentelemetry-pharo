Class {
	#name : 'OTBeaconSignalLogger',
	#superclass : 'SignalLogger',
	#instVars : [
		'logger',
		'severityNumber',
		'severityText',
		'bodyBlock',
		'attributesBlock',
		'eventNameBlock'
	],
	#category : 'OpenTelemetry-Logs',
	#package : 'OpenTelemetry-Logs'
}

{ #category : 'instance creation' }
OTBeaconSignalLogger class >> forLogger: anOTLogger [

	^ self new
		  logger: anOTLogger;
		  yourself
]

{ #category : 'private' }
OTBeaconSignalLogger >> attributeValueFor: anObject [

	^ [ OTAttributeNormalizer normalizeAttributeValue: anObject ]
		  on: Error
		  do: [ anObject printString ]
]

{ #category : 'accessing' }
OTBeaconSignalLogger >> attributesBlock [

	^ attributesBlock ifNil: [ [ :aSignal | self defaultAttributesFor: aSignal ] ]
]

{ #category : 'accessing' }
OTBeaconSignalLogger >> attributesBlock: aBlock [

	attributesBlock := aBlock ifNil: [ [ :aSignal | self defaultAttributesFor: aSignal ] ] ifNotNil: [ aBlock ].
	^ attributesBlock
]

{ #category : 'accessing' }
OTBeaconSignalLogger >> bodyBlock [

	^ bodyBlock ifNil: [ [ :aSignal | self defaultBodyFor: aSignal ] ]
]

{ #category : 'accessing' }
OTBeaconSignalLogger >> bodyBlock: aBlock [

	bodyBlock := aBlock ifNil: [ [ :aSignal | self defaultBodyFor: aSignal ] ] ifNotNil: [ aBlock ].
	^ bodyBlock
]

{ #category : 'private' }
OTBeaconSignalLogger >> defaultAttributesFor: aBeaconSignal [

	| attributes |
	attributes := OrderedDictionary new.
	attributes
		at: 'beacon.signal.name' put: aBeaconSignal name;
		at: 'beacon.signal.class' put: aBeaconSignal class name;
		at: 'beacon.signal.process_id' put: aBeaconSignal processId.
	aBeaconSignal properties associationsDo: [ :each |
		attributes at: (self normalizedPropertyAttributeNameFor: each key) put: (self attributeValueFor: each value) ].
	^ attributes
]

{ #category : 'private' }
OTBeaconSignalLogger >> defaultBodyFor: aBeaconSignal [

	| body |
	body := String streamContents: [ :stream | aBeaconSignal printOneLineContentsOn: stream ].
	^ body ifEmpty: [ aBeaconSignal name ] ifNotEmpty: [ body ]
]

{ #category : 'private' }
OTBeaconSignalLogger >> defaultSeverityTextFor: aSeverityNumber [

	^ (OTSeverity isSpecified: aSeverityNumber)
		  ifTrue: [ OTSeverity shortNameFor: aSeverityNumber ]
		  ifFalse: [ '' ]
]

{ #category : 'accessing' }
OTBeaconSignalLogger >> eventNameBlock [

	^ eventNameBlock ifNil: [ [ :aSignal | aSignal name ] ]
]

{ #category : 'accessing' }
OTBeaconSignalLogger >> eventNameBlock: aBlock [

	eventNameBlock := aBlock ifNil: [ [ :aSignal | aSignal name ] ] ifNotNil: [ aBlock ].
	^ eventNameBlock
]

{ #category : 'initialization' }
OTBeaconSignalLogger >> initialize [

	super initialize.
	severityNumber := OTSeverity info.
	severityText := 'INFO'.
	bodyBlock := [ :aSignal | self defaultBodyFor: aSignal ].
	attributesBlock := [ :aSignal | self defaultAttributesFor: aSignal ].
	eventNameBlock := [ :aSignal | aSignal name ]
]

{ #category : 'accessing' }
OTBeaconSignalLogger >> logger [

	^ logger
]

{ #category : 'accessing' }
OTBeaconSignalLogger >> logger: anOTLogger [

	logger := anOTLogger.
	self name: (anOTLogger ifNil: [ 'openTelemetryBeacon' ] ifNotNil: [ 'openTelemetryBeacon:' , anOTLogger instrumentationName ]).
	^ logger
]

{ #category : 'logging' }
OTBeaconSignalLogger >> nextPut: aSignal [

	| builder |
	logger ifNil: [ ^ false ].
	builder := logger logRecordBuilder.
	builder
		timestamp: aSignal timestamp;
		severityNumber: self severityNumber;
		severityText: self severityText;
		body: (self bodyBlock cull: aSignal);
		attributes: (self attributesBlock cull: aSignal);
		eventName: (self eventNameBlock cull: aSignal).
	^ builder emit
]

{ #category : 'private' }
OTBeaconSignalLogger >> normalizedPropertyAttributeNameFor: aKey [

	| normalizedKey |
	normalizedKey := [ OTAttributeNormalizer normalizeAttributeKey: aKey ]
		                 on: Error
		                 do: [ aKey printString ].
	^ 'beacon.signal.properties.' , normalizedKey
]

{ #category : 'accessing' }
OTBeaconSignalLogger >> severityNumber [

	^ severityNumber ifNil: [ OTSeverity info ]
]

{ #category : 'accessing' }
OTBeaconSignalLogger >> severityNumber: anInteger [

	severityNumber := OTSeverity normalize: anInteger.
	severityText := self defaultSeverityTextFor: severityNumber.
	^ severityNumber
]

{ #category : 'accessing' }
OTBeaconSignalLogger >> severityText [

	^ severityText ifNil: [ self defaultSeverityTextFor: self severityNumber ]
]

{ #category : 'accessing' }
OTBeaconSignalLogger >> severityText: aString [

	severityText := aString ifNil: [ self defaultSeverityTextFor: self severityNumber ] ifNotNil: [ aString ].
	^ severityText
]
