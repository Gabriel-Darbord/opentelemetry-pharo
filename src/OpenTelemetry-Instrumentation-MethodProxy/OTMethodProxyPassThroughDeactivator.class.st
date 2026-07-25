Class {
	#name : 'OTMethodProxyPassThroughDeactivator',
	#superclass : 'MpDeactivator',
	#category : 'OpenTelemetry-Instrumentation-MethodProxy',
	#package : 'OpenTelemetry-Instrumentation-MethodProxy'
}

{ #category : 'evaluating' }
OTMethodProxyPassThroughDeactivator >> value [
	"Execution handler for the slow path. An exception or a non local return happened during proxy execution"

	| trapContext |
	thisProcess shiftLevelUp.
	trapContext := thisContext.
	[
		trapContext := trapContext findNextUnwindContextUpTo: nil.
		trapContext method hasPragmaNamed: #trap ] whileFalse.

	handler aboutToReturnWithReceiver: trapContext receiver arguments: trapContext arguments.
	thisProcess shiftLevelDown.

	"Mark execution as complete to avoid double execution of the handler."
	trapContext tempAt: trapContext method numArgs + 2 put: true
]
