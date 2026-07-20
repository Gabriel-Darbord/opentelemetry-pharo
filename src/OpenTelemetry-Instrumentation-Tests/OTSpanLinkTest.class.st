Class {
	#name : 'OTSpanLinkTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'tests' }
OTSpanLinkTest >> testAttributesAnswerDeepCopy [

	| attributes returnedAttributes spanContext link |
	attributes := OrderedDictionary new
		              at: 'flat' put: 'value';
		              at: 'nested' put: (OrderedDictionary new
				               at: 'inner' put: 'value';
				               yourself);
		              yourself.
	spanContext := OTSpanContext
		               traceId: '00112233445566778899aabbccddeeff'
		               spanId: '1122334455667788'
		               traceFlags: '01'
		               traceState: nil
		               remote: false.
	link := OTSpanLink spanContext: spanContext attributes: attributes.
	returnedAttributes := link attributes.
	returnedAttributes at: 'flat' put: 'changed'.
	(returnedAttributes at: 'nested') at: 'inner' put: 'changed'.
	self assert: (link attributes at: 'flat') equals: 'value'.
	self assert: ((link attributes at: 'nested') at: 'inner') equals: 'value'
]
