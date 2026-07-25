Class {
	#name : 'OTMethodProxyBeforeOnlyTestInstrumentation',
	#superclass : 'OTLeanMethodProxyInstrumentation',
	#category : 'OpenTelemetry-Instrumentation-MethodProxy-Tests',
	#package : 'OpenTelemetry-Instrumentation-MethodProxy-Tests'
}

{ #category : 'evaluating' }
OTMethodProxyBeforeOnlyTestInstrumentation class >> beforeExecutionWithReceiver: receiver arguments: arguments [

	OTClassStateStore valueAt: #capturedReceiver forClass: self put: receiver.
	OTClassStateStore valueAt: #capturedArguments forClass: self put: arguments
]

{ #category : 'accessing' }
OTMethodProxyBeforeOnlyTestInstrumentation class >> capturedArguments [

	^ OTClassStateStore valueAt: #capturedArguments forClass: self ifAbsent: [ nil ]
]

{ #category : 'accessing' }
OTMethodProxyBeforeOnlyTestInstrumentation class >> capturedReceiver [

	^ OTClassStateStore valueAt: #capturedReceiver forClass: self ifAbsent: [ nil ]
]

{ #category : 'matching' }
OTMethodProxyBeforeOnlyTestInstrumentation class >> classMatcher [

	^ OTMatcher name: #OTTestTarget
]

{ #category : 'configuring' }
OTMethodProxyBeforeOnlyTestInstrumentation class >> configure: installer [

	self reset
]

{ #category : 'matching' }
OTMethodProxyBeforeOnlyTestInstrumentation class >> methodMatcher [

	^ OTMatcher any
]

{ #category : 'matching' }
OTMethodProxyBeforeOnlyTestInstrumentation class >> packageMatcher [

	^ OTMatcher name: #'OpenTelemetry-Instrumentation-Tests'
]

{ #category : 'class initialization' }
OTMethodProxyBeforeOnlyTestInstrumentation class >> reset [

	super reset.
	OTClassStateStore removeValueAt: #capturedReceiver forClass: self ifAbsent: [ ].
	OTClassStateStore removeValueAt: #capturedArguments forClass: self ifAbsent: [ ]
]
