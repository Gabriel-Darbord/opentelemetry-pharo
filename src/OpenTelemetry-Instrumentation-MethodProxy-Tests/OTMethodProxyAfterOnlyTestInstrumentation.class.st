Class {
	#name : 'OTMethodProxyAfterOnlyTestInstrumentation',
	#superclass : 'OTLeanMethodProxyInstrumentation',
	#category : 'OpenTelemetry-Instrumentation-MethodProxy-Tests',
	#package : 'OpenTelemetry-Instrumentation-MethodProxy-Tests'
}

{ #category : 'evaluating' }
OTMethodProxyAfterOnlyTestInstrumentation class >> afterExecutionWithReceiver: receiver arguments: arguments returnValue: returnValue [

	OTClassStateStore valueAt: #capturedValue forClass: self put: (returnValue ifNil: [ #nil ]).
	^ returnValue
]

{ #category : 'accessing' }
OTMethodProxyAfterOnlyTestInstrumentation class >> capturedValue [

	^ OTClassStateStore valueAt: #capturedValue forClass: self ifAbsent: [ nil ]
]

{ #category : 'matching' }
OTMethodProxyAfterOnlyTestInstrumentation class >> classMatcher [

	^ OTMatcher name: #OTTestTarget
]

{ #category : 'configuring' }
OTMethodProxyAfterOnlyTestInstrumentation class >> configure: installer [

	self reset
]

{ #category : 'matching' }
OTMethodProxyAfterOnlyTestInstrumentation class >> methodMatcher [

	^ OTMatcher any
]

{ #category : 'matching' }
OTMethodProxyAfterOnlyTestInstrumentation class >> packageMatcher [

	^ OTMatcher name: #'OpenTelemetry-Instrumentation-Tests'
]

{ #category : 'class initialization' }
OTMethodProxyAfterOnlyTestInstrumentation class >> reset [

	super reset.
	OTClassStateStore removeValueAt: #capturedValue forClass: self ifAbsent: [ ]
]
