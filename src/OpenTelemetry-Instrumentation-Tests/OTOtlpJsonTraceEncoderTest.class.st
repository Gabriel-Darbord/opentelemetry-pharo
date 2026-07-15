Class {
	#name : 'OTOtlpJsonTraceEncoderTest',
	#superclass : 'TestCase',
	#instVars : [
		'encoder'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'private' }
OTOtlpJsonTraceEncoderTest >> attributeValuesByKeyFrom: someKeyValueDictionaries [

	| valuesByKey |
	valuesByKey := Dictionary new.
	someKeyValueDictionaries do: [ :each |
		valuesByKey at: (each at: 'key') put: (each at: 'value') ].
	^ valuesByKey
]

{ #category : 'private' }
OTOtlpJsonTraceEncoderTest >> buildPrimarySpan [

	| span parentContext linkContext |
	parentContext := OTSpanContext
		traceId: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
		spanId: 'bbbbbbbbbbbbbbbb'
		traceFlags: '01'
		traceState: 'parent=remote'
		remote: true.
	linkContext := OTSpanContext
		traceId: 'cccccccccccccccccccccccccccccccc'
		spanId: 'dddddddddddddddd'
		traceFlags: '03'
		traceState: 'link=value'
		remote: false.
	span := OTSpan new.
	span
		traceId: '12345678876543211234567887654321';
		spanId: '8765432112345678';
		parent: parentContext asNonRecordingSpan;
		name: 'testSpan';
		kind: OTSpan client;
		startTime: (DateAndTime unixEpoch + (Duration nanoSeconds: 100));
		endTime: (DateAndTime unixEpoch + (Duration nanoSeconds: 1100));
		traceFlags: '01';
		traceState: 'vendor=value';
		attributes: (OrderedDictionary new
			at: 'animal' put: 'cat';
			at: 'bytes' put: #[1 2 3];
			at: 'empty' put: nil;
			at: 'heterogeneousArray' put: #('string' 123);
			at: 'lives' put: 9;
			at: 'map' put: (OrderedDictionary new at: 'nested' put: 'value'; yourself);
			yourself);
		events: {
				(OTSpanEvent
					named: 'somethingHappenedHere'
					attributes: (Dictionary new at: 'important' put: true; yourself)
					timestamp: (DateAndTime unixEpoch + (Duration nanoSeconds: 600))
					droppedAttributesCount: 1) };
		links: {
				(OTSpanLink
					spanContext: linkContext
					attributes: (Dictionary new at: 'link-attribute' put: 'value'; yourself)
					droppedAttributesCount: 2) };
		status: OTSpan error;
		statusDescription: 'boom';
		resource: (OTResource
			attributes: (OrderedDictionary new
				at: 'service.name' put: 'demo';
				at: 'resource-attr' put: 'resource-value';
				yourself)
			schemaUrl: 'https://opentelemetry.io/schemas/1.24.0');
		instrumentationScope: (OTInstrumentationScope
			named: 'instrumentation'
			version: '1.0.0'
			schemaUrl: 'https://opentelemetry.io/schemas/1.25.0'
			attributes: (OrderedDictionary new at: 'scope-key' put: 'scope-value'; yourself));
		droppedAttributesCount: 3;
		droppedEventsCount: 4;
		droppedLinksCount: 5.
	^ span
]

{ #category : 'private' }
OTOtlpJsonTraceEncoderTest >> buildSiblingSpanNamed: aString scopeName: aScopeName [

	| span |
	span := OTSpan new.
	span
		traceId: 'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';
		spanId: (aScopeName = 'scope-a'
			ifTrue: [ '1111111111111111' ]
			ifFalse: [ '2222222222222222' ]);
		name: aString;
		kind: OTSpan internal;
		startTime: (DateAndTime unixEpoch + (Duration milliSeconds: 1));
		endTime: (DateAndTime unixEpoch + (Duration milliSeconds: 2));
		traceFlags: '01';
		traceState: nil;
		attributes: #();
		events: #();
		links: #();
		resource: (OTResource
			attributes: (OrderedDictionary new at: 'service.name' put: 'shared'; yourself)
			schemaUrl: 'https://resource.example/schema');
		instrumentationScope: (OTInstrumentationScope
			named: aScopeName
			version: '1'
			schemaUrl: ''
			attributes: #()).
	^ span
]

{ #category : 'tests' }
OTOtlpJsonTraceEncoderTest >> testEncodeSpansGroupsByResourceAndScope [

	| payload resourceSpans scopeSpans |
	payload := encoder encodeSpans: {
			(self buildSiblingSpanNamed: 'one' scopeName: 'scope-a').
			(self buildSiblingSpanNamed: 'two' scopeName: 'scope-a').
			(self buildSiblingSpanNamed: 'three' scopeName: 'scope-b') }.
	resourceSpans := payload at: 'resourceSpans'.
	self assert: resourceSpans size equals: 1.
	scopeSpans := (resourceSpans first at: 'scopeSpans').
	self assert: scopeSpans size equals: 2.
	self assert: ((scopeSpans first at: 'scope') at: 'name') equals: 'scope-a'.
	self assert: ((scopeSpans first at: 'spans') size) equals: 2.
	self assert: ((scopeSpans second at: 'scope') at: 'name') equals: 'scope-b'.
	self assert: ((scopeSpans second at: 'spans') size) equals: 1
]

{ #category : 'tests' }
OTOtlpJsonTraceEncoderTest >> testEncodeSpansProducesSpecShapedOtlpJsonPayload [

	| payload resourceSpan scopeSpan span attributes link |
	payload := encoder encodeSpans: { self buildPrimarySpan }.
	self assert: (payload keys asArray) equals: #( 'resourceSpans' ).
	resourceSpan := (payload at: 'resourceSpans') first.
	self assert: (resourceSpan at: 'schemaUrl') equals: 'https://opentelemetry.io/schemas/1.24.0'.
	self
		assert:
			(((self attributeValuesByKeyFrom: ((resourceSpan at: 'resource') at: 'attributes'))
				at: 'service.name') at: 'stringValue')
		equals: 'demo'.
	scopeSpan := (resourceSpan at: 'scopeSpans') first.
	self assert: (scopeSpan at: 'schemaUrl') equals: 'https://opentelemetry.io/schemas/1.25.0'.
	self assert: ((scopeSpan at: 'scope') at: 'name') equals: 'instrumentation'.
	self assert: ((scopeSpan at: 'scope') at: 'version') equals: '1.0.0'.
	span := (scopeSpan at: 'spans') first.
	self assert: (span at: 'traceId') equals: '12345678876543211234567887654321'.
	self assert: (span at: 'spanId') equals: '8765432112345678'.
	self assert: (span at: 'parentSpanId') equals: 'bbbbbbbbbbbbbbbb'.
	self assert: (span at: 'traceState') equals: 'vendor=value'.
	self assert: (span at: 'kind') equals: 3.
	self assert: (span at: 'startTimeUnixNano') equals: '100'.
	self assert: (span at: 'endTimeUnixNano') equals: '1100'.
	self assert: (span at: 'flags') equals: 769.
	self assert: (span at: 'droppedAttributesCount') equals: 3.
	self assert: (span at: 'droppedEventsCount') equals: 4.
	self assert: (span at: 'droppedLinksCount') equals: 5.
	self assert: ((span at: 'status') at: 'code') equals: 2.
	self assert: ((span at: 'status') at: 'message') equals: 'boom'.
	attributes := self attributeValuesByKeyFrom: (span at: 'attributes').
	self assert: ((attributes at: 'animal') at: 'stringValue') equals: 'cat'.
	self assert: ((attributes at: 'bytes') at: 'bytesValue') equals: 'AQID'.
	self assert: (attributes at: 'empty') isEmpty.
	self assert: ((((attributes at: 'heterogeneousArray') at: 'arrayValue') at: 'values') first at: 'stringValue') equals: 'string'.
	self assert: ((((attributes at: 'heterogeneousArray') at: 'arrayValue') at: 'values') second at: 'intValue') equals: '123'.
	self assert: ((attributes at: 'lives') at: 'intValue') equals: '9'.
	self
		assert:
			((((((attributes at: 'map') at: 'kvlistValue') at: 'values') first at: 'value')
				at: 'stringValue'))
		equals: 'value'.
	self assert: (((span at: 'events') first at: 'timeUnixNano')) equals: '600'.
	self assert: ((((self attributeValuesByKeyFrom: (((span at: 'events') first) at: 'attributes')) at: 'important') at: 'boolValue')).
	self assert: ((((span at: 'events') first) at: 'droppedAttributesCount')) equals: 1.
	link := (span at: 'links') first.
	self assert: (link at: 'traceId') equals: 'cccccccccccccccccccccccccccccccc'.
	self assert: (link at: 'spanId') equals: 'dddddddddddddddd'.
	self assert: (link at: 'traceState') equals: 'link=value'.
	self assert: (link at: 'flags') equals: 259.
	self assert: ((((self attributeValuesByKeyFrom: (link at: 'attributes')) at: 'link-attribute') at: 'stringValue')) equals: 'value'.
	self assert: (link at: 'droppedAttributesCount') equals: 2
]

{ #category : 'tests' }
OTOtlpJsonTraceEncoderTest >> testEncodeSpansWithoutErrorStatusOmitsStatusMessage [

	| payload span |
	span := OTSpan new.
	span
		traceId: '12345678876543211234567887654321';
		spanId: '8765432112345678';
		name: 'testSpan';
		kind: OTSpan internal;
		startTime: DateAndTime unixEpoch;
		endTime: DateAndTime unixEpoch;
		traceFlags: '01';
		attributes: #();
		events: #();
		links: #();
		resource: OTResource empty;
		instrumentationScope: (OTInstrumentationScope named: '').
	payload := encoder encodeSpans: { span }.
	self assert: ((((payload at: 'resourceSpans') first at: 'scopeSpans') first at: 'spans') first at: 'status') isEmpty
]

{ #category : 'running' }
OTOtlpJsonTraceEncoderTest >> setUp [

	super setUp.
	encoder := OTOtlpJsonTraceEncoder new
]
