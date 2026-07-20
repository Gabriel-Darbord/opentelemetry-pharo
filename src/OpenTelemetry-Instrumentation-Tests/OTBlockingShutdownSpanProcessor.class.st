Class {
	#name : 'OTBlockingShutdownSpanProcessor',
	#superclass : 'OTSpanProcessor',
	#instVars : [
		'shutdownEntered',
		'shutdownRelease',
		'shutdownCount'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'control' }
OTBlockingShutdownSpanProcessor >> allowShutdown [

	shutdownRelease signal.
	self
]

{ #category : 'accessing' }
OTBlockingShutdownSpanProcessor >> forceFlush [

	self isShutdown ifTrue: [ ^ false ].
	^ true
]

{ #category : 'initialization' }
OTBlockingShutdownSpanProcessor >> initialize [

	super initialize.
	shutdownEntered := Semaphore new.
	shutdownRelease := Semaphore new.
	shutdownCount := 0
]

{ #category : 'processing' }
OTBlockingShutdownSpanProcessor >> process: aSpan [

	^ true
]

{ #category : 'accessing' }
OTBlockingShutdownSpanProcessor >> shutdown [

	self isShutdown ifTrue: [ ^ false ].
	shutdownEntered signal.
	shutdownRelease wait.
	shutdownCount := shutdownCount + 1.
	self markShutdown.
	^ true
]

{ #category : 'accessing' }
OTBlockingShutdownSpanProcessor >> shutdownCount [

	^ shutdownCount ifNil: [ 0 ]
]

{ #category : 'control' }
OTBlockingShutdownSpanProcessor >> waitForShutdownTimeoutMillis: anInteger [

	^ (shutdownEntered waitTimeoutMilliseconds: anInteger) not
]
