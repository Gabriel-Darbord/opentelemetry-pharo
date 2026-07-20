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

{ #category : 'tests' }
OTSpanEventTest >> testMutatorsAreNotExposed [

	| event |
	event := OTSpanEvent named: 'tick' attributes: #(  ) timestamp: DateAndTime unixEpoch.
	self should: [ OTSpanEvent new ] raise: Error.
	self should: [ event perform: #name: with: 'other' ] raise: MessageNotUnderstood.
	self should: [ event perform: #timestamp: with: DateAndTime now ] raise: MessageNotUnderstood.
	self
		should: [
				event perform: #attributes: with: (OrderedDictionary new
						 at: 'answer' put: 42;
						 yourself) ]
		raise: MessageNotUnderstood.
	self should: [ event perform: #droppedAttributesCount: with: 1 ] raise: MessageNotUnderstood
]
