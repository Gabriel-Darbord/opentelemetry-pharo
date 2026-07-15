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
