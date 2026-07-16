"
An ergonomic builder for logger emit calls.
"
Class {
	#name : 'OTLogRecordBuilder',
	#superclass : 'Object',
	#instVars : [
		'logger',
		'timestamp',
		'observedTimestamp',
		'context',
		'severityNumber',
		'severityText',
		'body',
		'attributes',
		'eventName',
		'exception'
	],
	#category : 'OpenTelemetry-Logs',
	#package : 'OpenTelemetry-Logs'
}

{ #category : 'instance creation' }
OTLogRecordBuilder class >> forLogger: anOTLogger [

	^ self new
		logger: anOTLogger;
		yourself
]

{ #category : 'accessing' }
OTLogRecordBuilder >> attributeNamed: aKey put: aValue [

	attributes at: aKey put: aValue.
	self
]

{ #category : 'accessing' }
OTLogRecordBuilder >> attributes: aCollection [

	attributes := OrderedDictionary new.
	aCollection ifNotNil: [
		(aCollection isDictionary
			ifTrue: [ aCollection associations ]
			ifFalse: [ aCollection ]) do: [ :each |
				attributes at: each key put: each value ] ].
	self
]

{ #category : 'accessing' }
OTLogRecordBuilder >> body: anObject [

	body := anObject.
	self
]

{ #category : 'actions' }
OTLogRecordBuilder >> emit [

	^ logger
		emitTimestamp: timestamp
		observedTimestamp: observedTimestamp
		in: context
		severityNumber: severityNumber
		severityText: severityText
		body: body
		attributes: attributes
		eventName: eventName
		exception: exception
]

{ #category : 'accessing' }
OTLogRecordBuilder >> eventName: aString [

	eventName := aString.
	self
]

{ #category : 'accessing' }
OTLogRecordBuilder >> exception: anException [

	exception := anException.
	self
]

{ #category : 'accessing' }
OTLogRecordBuilder >> inContext: anOTContext [

	context := anOTContext.
	self
]

{ #category : 'actions' }
OTLogRecordBuilder >> inCurrentContext [

	context := OpenTelemetry currentContext.
	self
]

{ #category : 'initialization' }
OTLogRecordBuilder >> initialize [

	super initialize.
	attributes := OrderedDictionary new.
	severityNumber := OTSeverity undefined
]

{ #category : 'accessing' }
OTLogRecordBuilder >> logger: anOTLogger [

	logger := anOTLogger.
	^ logger
]

{ #category : 'accessing' }
OTLogRecordBuilder >> observedTimestamp: aDateAndTime [

	observedTimestamp := aDateAndTime.
	self
]

{ #category : 'accessing' }
OTLogRecordBuilder >> severityNumber: anObject [

	severityNumber := anObject.
	self
]

{ #category : 'accessing' }
OTLogRecordBuilder >> severityText: aString [

	severityText := aString.
	self
]

{ #category : 'accessing' }
OTLogRecordBuilder >> timestamp: aDateAndTime [

	timestamp := aDateAndTime.
	self
]
