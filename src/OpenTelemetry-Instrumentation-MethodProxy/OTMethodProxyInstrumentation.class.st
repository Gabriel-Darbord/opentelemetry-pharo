"
I am the base class for MethodProxy-backed instrumentations.

I decide which proxy shape is needed from the hooks implemented by a concrete instrumentation, and I define the default before, after, and abnormal-exit lifecycle hooks used by that backend.
"
Class {
	#name : 'OTMethodProxyInstrumentation',
	#superclass : 'OTInstrumentation',
	#category : 'OpenTelemetry-Instrumentation-MethodProxy',
	#package : 'OpenTelemetry-Instrumentation-MethodProxy'
}

{ #category : 'evaluating' }
OTMethodProxyInstrumentation class >> aboutToReturnWithReceiver: receiver arguments: arguments [
	"MethodProxy invokes this hook during stack unwind for abnormal exits and
	non-local returns. Delegate through a dedicated abnormal-exit hook so
	subclasses can distinguish unwind handling from normal returns."

	^ self afterAbortedExecutionWithReceiver: receiver arguments: arguments
]

{ #category : 'evaluating' }
OTMethodProxyInstrumentation class >> afterAbortedExecutionWithReceiver: receiver arguments: arguments [
	"By default, preserve the legacy behavior and run the regular after-hook
	with a nil return value."

	^ self afterExecutionWithReceiver: receiver arguments: arguments returnValue: nil
]

{ #category : 'evaluating' }
OTMethodProxyInstrumentation class >> afterExecutionWithReceiver: receiver arguments: arguments returnValue: returnValue [
	"This method is executed AFTER the instrumented method.
	The return value of the instrumented method is the return value of this method."

	^ returnValue
]

{ #category : 'evaluating' }
OTMethodProxyInstrumentation class >> beforeExecutionWithReceiver: receiver arguments: arguments [
	"This method is executed BEFORE the instrumented method."

	
]

{ #category : 'testing' }
OTMethodProxyInstrumentation class >> hasAbortedHook [

	| abortedImplementor unwindImplementor |
	abortedImplementor := self classSide whichClassIncludesSelector: #afterAbortedExecutionWithReceiver:arguments:.
	(abortedImplementor notNil and: [ abortedImplementor ~= OTMethodProxyInstrumentation class ]) ifTrue: [ ^ true ].
	unwindImplementor := self classSide whichClassIncludesSelector: #aboutToReturnWithReceiver:arguments:.
	^ unwindImplementor notNil and: [ unwindImplementor ~= OTMethodProxyInstrumentation class ]
]

{ #category : 'testing' }
OTMethodProxyInstrumentation class >> hasAfterHook [

	| implementor |
	implementor := self classSide whichClassIncludesSelector: #afterExecutionWithReceiver:arguments:returnValue:.
	^ implementor notNil and: [ implementor ~= OTMethodProxyInstrumentation class ]
]

{ #category : 'testing' }
OTMethodProxyInstrumentation class >> hasBeforeHook [

	| implementor |
	implementor := self classSide whichClassIncludesSelector: #beforeExecutionWithReceiver:arguments:.
	^ implementor notNil and: [ implementor ~= OTMethodProxyInstrumentation class ]
]

{ #category : 'configuring' }
OTMethodProxyInstrumentation class >> installer [

	^ OTMethodProxyInstaller
]

{ #category : 'testing' }
OTMethodProxyInstrumentation class >> isAbstract [

	^ self == OTMethodProxyInstrumentation
]

{ #category : 'configuring' }
OTMethodProxyInstrumentation class >> methodProxyClass [

	self usesAfterHook ifTrue: [
			^ self usesBeforeHook
				  ifTrue: [ MpMethodProxy ]
				  ifFalse: [ OTMethodProxyAfter ] ].
	^ self usesBeforeHook
		  ifTrue: [ OTMethodProxyBefore ]
		  ifFalse: [ OTMethodProxyPassThrough ]
]

{ #category : 'configuring' }
OTMethodProxyInstrumentation class >> usesAbortedHook [

	^ self hasAbortedHook
]

{ #category : 'configuring' }
OTMethodProxyInstrumentation class >> usesAfterHook [

	^ self hasAfterHook
]

{ #category : 'configuring' }
OTMethodProxyInstrumentation class >> usesBeforeHook [

	^ self hasBeforeHook
]
