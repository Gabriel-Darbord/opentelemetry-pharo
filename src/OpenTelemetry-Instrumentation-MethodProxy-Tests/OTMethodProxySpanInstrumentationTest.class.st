Class {
	#name : 'OTMethodProxySpanInstrumentationTest',
	#superclass : 'OTAbstractInstrumentationTest',
	#instVars : [
		'currentProcessor'
	],
	#category : 'OpenTelemetry-Instrumentation-MethodProxy-Tests',
	#package : 'OpenTelemetry-Instrumentation-MethodProxy-Tests'
}

{ #category : 'accessing' }
OTMethodProxySpanInstrumentationTest >> instrumentation [

	^ OTMethodProxySpanTestInstrumentation
]

{ #category : 'running' }
OTMethodProxySpanInstrumentationTest >> setUp [

	super setUp.
	currentProcessor := OTSpanProcessor current.
	OTBatchSpanProcessor new beCurrent
]

{ #category : 'running' }
OTMethodProxySpanInstrumentationTest >> tearDown [

	currentProcessor beCurrent.
	super tearDown
]

{ #category : 'tests' }
OTMethodProxySpanInstrumentationTest >> testDefaultSpanKind [

	target answer.
	self assert: self instrumentation capturedSpan kind equals: OTSpan internal
]

{ #category : 'tests' }
OTMethodProxySpanInstrumentationTest >> testDefaultSpanName [

	target answer.
	self assert: self instrumentation capturedSpan name equals: (OTTestTarget >> #answer) name
]

{ #category : 'tests' }
OTMethodProxySpanInstrumentationTest >> testSpanAttributes [

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
OTMethodProxySpanInstrumentationTest >> testSpanEndsOnUnhandledExceptionWithoutMarkingSuccess [

	| span |
	self should: [ target fail ] raise: Error.
	span := self instrumentation capturedSpan.
	self assert: span startTime isNotNil.
	self assert: span endTime isNotNil.
	self deny: span status equals: #OK
]

{ #category : 'tests' }
OTMethodProxySpanInstrumentationTest >> testSpanExists [

	self assert: self instrumentation capturedSpan isNil.
	target answer.
	self assert: self instrumentation capturedSpan class identicalTo: OTSpan
]

{ #category : 'tests' }
OTMethodProxySpanInstrumentationTest >> testSpanLifetime [

	| span |
	target answer.
	span := self instrumentation capturedSpan.
	self assert: span startTime isNotNil.
	self assert: span endTime isNotNil.
	self assert: span startTime <= span endTime
]

{ #category : 'tests' }
OTMethodProxySpanInstrumentationTest >> testSpanStatus [

	target answer.
	self assert: self instrumentation capturedSpan status equals: #OK
]

{ #category : 'tests' }
OTMethodProxySpanInstrumentationTest >> testSpanSuppression [

	| span |
	target suppressedAnswer.
	span := self instrumentation capturedSpan.
	self assert: (span attributes includesKey: 'suppressed')
]
