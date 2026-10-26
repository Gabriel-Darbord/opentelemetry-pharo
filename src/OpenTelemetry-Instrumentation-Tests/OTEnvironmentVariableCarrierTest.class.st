Class {
	#name : 'OTEnvironmentVariableCarrierTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'tests' }
OTEnvironmentVariableCarrierTest >> testGetterReadsOnlyNormalizedNames [

	| carrier getter |
	carrier := {
		           ('TRACEPARENT' -> 'normalized').
		           ('traceparent' -> 'ignored').
		           ('ÉTRACE' -> 'ignored') } asDictionary.
	getter := OTEnvironmentVariableTextMapGetter new.
	self assert: (getter getFrom: carrier key: 'traceparent') equals: 'normalized'.
	self assert: (getter keysIn: carrier) asSet equals: #( 'TRACEPARENT' ) asSet.
	self assert: (getter getAllFrom: carrier key: 'missing') isEmpty
]

{ #category : 'tests' }
OTEnvironmentVariableCarrierTest >> testSetterNormalizesAsciiEnvironmentNames [

	| carrier setter |
	setter := OTEnvironmentVariableTextMapSetter new.
	{
		('traceparent' -> 'TRACEPARENT').
		('x-b3-traceid' -> 'X_B3_TRACEID').
		('1key' -> '_1KEY').
		('' -> '_').
		('ÉTRACE' -> '_TRACE').
		('key١' -> 'KEY_') } do: [ :example |
			carrier := Dictionary new.
			setter setIn: carrier key: example key value: 'opaque value'.
			self assert: carrier equals: { (example value -> 'opaque value') } asDictionary ]
]

{ #category : 'tests' }
OTEnvironmentVariableCarrierTest >> testSetterWritesOnlyToProvidedCarrier [

	| original child |
	original := { ('SERVICE_SETTING' -> 'unchanged') } asDictionary.
	child := original copy.
	OTEnvironmentVariableTextMapSetter new setIn: child key: 'traceparent' value: 'opaque value'.
	self deny: (original includesKey: 'TRACEPARENT').
	self assert: (child at: 'TRACEPARENT') equals: 'opaque value'.
	self assert: (child at: 'SERVICE_SETTING') equals: 'unchanged'
]
