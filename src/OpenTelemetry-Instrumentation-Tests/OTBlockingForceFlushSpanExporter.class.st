Class {
	#name : 'OTBlockingForceFlushSpanExporter',
	#superclass : 'OTRecordingSpanExporter',
	#instVars : [
		'forceFlushEntered',
		'forceFlushRelease'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'control' }
OTBlockingForceFlushSpanExporter >> allowForceFlush [

	forceFlushRelease signal.
	self
]

{ #category : 'accessing' }
OTBlockingForceFlushSpanExporter >> forceFlush [

	self isShutdown ifTrue: [ ^ false ].
	^ self withExportLockDo: [
			  self isShutdown
				  ifTrue: [ false ]
				  ifFalse: [
						  forceFlushEntered signal.
						  forceFlushRelease wait.
						  forceFlushCount := self forceFlushCount + 1.
						  true ] ]
]

{ #category : 'initialization' }
OTBlockingForceFlushSpanExporter >> initialize [

	super initialize.
	forceFlushEntered := Semaphore new.
	forceFlushRelease := Semaphore new
]

{ #category : 'control' }
OTBlockingForceFlushSpanExporter >> waitForForceFlushTimeoutMillis: anInteger [

	^ (forceFlushEntered waitTimeoutMilliseconds: anInteger) not
]
