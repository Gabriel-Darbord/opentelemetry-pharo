"
A composite processor that fans out to multiple processors in registration order.
"
Class {
	#name : 'OTCompositeLogRecordProcessor',
	#superclass : 'OTLogRecordProcessor',
	#instVars : [
		'processors',
		'stateLock',
		'shutdownRequested',
		'shutdownCompleted'
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

	self isShutdown ifTrue: [ ^ anOTLogRecordProcessor ].
	self processors add: anOTLogRecordProcessor.
	^ anOTLogRecordProcessor
]

{ #category : 'private - lifecycle' }
OTCompositeLogRecordProcessor >> beginShutdown [

	^ stateLock critical: [
			  (shutdownRequested = true or: [ shutdownCompleted = true ])
				  ifTrue: [ false ]
				  ifFalse: [
						  shutdownRequested := true.
						  true ] ]
]

{ #category : 'accessing' }
OTCompositeLogRecordProcessor >> componentProcessors [

	^ OrderedCollection streamContents: [ :stream |
		  self processors do: [ :each | each componentProcessors do: [ :processor | stream nextPut: processor ] ] ]
]

{ #category : 'testing' }
OTCompositeLogRecordProcessor >> enabledIn: anOTContext instrumentationScope: anInstrumentationScope severityNumber: anObject eventName: aString [

	self isShutdown ifTrue: [ ^ false ].
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

	self isShutdown ifTrue: [ ^ false ].
	^ self processors inject: true into: [ :allFlushed :each | each forceFlush & allFlushed ]
]

{ #category : 'initialization' }
OTCompositeLogRecordProcessor >> initialize [

	super initialize.
	processors := OrderedCollection new.
	stateLock := Semaphore forMutualExclusion.
	shutdownRequested := false.
	shutdownCompleted := false
]

{ #category : 'testing' }
OTCompositeLogRecordProcessor >> isShutdown [

	^ stateLock critical: [ shutdownRequested = true or: [ shutdownCompleted = true ] ]
]

{ #category : 'private - lifecycle' }
OTCompositeLogRecordProcessor >> markShutdown [

	stateLock critical: [
			shutdownRequested := true.
			shutdownCompleted := true ].
	self
]

{ #category : 'processing' }
OTCompositeLogRecordProcessor >> onEmit: anOTLogRecord context: anOTContext [

	self isShutdown ifTrue: [ ^ self ].
	self processors do: [ :each | each onEmit: anOTLogRecord context: anOTContext ].
	self
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

	| flushed processorsSnapshot |
	self beginShutdown ifFalse: [ ^ false ].
	processorsSnapshot := self componentProcessors.
	flushed := processorsSnapshot inject: true into: [ :allFlushed :each | each forceFlush & allFlushed ].
	self markShutdown.
	^ (processorsSnapshot inject: true into: [ :allShutdown :each | each shutdown & allShutdown ]) & flushed
]
