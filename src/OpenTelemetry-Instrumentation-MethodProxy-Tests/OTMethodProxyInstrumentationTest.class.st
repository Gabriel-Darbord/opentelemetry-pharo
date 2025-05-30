Class {
	#name : 'OTMethodProxyInstrumentationTest',
	#superclass : 'OTAbstractInstrumentationTest',
	#category : 'OpenTelemetry-Instrumentation-MethodProxy-Tests',
	#package : 'OpenTelemetry-Instrumentation-MethodProxy-Tests'
}

{ #category : 'accessing' }
OTMethodProxyInstrumentationTest >> instrumentation [

	^ OTMethodProxyTestInstrumentation
]

{ #category : 'tests' }
OTMethodProxyInstrumentationTest >> testEnsureHasRunOnExit [
	"TODO: implement OTMetaLinkInstrumentation class>>#run: for MethodProxies.
	Test is commented instead of skipped because it can lead to issues with proxies."

	"self deny: self instrumentation hasRunBefore.
	self should: [ target fail ] raise: Error.
	self assert: self instrumentation hasRunAfter"
]

{ #category : 'tests' }
OTMethodProxyInstrumentationTest >> testHasRun [

	self deny: self instrumentation hasRunBefore.
	self deny: self instrumentation hasRunAfter.
	target answer.
	self assert: self instrumentation hasRunBefore.
	self assert: self instrumentation hasRunAfter
]

{ #category : 'tests' }
OTMethodProxyInstrumentationTest >> testIsInstalled [

	| method literals instrumentation |
	method := OTTestTarget >> #answer.
	literals := method literals.
	self assert: literals size >= 8.
	instrumentation := method literalsAt: 8.
	self assert: instrumentation identicalTo: self instrumentation
]

{ #category : 'tests' }
OTMethodProxyInstrumentationTest >> testPassException [
	"The instrumentation should let the exception happen normally."

	self should: [ target fail ] raise: Error
]

{ #category : 'tests' }
OTMethodProxyInstrumentationTest >> testSmoke [
	"Instrumentation is successfully installed and uninstalled."
]
