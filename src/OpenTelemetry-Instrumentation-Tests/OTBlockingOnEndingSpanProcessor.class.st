Class {
	#name : 'OTBlockingOnEndingSpanProcessor',
	#superclass : 'OTSpanProcessor',
	#instVars : [
		'onEndingEntered',
		'onEndingRelease'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'control' }
OTBlockingOnEndingSpanProcessor >> allowOnEnding [

	onEndingRelease signal.
	self
]

{ #category : 'processing' }
OTBlockingOnEndingSpanProcessor >> forceFlush [

	self isShutdown ifTrue: [ ^ false ].
	^ true
]

{ #category : 'initialization' }
OTBlockingOnEndingSpanProcessor >> initialize [

	super initialize.
	onEndingEntered := Semaphore new.
	onEndingRelease := Semaphore new
]

{ #category : 'processing' }
OTBlockingOnEndingSpanProcessor >> onEnd: aSpan [

	^ true
]

{ #category : 'processing' }
OTBlockingOnEndingSpanProcessor >> onEnding: aSpan [

	onEndingEntered signal.
	onEndingRelease wait.
	aSpan attributeAt: 'processor.onEnding' put: true.
	^ true
]

{ #category : 'processing' }
OTBlockingOnEndingSpanProcessor >> shutdown [

	self isShutdown ifTrue: [ ^ false ].
	self markShutdown.
	^ true
]

{ #category : 'control' }
OTBlockingOnEndingSpanProcessor >> waitForOnEndingTimeoutMillis: anInteger [

	^ (onEndingEntered waitTimeoutMilliseconds: anInteger) not
]
