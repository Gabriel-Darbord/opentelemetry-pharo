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

{ #category : 'private' }
OTRecordingSpanExporter class >> exportsAllowedAfterShutdownByExporter [

	^ OTClassStateStore valueAt: #otExportsAllowedAfterShutdownByExporter forClass: self ifAbsent: [
			  | exporters |
			  exporters := WeakIdentityKeyDictionary new.
			  OTClassStateStore valueAt: #otExportsAllowedAfterShutdownByExporter forClass: self put: exporters.
			  exporters ]
]

{ #category : 'accessing' }
OTRecordingSpanExporter >> allowExportsAfterShutdown: aBoolean [

	aBoolean
		ifTrue: [ self class exportsAllowedAfterShutdownByExporter at: self put: true ]
		ifFalse: [ self class exportsAllowedAfterShutdownByExporter removeKey: self ifAbsent: [ ] ].
	^ aBoolean
]

{ #category : 'testing' }
OTRecordingSpanExporter >> allowsExportsAfterShutdown [

	^ self class exportsAllowedAfterShutdownByExporter at: self ifAbsent: [ false ]
]

{ #category : 'accessing' }
OTRecordingSpanExporter >> export: spans [

	^ self withExportLockDo: [ self exportUnchecked: spans ]
]

{ #category : 'accessing' }
OTRecordingSpanExporter >> exportUnchecked: spans [

	(self isShutdown and: [ self allowsExportsAfterShutdown not ]) ifTrue: [ ^ false ].
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
	^ self withExportLockDo: [
			  self isShutdown
				  ifTrue: [ false ]
				  ifFalse: [
						  forceFlushCount := self forceFlushCount + 1.
						  true ] ]
]

{ #category : 'accessing' }
OTRecordingSpanExporter >> forceFlushCount [

	^ forceFlushCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
OTRecordingSpanExporter >> shutdown [

	self beginShutdown ifFalse: [ ^ false ].
	^ self withExportLockDo: [
			  shutdownCount := self shutdownCount + 1.
			  self markShutdown.
			  true ]
]

{ #category : 'accessing' }
OTRecordingSpanExporter >> shutdownCount [

	^ shutdownCount ifNil: [ 0 ]
]
