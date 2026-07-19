Class {
	#name : 'OTOtlpProtobufTraceEncoderTest',
	#superclass : 'TestCase',
	#instVars : [
		'encoder'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'private' }
OTOtlpProtobufTraceEncoderTest >> assertReader: aReader readsField: aFieldNumber wireType: aWireType [

	| tag |
	tag := aReader readTag.
	self assert: tag first equals: aFieldNumber.
	self assert: tag second equals: aWireType
]

{ #category : 'private' }
OTOtlpProtobufTraceEncoderTest >> sampleSpan [

	| link parentContext provider span tracer |
	parentContext := OTContext new withSpan: (OTSpanContext
			                  traceId: '12345678876543211234567887654321'
			                  spanId: 'bbbbbbbbbbbbbbbb'
			                  traceFlags: '01'
			                  traceState: 'vendor=value'
			                  remote: true) asNonRecordingSpan.
	link := OTSpanLink
		        spanContext: (OTSpanContext
				         traceId: '11111111111111111111111111111111'
				         spanId: '2222222222222222'
				         traceFlags: '01'
				         traceState: 'linked=value'
				         remote: true)
		        attributes: (OrderedDictionary new
				         at: 'link.attr' put: 'link-value';
				         yourself)
		        droppedAttributesCount: 1.
	provider := OTTracerProvider new.
	provider
		spanProcessor: OTSimpleSpanProcessor new;
		idGenerator: (OTFixedIdGenerator traceIdHex: '12345678876543211234567887654321' spanIdHex: '8765432112345678' random: false).
	tracer := provider tracerNamed: 'encoder.test'.
	span := (tracer spanBuilderNamed: 'operation')
		        kind: OTSpan client;
		        inContext: parentContext;
		        startSpan.
	span
		startTime: DateAndTime unixEpoch + (Duration milliSeconds: 1);
		endTime: DateAndTime unixEpoch + (Duration milliSeconds: 2);
		attributes: (OrderedDictionary new
				 at: 'service.name' put: 'demo';
				 at: 'attempt' put: 7;
				 yourself);
		events: { (OTSpanEvent
				 named: 'tick'
				 attributes: (OrderedDictionary new
						  at: 'count' put: 3;
						  yourself)
				 timestamp: DateAndTime unixEpoch + (Duration milliSeconds: 1)
				 droppedAttributesCount: 1) };
		links: { link };
		resource: (OTResource
				 attributes: (OrderedDictionary new
						  at: 'service.name' put: 'demo-service';
						  yourself)
				 schemaUrl: 'https://resource.example/schema');
		instrumentationScope: (OTInstrumentationScope
				 named: 'demo.scope'
				 version: '1.2.3'
				 schemaUrl: 'https://scope.example/schema'
				 attributes: (OrderedDictionary new
						  at: 'scope.attr' put: true;
						  yourself));
		setErrorStatusDescription: 'boom';
		droppedAttributesCount: 2;
		droppedEventsCount: 3;
		droppedLinksCount: 4.
	^ span
]

{ #category : 'running' }
OTOtlpProtobufTraceEncoderTest >> setUp [

	super setUp.
	encoder := OTOtlpProtobufTraceEncoder new
]

{ #category : 'tests' }
OTOtlpProtobufTraceEncoderTest >> testEncodeEmptySpanCollectionProducesEmptyRequest [

	self assert: (encoder encodeSpans: #()) equals: #[]
]

{ #category : 'tests' }
OTOtlpProtobufTraceEncoderTest >> testEncodeSpanProducesExpectedOtlpTraceStructure [

	| requestReader requestBytes resourceAttributeReader resourceReader resourceSpansBytes scopeAttributeReader scopeReader scopeSpansBytes spanAttributeReader spanBytes spanReader statusBytes statusReader |
	requestBytes := encoder encodeSpans: { self sampleSpan }.
	requestReader := OTProtobufReader on: requestBytes.
	self assertReader: requestReader readsField: 1 wireType: 2.
	resourceSpansBytes := requestReader readBytes.
	self assert: requestReader atEnd.

	resourceReader := OTProtobufReader on: resourceSpansBytes.
	self assertReader: resourceReader readsField: 1 wireType: 2.
	resourceAttributeReader := OTProtobufReader on: resourceReader readBytes.
	self assertReader: resourceAttributeReader readsField: 1 wireType: 2.
	self assert: (resourceAttributeReader readBytes notEmpty).
	self assertReader: resourceAttributeReader readsField: 2 wireType: 0.
	self assert: resourceAttributeReader readVarint equals: 0.
	self assert: resourceAttributeReader atEnd.

	self assertReader: resourceReader readsField: 2 wireType: 2.
	scopeSpansBytes := resourceReader readBytes.
	self assertReader: resourceReader readsField: 3 wireType: 2.
	self assert: resourceReader readString equals: 'https://resource.example/schema'.
	self assert: resourceReader atEnd.

	scopeReader := OTProtobufReader on: scopeSpansBytes.
	self assertReader: scopeReader readsField: 1 wireType: 2.
	scopeAttributeReader := OTProtobufReader on: scopeReader readBytes.
	self assertReader: scopeAttributeReader readsField: 1 wireType: 2.
	self assert: scopeAttributeReader readString equals: 'demo.scope'.
	self assertReader: scopeAttributeReader readsField: 2 wireType: 2.
	self assert: scopeAttributeReader readString equals: '1.2.3'.
	self assertReader: scopeAttributeReader readsField: 3 wireType: 2.
	self assert: (scopeAttributeReader readBytes notEmpty).
	self assertReader: scopeAttributeReader readsField: 4 wireType: 0.
	self assert: scopeAttributeReader readVarint equals: 0.
	self assert: scopeAttributeReader atEnd.

	self assertReader: scopeReader readsField: 2 wireType: 2.
	spanBytes := scopeReader readBytes.
	self assertReader: scopeReader readsField: 3 wireType: 2.
	self assert: scopeReader readString equals: 'https://scope.example/schema'.
	self assert: scopeReader atEnd.

	spanReader := OTProtobufReader on: spanBytes.
	self assertReader: spanReader readsField: 1 wireType: 2.
	self assert: spanReader readBytes equals: (OTSpanContext byteArrayFromHex: '12345678876543211234567887654321' size: 16).
	self assertReader: spanReader readsField: 2 wireType: 2.
	self assert: spanReader readBytes equals: (OTSpanContext byteArrayFromHex: '8765432112345678' size: 8).
	self assertReader: spanReader readsField: 3 wireType: 2.
	self assert: spanReader readString equals: 'vendor=value'.
	self assertReader: spanReader readsField: 4 wireType: 2.
	self assert: spanReader readBytes equals: (OTSpanContext byteArrayFromHex: 'bbbbbbbbbbbbbbbb' size: 8).
	self assertReader: spanReader readsField: 5 wireType: 2.
	self assert: spanReader readString equals: 'operation'.
	self assertReader: spanReader readsField: 6 wireType: 0.
	self assert: spanReader readVarint equals: 3.
	self assertReader: spanReader readsField: 7 wireType: 1.
	self assert: spanReader readFixed64 equals: 1000000.
	self assertReader: spanReader readsField: 8 wireType: 1.
	self assert: spanReader readFixed64 equals: 2000000.
	self assertReader: spanReader readsField: 9 wireType: 2.
	spanAttributeReader := OTProtobufReader on: spanReader readBytes.
	self assertReader: spanAttributeReader readsField: 1 wireType: 2.
	self assert: spanAttributeReader readString equals: 'service.name'.
	self assertReader: spanAttributeReader readsField: 2 wireType: 2.
	self assert: (spanAttributeReader readBytes notEmpty).
	self assert: spanAttributeReader atEnd.
	self assertReader: spanReader readsField: 9 wireType: 2.
	self assert: (spanReader readBytes notEmpty).
	self assertReader: spanReader readsField: 10 wireType: 0.
	self assert: spanReader readVarint equals: 2.
	self assertReader: spanReader readsField: 11 wireType: 2.
	self assert: (spanReader readBytes notEmpty).
	self assertReader: spanReader readsField: 12 wireType: 0.
	self assert: spanReader readVarint equals: 3.
	self assertReader: spanReader readsField: 13 wireType: 2.
	self assert: (spanReader readBytes notEmpty).
	self assertReader: spanReader readsField: 14 wireType: 0.
	self assert: spanReader readVarint equals: 4.
	self assertReader: spanReader readsField: 15 wireType: 2.
	statusBytes := spanReader readBytes.
	statusReader := OTProtobufReader on: statusBytes.
	self assertReader: statusReader readsField: 2 wireType: 2.
	self assert: statusReader readString equals: 'boom'.
	self assertReader: statusReader readsField: 3 wireType: 0.
	self assert: statusReader readVarint equals: 2.
	self assert: statusReader atEnd.
	self assertReader: spanReader readsField: 16 wireType: 5.
	self assert: spanReader readFixed32 equals: 16r301.
	self assert: spanReader atEnd
]
