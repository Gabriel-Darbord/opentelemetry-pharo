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

	| linkContext parentContext span |
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
	span := OTSpan rootInInternal: OTContext new.
	span
		restoreSpanContext: (OTSpanContext
				 traceId: '12345678876543211234567887654321'
				 spanId: '8765432112345678'
				 traceFlags: '01'
				 traceState: 'vendor=value'
				 remote: false);
		restoreParent: parentContext asNonRecordingSpan;
		restoreName: 'testSpan';
		restoreKind: OTSpan client;
		restoreStartTime: DateAndTime unixEpoch + (Duration nanoSeconds: 100);
		restoreEndTime: DateAndTime unixEpoch + (Duration nanoSeconds: 1100);
		restoreAttributes: (OrderedDictionary new
				 at: 'animal' put: 'cat';
				 at: 'bytes' put: #[ 1 2 3 ];
				 at: 'empty' put: nil;
				 at: 'heterogeneousArray' put: #( 'string' 123 );
				 at: 'lives' put: 9;
				 at: 'map' put: (OrderedDictionary new
						  at: 'nested' put: 'value';
						  yourself);
				 yourself);
		restoreEvents: { (OTSpanEvent
				 named: 'somethingHappenedHere'
				 attributes: (Dictionary new
						  at: 'important' put: true;
						  yourself)
				 timestamp: DateAndTime unixEpoch + (Duration nanoSeconds: 600)
				 droppedAttributesCount: 1) };
		restoreLinks: { (OTSpanLink
				 spanContext: linkContext
				 attributes: (Dictionary new
						  at: 'link-attribute' put: 'value';
						  yourself)
				 droppedAttributesCount: 2) };
		setStatus: OTSpan error description: 'boom';
		restoreResource: (OTResource
				 attributes: (OrderedDictionary new
						  at: 'service.name' put: 'demo';
						  at: 'resource-attr' put: 'resource-value';
						  yourself)
				 schemaUrl: 'https://opentelemetry.io/schemas/1.24.0');
		restoreInstrumentationScope: (OTInstrumentationScope
				 named: 'instrumentation'
				 version: '1.0.0'
				 schemaUrl: 'https://opentelemetry.io/schemas/1.25.0'
				 attributes: (OrderedDictionary new
						  at: 'scope-key' put: 'scope-value';
						  yourself));
		restoreDroppedAttributesCount: 3;
		restoreDroppedEventsCount: 4;
		restoreDroppedLinksCount: 5.
	^ span
]

{ #category : 'private' }
OTOtlpJsonTraceEncoderTest >> buildSiblingSpanNamed: aString scopeName: aScopeName [

	| provider span tracer |
	provider := OTTracerProvider new.
	provider
		spanProcessor: OTSimpleSpanProcessor new;
		idGenerator: (OTFixedIdGenerator
				 traceIdHex: 'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee'
				 spanIdHex: (aScopeName = 'scope-a'
						  ifTrue: [ '1111111111111111' ]
						  ifFalse: [ '2222222222222222' ])
				 random: false).
	tracer := provider tracerNamed: 'encoder.test'.
	span := (tracer spanBuilderNamed: aString)
		        kind: OTSpan internal;
		        startTimestamp: DateAndTime unixEpoch + (Duration milliSeconds: 1);
		        startSpan.
	span
		restoreAttributes: #(  );
		restoreEvents: #(  );
		restoreLinks: #(  );
		restoreResource: (OTResource
				 attributes: (OrderedDictionary new
						  at: 'service.name' put: 'shared';
						  yourself)
				 schemaUrl: 'https://resource.example/schema');
		restoreInstrumentationScope: (OTInstrumentationScope
				 named: aScopeName
				 version: '1'
				 schemaUrl: ''
				 attributes: #(  ));
		end: DateAndTime unixEpoch + (Duration milliSeconds: 2).
	^ span
]

{ #category : 'running' }
OTOtlpJsonTraceEncoderTest >> setUp [

	super setUp.
	encoder := OTOtlpJsonTraceEncoder new
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

	| payload provider span tracer |
	provider := OTTracerProvider new.
	provider
		spanProcessor: OTSimpleSpanProcessor new;
		idGenerator: (OTFixedIdGenerator traceIdHex: '12345678876543211234567887654321' spanIdHex: '8765432112345678' random: false).
	tracer := provider tracerNamed: 'encoder.test'.
	span := (tracer spanBuilderNamed: 'testSpan')
		        kind: OTSpan internal;
		        startTimestamp: DateAndTime unixEpoch;
		        startSpan.
	span
		restoreAttributes: #(  );
		restoreEvents: #(  );
		restoreLinks: #(  );
		restoreResource: OTResource empty;
		restoreInstrumentationScope: (OTInstrumentationScope named: '');
		end: DateAndTime unixEpoch.
	payload := encoder encodeSpans: { span }.
	self assert: ((((payload at: 'resourceSpans') first at: 'scopeSpans') first at: 'spans') first at: 'status') isEmpty
]

{ #category : 'tests' }
OTOtlpJsonTraceEncoderTest >> testEncodeStonRoundTrippedSpanPreservesParentSpanContext [

	| payload roundTripped span |
	roundTripped := STON fromString: (STON toString: self buildPrimarySpan).
	payload := encoder encodeSpans: { roundTripped }.
	span := (((payload at: 'resourceSpans') first at: 'scopeSpans') first at: 'spans') first.
	self assert: (span at: 'parentSpanId') equals: 'bbbbbbbbbbbbbbbb'.
	self assert: roundTripped parentSpanContext traceId equals: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'.
	self assert: roundTripped parentSpanContext isRemote
]
