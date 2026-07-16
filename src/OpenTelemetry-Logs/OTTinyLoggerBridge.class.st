Class {
	#name : 'OTTinyLoggerBridge',
	#superclass : 'Object',
	#instVars : [
		'logger',
		'parentLogger',
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
OTTinyLoggerBridge class >> forLogger: anOTLogger [

	^ self new
		logger: anOTLogger;
		yourself
]

{ #category : 'accessing' }
OTTinyLoggerBridge >> attributesBlock [

	^ attributesBlock ifNil: [ [ :message | #() ] ]
]

{ #category : 'accessing' }
OTTinyLoggerBridge >> attributesBlock: aBlock [

	attributesBlock := aBlock ifNil: [ [ :message | #() ] ] ifNotNil: [ aBlock ].
	^ attributesBlock
]

{ #category : 'accessing' }
OTTinyLoggerBridge >> bodyBlock [

	^ bodyBlock ifNil: [ [ :message | message ] ]
]

{ #category : 'accessing' }
OTTinyLoggerBridge >> bodyBlock: aBlock [

	bodyBlock := aBlock ifNil: [ [ :message | message ] ] ifNotNil: [ aBlock ].
	^ bodyBlock
]

{ #category : 'logging' }
OTTinyLoggerBridge >> clearLog [

	^ self
]

{ #category : 'private' }
OTTinyLoggerBridge >> defaultSeverityTextFor: aSeverityNumber [

	^ (OTSeverity isSpecified: aSeverityNumber)
		ifTrue: [ OTSeverity shortNameFor: aSeverityNumber ]
		ifFalse: [ '' ]
]

{ #category : 'accessing' }
OTTinyLoggerBridge >> eventNameBlock [

	^ eventNameBlock ifNil: [ [ :message | nil ] ]
]

{ #category : 'accessing' }
OTTinyLoggerBridge >> eventNameBlock: aBlock [

	eventNameBlock := aBlock ifNil: [ [ :message | nil ] ] ifNotNil: [ aBlock ].
	^ eventNameBlock
]

{ #category : 'initialization' }
OTTinyLoggerBridge >> initialize [

	super initialize.
	severityNumber := OTSeverity info.
	severityText := 'INFO'.
	bodyBlock := [ :message | message ].
	attributesBlock := [ :message | #() ].
	eventNameBlock := [ :message | nil ]
]

{ #category : 'accessing' }
OTTinyLoggerBridge >> kind [

	^ #openTelemetry
]

{ #category : 'accessing' }
OTTinyLoggerBridge >> logger [

	^ logger
]

{ #category : 'accessing' }
OTTinyLoggerBridge >> logger: anOTLogger [

	logger := anOTLogger.
	^ logger
]

{ #category : 'opening' }
OTTinyLoggerBridge >> open [

	^ self
]

{ #category : 'accessing' }
OTTinyLoggerBridge >> parentLogger [

	^ parentLogger
]

{ #category : 'accessing' }
OTTinyLoggerBridge >> parentLogger: aTinyLogger [

	parentLogger := aTinyLogger.
	^ self
]

{ #category : 'logging' }
OTTinyLoggerBridge >> record: aString [

	| builder |
	logger ifNil: [ ^ false ].
	builder := logger logRecordBuilder.
	builder
		severityNumber: self severityNumber;
		severityText: self severityText;
		body: (self bodyBlock cull: aString);
		attributes: (self attributesBlock cull: aString);
		eventName: (self eventNameBlock cull: aString).
	^ builder emit
]

{ #category : 'accessing' }
OTTinyLoggerBridge >> severityNumber [

	^ severityNumber ifNil: [ OTSeverity info ]
]

{ #category : 'accessing' }
OTTinyLoggerBridge >> severityNumber: anInteger [

	severityNumber := OTSeverity normalize: anInteger.
	severityText := self defaultSeverityTextFor: severityNumber.
	^ severityNumber
]

{ #category : 'accessing' }
OTTinyLoggerBridge >> severityText [

	^ severityText ifNil: [ self defaultSeverityTextFor: self severityNumber ]
]

{ #category : 'accessing' }
OTTinyLoggerBridge >> severityText: aString [

	severityText := aString ifNil: [ self defaultSeverityTextFor: self severityNumber ] ifNotNil: [ aString ].
	^ severityText
]
