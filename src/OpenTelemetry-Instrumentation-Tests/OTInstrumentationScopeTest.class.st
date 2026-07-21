Class {
	#name : 'OTInstrumentationScopeTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'tests' }
OTInstrumentationScopeTest >> testDirectConstructorIgnoresInvalidAttributesWithoutError [

	| scope |
	scope := nil.
	self
		shouldnt: [
			scope := OTInstrumentationScope
				         named: 'demo.scope'
				         version: 42
				         schemaUrl: 7
				         attributes: 42 ]
		raise: Error.
	self assert: scope name equals: 'demo.scope'.
	self assert: scope version equals: 42.
	self assert: scope schemaUrl equals: 7.
	self assert: scope allAttributes isEmpty
]
