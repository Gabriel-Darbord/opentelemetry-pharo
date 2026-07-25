Class {
	#name : 'OTLeanMethodProxyCombinedTestInstrumentation',
	#superclass : 'OTLeanMethodProxyInstrumentation',
	#category : 'OpenTelemetry-Instrumentation-MethodProxy-Tests',
	#package : 'OpenTelemetry-Instrumentation-MethodProxy-Tests'
}

{ #category : 'evaluating' }
OTLeanMethodProxyCombinedTestInstrumentation class >> afterExecutionWithReceiver: receiver arguments: arguments returnValue: returnValue [

	OTClassStateStore valueAt: #capturedValue forClass: self put: (returnValue ifNil: [ #nil ]).
	^ returnValue
]

{ #category : 'evaluating' }
OTLeanMethodProxyCombinedTestInstrumentation class >> beforeExecutionWithReceiver: receiver arguments: arguments [

	OTClassStateStore valueAt: #capturedReceiver forClass: self put: receiver.
	OTClassStateStore valueAt: #capturedArguments forClass: self put: arguments
]

{ #category : 'accessing' }
OTLeanMethodProxyCombinedTestInstrumentation class >> capturedArguments [

	^ OTClassStateStore valueAt: #capturedArguments forClass: self ifAbsent: [ nil ]
]

{ #category : 'accessing' }
OTLeanMethodProxyCombinedTestInstrumentation class >> capturedReceiver [

	^ OTClassStateStore valueAt: #capturedReceiver forClass: self ifAbsent: [ nil ]
]

{ #category : 'accessing' }
OTLeanMethodProxyCombinedTestInstrumentation class >> capturedValue [

	^ OTClassStateStore valueAt: #capturedValue forClass: self ifAbsent: [ nil ]
]

{ #category : 'matching' }
OTLeanMethodProxyCombinedTestInstrumentation class >> classMatcher [

	^ OTMatcher name: #OTTestTarget
]

{ #category : 'configuring' }
OTLeanMethodProxyCombinedTestInstrumentation class >> configure: installer [

	self reset
]

{ #category : 'matching' }
OTLeanMethodProxyCombinedTestInstrumentation class >> methodMatcher [

	^ OTMatcher any
]

{ #category : 'matching' }
OTLeanMethodProxyCombinedTestInstrumentation class >> packageMatcher [

	^ OTMatcher name: #'OpenTelemetry-Instrumentation-Tests'
]

{ #category : 'class initialization' }
OTLeanMethodProxyCombinedTestInstrumentation class >> reset [

	super reset.
	OTClassStateStore removeValueAt: #capturedReceiver forClass: self ifAbsent: [ ].
	OTClassStateStore removeValueAt: #capturedArguments forClass: self ifAbsent: [ ].
	OTClassStateStore removeValueAt: #capturedValue forClass: self ifAbsent: [ ]
]
