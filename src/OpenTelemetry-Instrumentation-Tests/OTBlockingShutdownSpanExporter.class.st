Class {
	#name : 'OTBlockingShutdownSpanExporter',
	#superclass : 'OTRecordingSpanExporter',
	#instVars : [
		'shutdownEntered',
		'shutdownRelease'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'control' }
OTBlockingShutdownSpanExporter >> allowShutdown [

	shutdownRelease signal.
	self
]

{ #category : 'initialization' }
OTBlockingShutdownSpanExporter >> initialize [

	super initialize.
	shutdownEntered := Semaphore new.
	shutdownRelease := Semaphore new
]

{ #category : 'accessing' }
OTBlockingShutdownSpanExporter >> shutdown [

	self beginShutdown ifFalse: [ ^ false ].
	shutdownEntered signal.
	shutdownRelease wait.
	shutdownCount := self shutdownCount + 1.
	self markShutdown.
	^ true
]

{ #category : 'control' }
OTBlockingShutdownSpanExporter >> waitForShutdownTimeoutMillis: anInteger [

	^ (shutdownEntered waitTimeoutMilliseconds: anInteger) not
]
