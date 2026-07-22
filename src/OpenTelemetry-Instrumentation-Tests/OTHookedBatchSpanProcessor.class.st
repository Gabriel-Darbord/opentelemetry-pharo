Class {
	#name : 'OTHookedBatchSpanProcessor',
	#superclass : 'OTBatchSpanProcessor',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'private' }
OTHookedBatchSpanProcessor class >> onEndEnteredByProcessor [

	^ OTClassStateStore valueAt: #otOnEndEnteredByProcessor forClass: self ifAbsent: [
			  | values |
			  values := WeakIdentityKeyDictionary new.
			  OTClassStateStore valueAt: #otOnEndEnteredByProcessor forClass: self put: values.
			  values ]
]

{ #category : 'private' }
OTHookedBatchSpanProcessor class >> onEndReleaseByProcessor [

	^ OTClassStateStore valueAt: #otOnEndReleaseByProcessor forClass: self ifAbsent: [
			  | values |
			  values := WeakIdentityKeyDictionary new.
			  OTClassStateStore valueAt: #otOnEndReleaseByProcessor forClass: self put: values.
			  values ]
]

{ #category : 'control' }
OTHookedBatchSpanProcessor >> allowOnEndToContinue [

	(self class onEndReleaseByProcessor at: self) signal.
	self
]

{ #category : 'private - hooks' }
OTHookedBatchSpanProcessor >> beforeOnEndEnqueueingSnapshot: aSpanSnapshot [

	(self class onEndEnteredByProcessor at: self) signal.
	(self class onEndReleaseByProcessor at: self) wait
]

{ #category : 'initialization' }
OTHookedBatchSpanProcessor >> initialize [

	super initialize.
	self class onEndEnteredByProcessor at: self put: Semaphore new.
	self class onEndReleaseByProcessor at: self put: Semaphore new
]

{ #category : 'control' }
OTHookedBatchSpanProcessor >> waitForOnEndHookTimeoutMillis: anInteger [

	^ (self class onEndEnteredByProcessor at: self) waitTimeoutMilliseconds: anInteger
]
