Class {
	#name : 'OTCurrentContextTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'running' }
OTCurrentContextTest >> tearDown [

	OpenTelemetry resetCurrentContext.
	super tearDown
]

{ #category : 'tests' }
OTCurrentContextTest >> testAttachAndDetachContextRestoresPreviousContext [

	| innerContext outerContext token |
	outerContext := OTContext new withBaggage: (OTBaggage builder
			                 putEntryNamed: 'scope' value: 'outer';
			                 build).
	innerContext := OTContext new withBaggage: (OTBaggage builder
			                 putEntryNamed: 'scope' value: 'inner';
			                 build).
	OpenTelemetry currentContext: outerContext.
	token := OpenTelemetry attachContext: innerContext.
	self assert: OpenTelemetry currentContext identicalTo: innerContext.
	self assert: (OpenTelemetry detachContext: token).
	self assert: OpenTelemetry currentContext identicalTo: outerContext
]

{ #category : 'tests' }
OTCurrentContextTest >> testCurrentContextIsProcessLocal [

	| childContext currentContext semaphore |
	currentContext := (OTContext new)
		withBaggage: ((OTBaggage builder)
			putEntryNamed: 'request.id' value: 'parent';
			build).
	OpenTelemetry currentContext: currentContext.
	semaphore := Semaphore new.
	[
	childContext := OpenTelemetry currentContext.
	semaphore signal ] fork.
	semaphore wait.
	self assert: OpenTelemetry currentContext identicalTo: currentContext.
	self assert: childContext isEmpty
]

{ #category : 'tests' }
OTCurrentContextTest >> testCurrentContextSetterIgnoresInvalidContextObject [

	| currentContext |
	currentContext := nil.
	self shouldnt: [ currentContext := OpenTelemetry currentContext: 42 ] raise: Error.
	self assert: currentContext class identicalTo: OTContext.
	self assert: currentContext isEmpty.
	self assert: OpenTelemetry currentContext isEmpty
]

{ #category : 'tests' }
OTCurrentContextTest >> testDetachContextReturnsFalseWhenDetachOrderIsWrong [

	| firstContext firstToken secondContext secondToken |
	firstContext := OTContext new withBaggage: (OTBaggage builder
			                 putEntryNamed: 'scope' value: 'first';
			                 build).
	secondContext := OTContext new withBaggage: (OTBaggage builder
			                  putEntryNamed: 'scope' value: 'second';
			                  build).
	firstToken := OpenTelemetry attachContext: firstContext.
	secondToken := OpenTelemetry attachContext: secondContext.
	self deny: (OpenTelemetry detachContext: firstToken).
	self assert: OpenTelemetry currentContext identicalTo: secondContext.
	self assert: (OpenTelemetry detachContext: secondToken).
	self assert: OpenTelemetry currentContext identicalTo: firstContext
]

{ #category : 'tests' }
OTCurrentContextTest >> testDetachContextReturnsFalseWhenUsedFromAnotherProcess [

	| childResult context semaphore token |
	context := OTContext new withBaggage: (OTBaggage builder
			            putEntryNamed: 'scope' value: 'parent';
			            build).
	token := OpenTelemetry attachContext: context.
	semaphore := Semaphore new.
	[
		childResult := OpenTelemetry detachContext: token.
		semaphore signal ] fork.
	semaphore wait.
	self deny: childResult.
	self assert: OpenTelemetry currentContext identicalTo: context
]

{ #category : 'tests' }
OTCurrentContextTest >> testEndedSpanCanStillBeActivatedWithUseSpan [

	| childSpan provider span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	span := tracer startSpanNamed: 'operation'.
	span end.
	OpenTelemetry useSpan: span during: [
			self assert: OpenTelemetry currentSpan identicalTo: span.
			self assert: OpenTelemetry currentContext span identicalTo: span.
			childSpan := tracer startSpanNamed: 'child'.
			self assert: (childSpan asExportRecord at: #parentSpanContext) equals: span spanContext ].
	self deny: OpenTelemetry currentSpan identicalTo: span
]

{ #category : 'tests' }
OTCurrentContextTest >> testEndingActiveSpanDoesNotEvictItFromCurrentContext [

	| provider span tracer |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	tracer := provider tracerNamed: 'demo.scope'.
	span := tracer startSpanNamed: 'operation'.
	OpenTelemetry useSpan: span during: [
			self assert: OpenTelemetry currentSpan identicalTo: span.
			span end.
			self assert: OpenTelemetry currentSpan identicalTo: span.
			self assert: OpenTelemetry currentContext span identicalTo: span.
			self deny: OpenTelemetry currentSpan isRecording ]
]

{ #category : 'tests' }
OTCurrentContextTest >> testUseContextRestoresPreviousContextWithinProcess [

	| innerContext outerContext |
	outerContext := (OTContext new)
		withBaggage: ((OTBaggage builder)
			putEntryNamed: 'scope' value: 'outer';
			build).
	innerContext := (OTContext new)
		withBaggage: ((OTBaggage builder)
			putEntryNamed: 'scope' value: 'inner';
			build).
	OpenTelemetry currentContext: outerContext.
	OpenTelemetry
		useContext: innerContext
		during: [
			self assert: OpenTelemetry currentContext identicalTo: innerContext ].
	self assert: OpenTelemetry currentContext identicalTo: outerContext
]
