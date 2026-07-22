Class {
	#name : 'OTHookedSimpleSpanProcessor',
	#superclass : 'OTSimpleSpanProcessor',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'private' }
OTHookedSimpleSpanProcessor class >> onEndEnteredByProcessor [

	^ OTClassStateStore valueAt: #otOnEndEnteredByProcessor forClass: self ifAbsent: [
			  | values |
			  values := WeakIdentityKeyDictionary new.
			  OTClassStateStore valueAt: #otOnEndEnteredByProcessor forClass: self put: values.
			  values ]
]

{ #category : 'private' }
OTHookedSimpleSpanProcessor class >> onEndReleaseByProcessor [

	^ OTClassStateStore valueAt: #otOnEndReleaseByProcessor forClass: self ifAbsent: [
			  | values |
			  values := WeakIdentityKeyDictionary new.
			  OTClassStateStore valueAt: #otOnEndReleaseByProcessor forClass: self put: values.
			  values ]
]

{ #category : 'control' }
OTHookedSimpleSpanProcessor >> allowOnEndToContinue [

	(self class onEndReleaseByProcessor at: self) signal.
	self
]

{ #category : 'private - hooks' }
OTHookedSimpleSpanProcessor >> beforeOnEndExportingSnapshot: aSpanSnapshot [

	(self class onEndEnteredByProcessor at: self) signal.
	(self class onEndReleaseByProcessor at: self) wait
]

{ #category : 'initialization' }
OTHookedSimpleSpanProcessor >> initialize [

	super initialize.
	self class onEndEnteredByProcessor at: self put: Semaphore new.
	self class onEndReleaseByProcessor at: self put: Semaphore new
]

{ #category : 'control' }
OTHookedSimpleSpanProcessor >> waitForOnEndHookTimeoutMillis: anInteger [

	^ (self class onEndEnteredByProcessor at: self) waitTimeoutMilliseconds: anInteger
]
