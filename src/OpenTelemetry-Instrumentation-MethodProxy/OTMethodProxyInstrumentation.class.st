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

{ #category : 'configuring' }
OTMethodProxyInstrumentation class >> installer [

	^ OTMethodProxyInstaller
]

{ #category : 'testing' }
OTMethodProxyInstrumentation class >> isAbstract [

	^ self == OTMethodProxyInstrumentation
]
