"
A composite processor that fans out to multiple processors in registration order.
"
Class {
	#name : 'OTCompositeLogRecordProcessor',
	#superclass : 'OTLogRecordProcessor',
	#instVars : [
		'processors'
	],
	#category : 'OpenTelemetry-Logs',
	#package : 'OpenTelemetry-Logs'
}

{ #category : 'instance creation' }
OTCompositeLogRecordProcessor class >> withAll: aCollection [

	^ self new
		processors: aCollection;
		yourself
]

{ #category : 'accessing' }
OTCompositeLogRecordProcessor >> addProcessor: anOTLogRecordProcessor [

	self processors add: anOTLogRecordProcessor.
	^ anOTLogRecordProcessor
]

{ #category : 'accessing' }
OTCompositeLogRecordProcessor >> componentProcessors [

	^ OrderedCollection streamContents: [ :stream |
		self processors do: [ :each |
			each componentProcessors do: [ :processor | stream nextPut: processor ] ] ]
]

{ #category : 'testing' }
OTCompositeLogRecordProcessor >> enabledIn: anOTContext instrumentationScope: anInstrumentationScope severityNumber: anObject eventName: aString [

	self processors isEmpty ifTrue: [ ^ false ].
	^ self processors anySatisfy: [ :each |
		each
			enabledIn: anOTContext
			instrumentationScope: anInstrumentationScope
			severityNumber: anObject
			eventName: aString ]
]

{ #category : 'processing' }
OTCompositeLogRecordProcessor >> forceFlush [

	^ self processors
		inject: true
		into: [ :allFlushed :each | (each forceFlush) & allFlushed ]
]

{ #category : 'initialization' }
OTCompositeLogRecordProcessor >> initialize [

	super initialize.
	processors := OrderedCollection new
]

{ #category : 'processing' }
OTCompositeLogRecordProcessor >> onEmit: anOTLogRecord context: anOTContext [

	self processors do: [ :each | each onEmit: anOTLogRecord context: anOTContext ]
]

{ #category : 'accessing' }
OTCompositeLogRecordProcessor >> processors [

	^ processors ifNil: [ OrderedCollection new ]
]

{ #category : 'accessing' }
OTCompositeLogRecordProcessor >> processors: aCollection [

	processors := OrderedCollection new.
	aCollection ifNotNil: [ aCollection do: [ :each | processors add: each ] ].
	^ processors
]

{ #category : 'processing' }
OTCompositeLogRecordProcessor >> shutdown [

	| flushed |
	flushed := self forceFlush.
	^ (self processors
		inject: true
		into: [ :allShutdown :each | (each shutdown) & allShutdown ]) & flushed
]
