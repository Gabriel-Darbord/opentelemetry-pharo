Class {
	#name : 'OTMethodProxyAbortedOnlyTestInstrumentation',
	#superclass : 'OTLeanMethodProxyInstrumentation',
	#category : 'OpenTelemetry-Instrumentation-MethodProxy-Tests',
	#package : 'OpenTelemetry-Instrumentation-MethodProxy-Tests'
}

{ #category : 'evaluating' }
OTMethodProxyAbortedOnlyTestInstrumentation class >> afterAbortedExecutionWithReceiver: receiver arguments: arguments [

	OTClassStateStore valueAt: #didAbort forClass: self put: true.
	^ nil
]

{ #category : 'matching' }
OTMethodProxyAbortedOnlyTestInstrumentation class >> classMatcher [

	^ OTMatcher name: #OTTestTarget
]

{ #category : 'configuring' }
OTMethodProxyAbortedOnlyTestInstrumentation class >> configure: installer [

	self reset
]

{ #category : 'accessing' }
OTMethodProxyAbortedOnlyTestInstrumentation class >> didAbort [

	^ OTClassStateStore valueAt: #didAbort forClass: self ifAbsent: [ false ]
]

{ #category : 'matching' }
OTMethodProxyAbortedOnlyTestInstrumentation class >> methodMatcher [

	^ OTMatcher any
]

{ #category : 'matching' }
OTMethodProxyAbortedOnlyTestInstrumentation class >> packageMatcher [

	^ OTMatcher name: #'OpenTelemetry-Instrumentation-Tests'
]

{ #category : 'class initialization' }
OTMethodProxyAbortedOnlyTestInstrumentation class >> reset [

	super reset.
	OTClassStateStore removeValueAt: #didAbort forClass: self ifAbsent: [ ]
]
