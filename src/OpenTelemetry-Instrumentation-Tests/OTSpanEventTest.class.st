Class {
	#name : 'OTSpanEventTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'tests' }
OTSpanEventTest >> testAttributesAnswerDeepCopy [

	| attributes event returnedAttributes |
	attributes := OrderedDictionary new
		              at: 'flat' put: 'value';
		              at: 'nested' put: (OrderedDictionary new
				               at: 'inner' put: 'value';
				               yourself);
		              yourself.
	event := OTSpanEvent named: 'tick' attributes: attributes timestamp: DateAndTime unixEpoch.
	returnedAttributes := event attributes.
	returnedAttributes at: 'flat' put: 'changed'.
	(returnedAttributes at: 'nested') at: 'inner' put: 'changed'.
	self assert: (event attributes at: 'flat') equals: 'value'.
	self assert: ((event attributes at: 'nested') at: 'inner') equals: 'value'
]
