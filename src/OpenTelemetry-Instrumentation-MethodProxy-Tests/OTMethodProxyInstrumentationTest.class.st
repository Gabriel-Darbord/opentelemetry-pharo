Class {
	#name : 'OTMethodProxyInstrumentationTest',
	#superclass : 'OTAbstractInstrumentationTest',
	#category : 'OpenTelemetry-Instrumentation-MethodProxy-Tests',
	#package : 'OpenTelemetry-Instrumentation-MethodProxy-Tests'
}

{ #category : 'asserting' }
OTMethodProxyInstrumentationTest >> assertTargetHasNoMethodProxyArtifacts [

	self deny: (OTTestTarget methods anySatisfy: [ :method | method selector isKindOf: MpHiddenSelector ]).
	#( answer suppressedAnswer indirectAnswer fail handledFail ) do: [ :selector |
			| method |
			method := OTTestTarget >> selector.
			self deny: (OTMethodProxyInstaller isMethodProxyTrap: method) ].
	self assert: target answer equals: 42
]

{ #category : 'accessing' }
OTMethodProxyInstrumentationTest >> instrumentation [

	^ OTMethodProxyTestInstrumentation
]

{ #category : 'tests' }
OTMethodProxyInstrumentationTest >> testEnsureHasRunOnExit [

	self deny: self instrumentation hasRunBefore.
	self should: [ target fail ] raise: Error.
	self assert: self instrumentation hasRunAfter
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
OTMethodProxyInstrumentationTest >> testRepeatedInstallDoesNotAccumulateProxyArtifacts [

	self instrumentation install.
	self instrumentation uninstall.
	self assertTargetHasNoMethodProxyArtifacts
]

{ #category : 'tests' }
OTMethodProxyInstrumentationTest >> testSmoke [
	"Instrumentation is successfully installed and uninstalled."

	
]

{ #category : 'tests' }
OTMethodProxyInstrumentationTest >> testUninstallRestoresTargetMethodDictionary [

	self instrumentation uninstall.
	self assertTargetHasNoMethodProxyArtifacts
]
