Class {
	#name : 'OTFailingSpanProcessor',
	#superclass : 'OTRecordingSpanProcessor',
	#instVars : [
		'operationsToFail',
		'forceFlushCount',
		'shutdownCount'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'instance creation' }
OTFailingSpanProcessor class >> failingOperations: aCollection [

	^ self new
		  operationsToFail: aCollection;
		  yourself
]

{ #category : 'accessing' }
OTFailingSpanProcessor >> forceFlush [

	self isShutdown ifTrue: [ ^ false ].
	(self shouldFailOperationNamed: 'forceFlush') ifTrue: [ Error signal: 'processor failure' ].
	forceFlushCount := self forceFlushCount + 1.
	^ true
]

{ #category : 'accessing' }
OTFailingSpanProcessor >> forceFlushCount [

	^ forceFlushCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
OTFailingSpanProcessor >> onEnd: aSpan [

	(self shouldFailOperationNamed: 'onEnd') ifTrue: [ Error signal: 'processor failure' ].
	^ super onEnd: aSpan
]

{ #category : 'accessing' }
OTFailingSpanProcessor >> onEnding: aSpan [

	(self shouldFailOperationNamed: 'onEnding') ifTrue: [ Error signal: 'processor failure' ].
	^ super onEnding: aSpan
]

{ #category : 'accessing' }
OTFailingSpanProcessor >> onStart: aSpan parentContext: aContext [

	(self shouldFailOperationNamed: 'onStart') ifTrue: [ Error signal: 'processor failure' ].
	^ super onStart: aSpan parentContext: aContext
]

{ #category : 'accessing' }
OTFailingSpanProcessor >> operationsToFail: aCollection [

	operationsToFail := aCollection ifNil: [ Set new ] ifNotNil: [ aCollection asSet ]
]

{ #category : 'testing' }
OTFailingSpanProcessor >> shouldFailOperationNamed: aString [

	^ operationsToFail ifNil: [ false ] ifNotNil: [ operationsToFail includes: aString ]
]

{ #category : 'accessing' }
OTFailingSpanProcessor >> shutdown [

	self isShutdown ifTrue: [ ^ false ].
	(self shouldFailOperationNamed: 'shutdown') ifTrue: [ Error signal: 'processor failure' ].
	shutdownCount := self shutdownCount + 1.
	self markShutdown.
	^ true
]

{ #category : 'accessing' }
OTFailingSpanProcessor >> shutdownCount [

	^ shutdownCount ifNil: [ 0 ]
]
