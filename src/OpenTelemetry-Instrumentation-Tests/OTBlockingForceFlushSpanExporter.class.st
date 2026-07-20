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
	forceFlushEntered signal.
	forceFlushRelease wait.
	^ super forceFlush
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
