Class {
	#name : 'OTFailingSpanExporter',
	#superclass : 'OTRecordingSpanExporter',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'instance creation' }
OTFailingSpanExporter class >> failingOperations: aCollection [

	^ self new
		  operationsToFail: aCollection;
		  yourself
]

{ #category : 'private' }
OTFailingSpanExporter class >> operationsToFailByExporter [

	^ OTClassStateStore valueAt: #otOperationsToFailByExporter forClass: self ifAbsent: [
			  | exporters |
			  exporters := WeakIdentityKeyDictionary new.
			  OTClassStateStore valueAt: #otOperationsToFailByExporter forClass: self put: exporters.
			  exporters ]
]

{ #category : 'accessing' }
OTFailingSpanExporter >> export: spans [

	^ self withExportLockDo: [
			  (self shouldFailOperationNamed: 'export') ifTrue: [ Error signal: 'exporter failure' ].
			  self exportUnchecked: spans ]
]

{ #category : 'accessing' }
OTFailingSpanExporter >> forceFlush [

	self isShutdown ifTrue: [ ^ false ].
	(self shouldFailOperationNamed: 'forceFlush') ifTrue: [ Error signal: 'exporter failure' ].
	^ super forceFlush
]

{ #category : 'accessing' }
OTFailingSpanExporter >> operationsToFail: aCollection [

	self class operationsToFailByExporter at: self put: (aCollection ifNil: [ Set new ] ifNotNil: [ aCollection asSet ]).
	self
]

{ #category : 'testing' }
OTFailingSpanExporter >> shouldFailOperationNamed: aString [

	^ (self class operationsToFailByExporter at: self ifAbsent: [ Set new ]) includes: aString
]

{ #category : 'accessing' }
OTFailingSpanExporter >> shutdown [

	self beginShutdown ifFalse: [ ^ false ].
	(self shouldFailOperationNamed: 'shutdown') ifTrue: [ Error signal: 'exporter failure' ].
	^ self withExportLockDo: [
			  self markShutdown.
			  true ]
]
