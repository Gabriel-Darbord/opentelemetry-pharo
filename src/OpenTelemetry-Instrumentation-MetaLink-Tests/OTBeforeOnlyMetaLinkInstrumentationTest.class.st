Class {
	#name : 'OTBeforeOnlyMetaLinkInstrumentationTest',
	#superclass : 'OTAbstractInstrumentationTest',
	#category : 'OpenTelemetry-Instrumentation-MetaLink-Tests',
	#package : 'OpenTelemetry-Instrumentation-MetaLink-Tests'
}

{ #category : 'accessing' }
OTBeforeOnlyMetaLinkInstrumentationTest >> instrumentation [

	^ OTBeforeOnlyMetaLinkTestInstrumentation
]

{ #category : 'tests' }
OTBeforeOnlyMetaLinkInstrumentationTest >> testInstallsBeforeHookOnly [

	| links |
	links := (OTTestTarget >> #answer) ast links select: [ :link | link metaObject == self instrumentation ].
	self assert: links size equals: 1.
	self assert: links first control equals: #before.
	self assert: links first selector equals: #runBefore:.
	self deny: self instrumentation hasRunOnExit
]

{ #category : 'tests' }
OTBeforeOnlyMetaLinkInstrumentationTest >> testRunsOnlyOnEnter [

	self deny: self instrumentation hasRunOnEnter.
	self deny: self instrumentation hasRunOnExit.
	target answer.
	self assert: self instrumentation hasRunOnEnter.
	self deny: self instrumentation hasRunOnExit
]
