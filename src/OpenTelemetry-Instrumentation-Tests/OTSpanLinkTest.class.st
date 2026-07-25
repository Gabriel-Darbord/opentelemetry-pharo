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

{ #category : 'tests' }
OTSpanLinkTest >> testConstructorIgnoresInvalidArgumentsWithoutError [

	| link |
	link := nil.
	self shouldnt: [ link := OTSpanLink spanContext: 'not a span context' attributes: #( invalid ) ] raise: Error.
	self deny: link spanContext isValid.
	self assert: link attributes isEmpty
]

{ #category : 'tests' }
OTSpanLinkTest >> testMutatorsAreNotExposed [

	| link spanContext |
	spanContext := OTSpanContext
		               traceId: '00112233445566778899aabbccddeeff'
		               spanId: '1122334455667788'
		               traceFlags: '01'
		               traceState: nil
		               remote: false.
	link := OTSpanLink spanContext: spanContext attributes: #(  ).
	self should: [ OTSpanLink new ] raise: Error.
	self should: [ link perform: #spanContext: with: spanContext ] raise: MessageNotUnderstood.
	self
		should: [
				link perform: #attributes: with: (OrderedDictionary new
						 at: 'answer' put: 42;
						 yourself) ]
		raise: MessageNotUnderstood.
	self should: [ link perform: #droppedAttributesCount: with: 1 ] raise: MessageNotUnderstood
]
