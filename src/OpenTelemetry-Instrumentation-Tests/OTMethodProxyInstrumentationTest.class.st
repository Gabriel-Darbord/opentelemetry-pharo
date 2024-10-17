Class {
	#name : #OTMethodProxyInstrumentationTest,
	#superclass : #OTAbstractInstrumentationTest,
	#category : #'OpenTelemetry-Instrumentation-Tests'
}

{ #category : #accessing }
OTMethodProxyInstrumentationTest >> instrumentation [

	^ OTMethodProxyTestInstrumentation
]

{ #category : #tests }
OTMethodProxyInstrumentationTest >> testEnsureHasRunOnExit [

	self flag: #TODO. "implement OTMetaLinkInstrumentation class>>#run: for MethodProxies"
	self skip.
	self deny: self instrumentation hasRunBefore.
	self should: [ target fail ] raise: Error.
	self assert: self instrumentation hasRunAfter
]

{ #category : #tests }
OTMethodProxyInstrumentationTest >> testHasRun [

	self deny: self instrumentation hasRunBefore.
	self deny: self instrumentation hasRunAfter.
	target answer.
	self assert: self instrumentation hasRunBefore.
	self assert: self instrumentation hasRunAfter
]

{ #category : #tests }
OTMethodProxyInstrumentationTest >> testIsInstalled [

	| method |
	method := OTTestTarget >> #answer.
	self assert: method isMethodProxy.
	self assert: method handler identicalTo: self instrumentation
]

{ #category : #tests }
OTMethodProxyInstrumentationTest >> testPassException [
	"The instrumentation should let the exception happen normally."

	self should: [ target fail ] raise: Error
]

{ #category : #tests }
OTMethodProxyInstrumentationTest >> testSmoke [
	"Instrumentation is successfully installed and uninstalled."
]
