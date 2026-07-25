Class {
	#name : 'OTLeanMethodProxyInstrumentation',
	#superclass : 'OTMethodProxyInstrumentation',
	#category : 'OpenTelemetry-Instrumentation-MethodProxy',
	#package : 'OpenTelemetry-Instrumentation-MethodProxy'
}

{ #category : 'testing' }
OTLeanMethodProxyInstrumentation class >> hasAbortedHook [

	| abortedImplementor unwindImplementor |
	abortedImplementor := self classSide whichClassIncludesSelector: #afterAbortedExecutionWithReceiver:arguments:.
	((abortedImplementor == OTLeanMethodProxyInstrumentation class or: [ abortedImplementor == OTMethodProxyInstrumentation class ])
		 not and: [ abortedImplementor notNil ]) ifTrue: [ ^ true ].
	unwindImplementor := self classSide whichClassIncludesSelector: #aboutToReturnWithReceiver:arguments:.
	^ unwindImplementor notNil and: [
		  (unwindImplementor == OTLeanMethodProxyInstrumentation class or: [ unwindImplementor == OTMethodProxyInstrumentation class ])
			  not ]
]

{ #category : 'testing' }
OTLeanMethodProxyInstrumentation class >> hasAfterHook [

	| implementor |
	implementor := self classSide whichClassIncludesSelector: #afterExecutionWithReceiver:arguments:returnValue:.
	^ implementor notNil and: [
		  (implementor == OTLeanMethodProxyInstrumentation class or: [ implementor == OTMethodProxyInstrumentation class ]) not ]
]

{ #category : 'testing' }
OTLeanMethodProxyInstrumentation class >> hasBeforeHook [

	| implementor |
	implementor := self classSide whichClassIncludesSelector: #beforeExecutionWithReceiver:arguments:.
	^ implementor notNil and: [
		  (implementor == OTLeanMethodProxyInstrumentation class or: [ implementor == OTMethodProxyInstrumentation class ]) not ]
]

{ #category : 'configuring' }
OTLeanMethodProxyInstrumentation class >> installer [

	^ OTLeanMethodProxyInstaller
]

{ #category : 'testing' }
OTLeanMethodProxyInstrumentation class >> isAbstract [

	^ self == OTLeanMethodProxyInstrumentation
]

{ #category : 'configuring' }
OTLeanMethodProxyInstrumentation class >> methodProxyClass [

	self usesAfterHook ifTrue: [
			^ self usesBeforeHook
				  ifTrue: [ MpMethodProxy ]
				  ifFalse: [ OTMethodProxyAfterProxy ] ].
	^ self usesBeforeHook
		  ifTrue: [ OTMethodProxyBeforeProxy ]
		  ifFalse: [ OTMethodProxyPassThroughProxy ]
]

{ #category : 'configuring' }
OTLeanMethodProxyInstrumentation class >> usesAbortedHook [

	^ self hasAbortedHook
]

{ #category : 'configuring' }
OTLeanMethodProxyInstrumentation class >> usesAfterHook [

	^ self hasAfterHook
]

{ #category : 'configuring' }
OTLeanMethodProxyInstrumentation class >> usesBeforeHook [

	^ self hasBeforeHook
]
