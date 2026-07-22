Class {
	#name : 'OTInstrumentationScopeTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'tests' }
OTInstrumentationScopeTest >> testDirectConstructorNormalizesIdentityFieldsAndIgnoresInvalidAttributesWithoutError [

	| scope |
	scope := nil.
	self
		shouldnt: [
				scope := OTInstrumentationScope
					         named: 42
					         version: 7
					         schemaUrl: 9
					         attributes: 42 ]
		raise: Error.
	self assert: scope name equals: '42'.
	self assert: scope version equals: '7'.
	self assert: scope schemaUrl equals: '9'.
	self assert: scope allAttributes isEmpty
]
