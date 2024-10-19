Class {
	#name : 'OTMethodProxyInstrumentation',
	#superclass : 'OTInstrumentation',
	#category : 'OpenTelemetry-Instrumentation',
	#package : 'OpenTelemetry-Instrumentation'
}

{ #category : 'evaluating' }
OTMethodProxyInstrumentation class >> aboutToReturnWithReceiver: receiver arguments: arguments [
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
