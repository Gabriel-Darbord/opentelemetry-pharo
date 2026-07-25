Class {
	#name : 'OTMethodProxyHookSelectionTest',
	#superclass : 'TestCase',
	#instVars : [
		'target'
	],
	#category : 'OpenTelemetry-Instrumentation-MethodProxy-Tests',
	#package : 'OpenTelemetry-Instrumentation-MethodProxy-Tests'
}

{ #category : 'asserting' }
OTMethodProxyHookSelectionTest >> assertTrapFor: anInstrumentationClass selector: aSelector includesBefore: includesBefore includesAfter: includesAfter [

	self withInstrumentation: anInstrumentationClass do: [
			| source |
			source := (OTTestTarget >> aSelector) sourceCode.
			self assert: (source includesSubstring: 'beforeExecutionWithReceiver:') equals: includesBefore.
			self assert: (source includesSubstring: 'afterExecutionWithReceiver:') equals: includesAfter ]
]

{ #category : 'running' }
OTMethodProxyHookSelectionTest >> setUp [

	super setUp.
	target := OTTestTarget new
]

{ #category : 'tests' }
OTMethodProxyHookSelectionTest >> testAbortedOnlyInstrumentationUsesPassThrough [

	self assert: OTMethodProxyAbortedOnlyTestInstrumentation methodProxyClass identicalTo: OTMethodProxyPassThrough.
	self
		assertTrapFor: OTMethodProxyAbortedOnlyTestInstrumentation
		selector: #fail
		includesBefore: false
		includesAfter: false.
	self withInstrumentation: OTMethodProxyAbortedOnlyTestInstrumentation do: [
			self should: [ target fail ] raise: Error.
			self assert: OTMethodProxyAbortedOnlyTestInstrumentation didAbort ]
]

{ #category : 'tests' }
OTMethodProxyHookSelectionTest >> testAfterOnlyInstrumentationUsesAfter [

	self assert: OTMethodProxyAfterOnlyTestInstrumentation methodProxyClass identicalTo: OTMethodProxyAfter.
	self
		assertTrapFor: OTMethodProxyAfterOnlyTestInstrumentation
		selector: #answer
		includesBefore: false
		includesAfter: true.
	self withInstrumentation: OTMethodProxyAfterOnlyTestInstrumentation do: [
			self assert: target answer equals: 42.
			self assert: OTMethodProxyAfterOnlyTestInstrumentation capturedValue equals: 42 ]
]

{ #category : 'tests' }
OTMethodProxyHookSelectionTest >> testBeforeOnlyInstrumentationUsesBefore [

	self assert: OTMethodProxyBeforeOnlyTestInstrumentation methodProxyClass identicalTo: OTMethodProxyBefore.
	self
		assertTrapFor: OTMethodProxyBeforeOnlyTestInstrumentation
		selector: #answer
		includesBefore: true
		includesAfter: false.
	self withInstrumentation: OTMethodProxyBeforeOnlyTestInstrumentation do: [
			self assert: target answer equals: 42.
			self assert: OTMethodProxyBeforeOnlyTestInstrumentation capturedReceiver identicalTo: target.
			self assert: OTMethodProxyBeforeOnlyTestInstrumentation capturedArguments equals: #(  ) ]
]

{ #category : 'tests' }
OTMethodProxyHookSelectionTest >> testCombinedInstrumentationKeepsOriginalMethodProxy [

	self assert: OTMethodProxyTestInstrumentation methodProxyClass identicalTo: MpMethodProxy.
	self
		assertTrapFor: OTMethodProxyTestInstrumentation
		selector: #answer
		includesBefore: true
		includesAfter: true.
	self withInstrumentation: OTMethodProxyTestInstrumentation do: [
			self assert: target answer equals: 42.
			self assert: OTMethodProxyTestInstrumentation capturedReceiver identicalTo: target.
			self assert: OTMethodProxyTestInstrumentation capturedArguments equals: #(  ).
			self assert: OTMethodProxyTestInstrumentation capturedValue equals: 42 ]
]

{ #category : 'private' }
OTMethodProxyHookSelectionTest >> withInstrumentation: anInstrumentationClass do: aBlock [

	anInstrumentationClass install.
	^ [ aBlock value ] ensure: [ anInstrumentationClass uninstall ]
]
