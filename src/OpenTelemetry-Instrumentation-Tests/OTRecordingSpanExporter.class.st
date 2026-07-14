Class {
	#name : 'OTRecordingSpanExporter',
	#superclass : 'OTSpanExporter',
	#instVars : [
		'exportedBatches',
		'forceFlushCount',
		'shutdownCount'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'accessing' }
OTRecordingSpanExporter >> export: spans [

	self isShutdown ifTrue: [ ^ false ].
	self exportedBatches add: spans asArray.
	^ true
]

{ #category : 'accessing' }
OTRecordingSpanExporter >> exportedBatches [

	^ exportedBatches ifNil: [ exportedBatches := OrderedCollection new ]
]

{ #category : 'accessing' }
OTRecordingSpanExporter >> forceFlush [

	self isShutdown ifTrue: [ ^ false ].
	forceFlushCount := self forceFlushCount + 1.
	^ true
]

{ #category : 'accessing' }
OTRecordingSpanExporter >> forceFlushCount [

	^ forceFlushCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
OTRecordingSpanExporter >> shutdown [

	self isShutdown ifTrue: [ ^ false ].
	shutdownCount := self shutdownCount + 1.
	self markShutdown.
	^ true
]

{ #category : 'accessing' }
OTRecordingSpanExporter >> shutdownCount [

	^ shutdownCount ifNil: [ 0 ]
]
