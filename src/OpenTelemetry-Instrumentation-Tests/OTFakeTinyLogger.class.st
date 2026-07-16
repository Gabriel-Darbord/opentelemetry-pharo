Class {
	#name : 'OTFakeTinyLogger',
	#superclass : 'Object',
	#instVars : [
		'ensureStdoutLoggerCount',
		'recordedMessages'
	],
	#classVars : [
		'LastInstance'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'accessing' }
OTFakeTinyLogger class >> lastInstance [

	^ LastInstance
]

{ #category : 'class initialization' }
OTFakeTinyLogger class >> reset [

	LastInstance := nil
]

{ #category : 'initialization' }
OTFakeTinyLogger >> initialize [

	super initialize.
	LastInstance := self.
	ensureStdoutLoggerCount := 0.
	recordedMessages := OrderedCollection new
]

{ #category : 'operations' }
OTFakeTinyLogger >> ensureStdoutLogger [

	ensureStdoutLoggerCount := ensureStdoutLoggerCount + 1.
	self
]

{ #category : 'accessing' }
OTFakeTinyLogger >> ensureStdoutLoggerCount [

	^ ensureStdoutLoggerCount
]

{ #category : 'accessing' }
OTFakeTinyLogger >> record: aBlock [

	recordedMessages add: aBlock value.
	self
]

{ #category : 'accessing' }
OTFakeTinyLogger >> recordedMessages [

	^ recordedMessages copy
]
