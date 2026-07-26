Class {
	#name : 'OTRecordingLogRecordExporter',
	#superclass : 'OTLogRecordExporter',
	#instVars : [
		'exportedBatches',
		'forceFlushCount',
		'shutdownCount'
	],
	#category : 'OpenTelemetry-Logs-Tests',
	#package : 'OpenTelemetry-Logs-Tests'
}

{ #category : 'exporting' }
OTRecordingLogRecordExporter >> export: someLogRecords [

	self isShutdown ifTrue: [ ^ false ].
	self exportedBatches add: (someLogRecords collect: [ :each | each copy ]) asArray.
	^ true
]

{ #category : 'accessing' }
OTRecordingLogRecordExporter >> exportedBatches [

	^ exportedBatches ifNil: [ exportedBatches := OrderedCollection new ]
]

{ #category : 'accessing' }
OTRecordingLogRecordExporter >> exportedRecords [

	^ OrderedCollection streamContents: [ :stream |
		  self exportedBatches do: [ :each | each do: [ :record | stream nextPut: record ] ] ]
]

{ #category : 'exporting' }
OTRecordingLogRecordExporter >> forceFlush [

	super forceFlush ifFalse: [ ^ false ].
	forceFlushCount := self forceFlushCount + 1.
	^ true
]

{ #category : 'accessing' }
OTRecordingLogRecordExporter >> forceFlushCount [

	^ forceFlushCount ifNil: [ 0 ]
]

{ #category : 'exporting' }
OTRecordingLogRecordExporter >> shutdown [

	super shutdown ifFalse: [ ^ false ].
	shutdownCount := self shutdownCount + 1.
	^ true
]

{ #category : 'accessing' }
OTRecordingLogRecordExporter >> shutdownCount [

	^ shutdownCount ifNil: [ 0 ]
]
