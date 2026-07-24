Class {
	#name : 'OTSpanInstrumentationTest',
	#superclass : 'OTAbstractInstrumentationTest',
	#instVars : [
		'currentProcessor'
	],
	#category : 'OpenTelemetry-Instrumentation-MetaLink-Tests',
	#package : 'OpenTelemetry-Instrumentation-MetaLink-Tests'
}

{ #category : 'accessing' }
OTSpanInstrumentationTest >> instrumentation [

	^ OTSpanTestInstrumentation
]

{ #category : 'running' }
OTSpanInstrumentationTest >> setUp [
	"Remember the configured processor."

	super setUp.
	currentProcessor := OTSpanProcessor current.
	OTBatchSpanProcessor new beCurrent
]

{ #category : 'running' }
OTSpanInstrumentationTest >> tearDown [
	"Restore the configured processor."

	currentProcessor beCurrent.
	super tearDown
]

{ #category : 'tests' }
OTSpanInstrumentationTest >> testDefaultSpanKind [

	target answer.
	self assert: self instrumentation capturedSpan kind equals: OTSpan internal
]

{ #category : 'tests' }
OTSpanInstrumentationTest >> testDefaultSpanName [

	target answer.
	self assert: self instrumentation capturedSpan name equals: (OTTestTarget >> #answer) name
]

{ #category : 'tests' }
OTSpanInstrumentationTest >> testInstallsExceptionAwareAroundHook [

	| links |
	links := (OTTestTarget >> #answer) ast links select: [ :link | link metaObject == self instrumentation ].
	self assert: links size equals: 1.
	self assert: links first control equals: #instead.
	self assert: links first selector equals: #runWithEnterExitAndExceptionHandling:
]

{ #category : 'tests' }
OTSpanInstrumentationTest >> testRecordException [

	[
		| error span exceptionEvent |
		[ target fail ]
			on: Error
			do: [ :e | error := e ].
		span := self instrumentation capturedSpan.
		exceptionEvent := span events detect: [ :each | each name = 'exception' ].
		self assert: span status equals: OTSpan error.
		self assert: span statusDescription equals: error description.
		self assert: (exceptionEvent attributeAt: 'exception.message') equals: error messageText.
		self assert: (exceptionEvent attributeAt: 'exception.type') equals: error class name asString ]
]

{ #category : 'tests' }
OTSpanInstrumentationTest >> testSpanAttributes [
	"Attributes were created and populated on method enter and exit."

	| attributes |
	target answer.
	attributes := self instrumentation capturedSpan attributes.
	self assert: attributes isNotNil.
	self assert: (attributes includesKey: 'enter').
	self assert: (attributes at: 'enter') equals: #OK.
	self assert: (attributes includesKey: 'exit').
	self assert: (attributes at: 'exit') equals: #OK
]

{ #category : 'tests' }
OTSpanInstrumentationTest >> testSpanExists [

	self assert: self instrumentation capturedSpan isNil.
	target answer.
	self assert: self instrumentation capturedSpan class identicalTo: OTSpan
]

{ #category : 'tests' }
OTSpanInstrumentationTest >> testSpanLifetime [

	| span |
	target answer.
	span := self instrumentation capturedSpan.
	self assert: span startTime isNotNil.
	self assert: span endTime isNotNil.
	self assert: span startTime <= span endTime
]

{ #category : 'tests' }
OTSpanInstrumentationTest >> testSpanStatus [

	target answer.
	self assert: self instrumentation capturedSpan status equals: #OK
]

{ #category : 'tests' }
OTSpanInstrumentationTest >> testSpanSuppression [

	| span |
	target suppressedAnswer.
	span := self instrumentation capturedSpan.
	self assert: (span attributes includesKey: 'suppressed')
]
