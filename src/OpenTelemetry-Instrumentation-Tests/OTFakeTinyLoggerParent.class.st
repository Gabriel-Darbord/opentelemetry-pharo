Class {
	#name : 'OTFakeTinyLoggerParent',
	#superclass : 'Object',
	#instVars : [
		'loggers',
		'recordedMessages'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'accessing' }
OTFakeTinyLoggerParent >> addLogger: aLogger [

	loggers add: aLogger.
	^ aLogger
]

{ #category : 'initialization' }
OTFakeTinyLoggerParent >> initialize [

	super initialize.
	loggers := OrderedCollection new.
	recordedMessages := OrderedCollection new
]

{ #category : 'accessing' }
OTFakeTinyLoggerParent >> record: aValue [

	| message |
	message := aValue isBlock
		           ifTrue: [ aValue value ]
		           ifFalse: [ aValue ].
	recordedMessages add: message.
	loggers do: [ :each | each record: message ].
	^ message
]

{ #category : 'accessing' }
OTFakeTinyLoggerParent >> recordedMessages [

	^ recordedMessages copy
]
