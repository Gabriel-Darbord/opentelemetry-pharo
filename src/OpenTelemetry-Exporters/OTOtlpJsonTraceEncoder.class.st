"
An OTLP trace encoder that emits the OpenTelemetry JSON protobuf shape for ExportTraceServiceRequest payloads.
"
Class {
	#name : 'OTOtlpJsonTraceEncoder',
	#superclass : 'OTOtlpTraceEncoder',
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'private - encoding' }
OTOtlpJsonTraceEncoder >> anyValueDataFor: anObject [

	| data |
	data := OrderedDictionary new.
	anObject isNil ifTrue: [ ^ data ].
	((anObject isString) or: [ anObject isSymbol ]) ifTrue: [
		data at: 'stringValue' put: anObject asString.
		^ data ].
	(OTAttributeNormalizer isBoolean: anObject) ifTrue: [
		data at: 'boolValue' put: anObject.
		^ data ].
	anObject isInteger ifTrue: [
		data at: 'intValue' put: anObject asString.
		^ data ].
	anObject isNumber ifTrue: [
		data at: 'doubleValue' put: anObject asFloat.
		^ data ].
	(anObject isKindOf: ByteArray) ifTrue: [
		data at: 'bytesValue' put: anObject base64Encoded.
		^ data ].
	(OTAttributeNormalizer isMapValue: anObject) ifTrue: [
		data
			at: 'kvlistValue'
			put: (OrderedDictionary new
					at: 'values' put: (self keyValueDataFrom: anObject);
					yourself).
		^ data ].
	anObject isCollection ifTrue: [
		data
			at: 'arrayValue'
			put: (OrderedDictionary new
					at: 'values' put: (anObject collect: [ :each | self anyValueDataFor: each ]) asArray;
					yourself).
		^ data ].
	Error signal: 'Unsupported OTLP AnyValue: ' , anObject printString
]

{ #category : 'private - encoding' }
OTOtlpJsonTraceEncoder >> eventDataFor: anEvent [

	| data |
	data := OrderedDictionary new.
	data
		at: 'timeUnixNano' put: (self unixNanosecondsStringFor: anEvent timestamp);
		at: 'name' put: anEvent name.
	anEvent attributes ifNotEmpty: [
		data at: 'attributes' put: (self keyValueDataFrom: anEvent attributes) ].
	anEvent droppedAttributesCount > 0 ifTrue: [
		data at: 'droppedAttributesCount' put: anEvent droppedAttributesCount ].
	^ data
]

{ #category : 'encoding' }
OTOtlpJsonTraceEncoder >> encodeSpans: someSpans [

	^ OrderedDictionary new
		at: 'resourceSpans' put: (self resourceSpansDataFor: someSpans);
		yourself
]

{ #category : 'private - encoding' }
OTOtlpJsonTraceEncoder >> flagsForParentContext: aSpanContext traceFlagsHex: aString [

	| flags |
	flags := Integer readFrom: aString readStream base: 16.
	aSpanContext ifNil: [ ^ flags ].
	flags := flags bitOr: 16r100.
	aSpanContext isRemote ifTrue: [ flags := flags bitOr: 16r200 ].
	^ flags
]

{ #category : 'private - encoding' }
OTOtlpJsonTraceEncoder >> flagsForSpanContext: aSpanContext [

	^ self
		flagsForParentContext: aSpanContext
		traceFlagsHex: aSpanContext traceFlags
]

{ #category : 'private - encoding' }
OTOtlpJsonTraceEncoder >> groupedSpansFrom: someSpans [

	| groupedSpans |
	groupedSpans := OrderedDictionary new.
	(someSpans ifNil: [ #() ]) do: [ :eachSpan |
		| resource scope scopeGroups |
		resource := eachSpan resource.
		scope := eachSpan instrumentationScope.
		scopeGroups := groupedSpans
			at: resource
			ifAbsentPut: [ OrderedDictionary new ].
		(scopeGroups
			at: scope
			ifAbsentPut: [ OrderedCollection new ]) add: eachSpan ].
	^ groupedSpans
]

{ #category : 'private - encoding' }
OTOtlpJsonTraceEncoder >> keyValueDataFor: anAssociation [

	^ OrderedDictionary new
		at: 'key' put: anAssociation key;
		at: 'value' put: (self anyValueDataFor: anAssociation value);
		yourself
]

{ #category : 'private - encoding' }
OTOtlpJsonTraceEncoder >> keyValueDataFrom: aCollection [

	^ aCollection associations collect: [ :each |
		  self keyValueDataFor: each ]
]

{ #category : 'private - encoding' }
OTOtlpJsonTraceEncoder >> kindCodeFor: aSpan [

	| kind |
	kind := aSpan kind.
	kind = OTSpan internal ifTrue: [ ^ 1 ].
	kind = OTSpan server ifTrue: [ ^ 2 ].
	kind = OTSpan client ifTrue: [ ^ 3 ].
	kind = OTSpan producer ifTrue: [ ^ 4 ].
	kind = OTSpan consumer ifTrue: [ ^ 5 ].
	^ 0
]

{ #category : 'private - encoding' }
OTOtlpJsonTraceEncoder >> linkDataFor: aLink [

	| data linkContext |
	linkContext := aLink spanContext.
	data := OrderedDictionary new.
	data
		at: 'traceId' put: linkContext traceIdHex;
		at: 'spanId' put: linkContext spanIdHex;
		at: 'flags' put: (self flagsForSpanContext: linkContext).
	linkContext traceState ifNotNil: [ :traceState |
		traceState isEmpty ifFalse: [
			data at: 'traceState' put: traceState asHeaderValue ] ].
	aLink attributes ifNotEmpty: [
		data at: 'attributes' put: (self keyValueDataFrom: aLink attributes) ].
	aLink droppedAttributesCount > 0 ifTrue: [
		data at: 'droppedAttributesCount' put: aLink droppedAttributesCount ].
	^ data
]

{ #category : 'private - encoding' }
OTOtlpJsonTraceEncoder >> resourceDataFor: aResource [

	| data |
	data := OrderedDictionary new.
	aResource allAttributes ifNotEmpty: [
		data at: 'attributes' put: (self keyValueDataFrom: aResource allAttributes) ].
	^ data
]

{ #category : 'private - encoding' }
OTOtlpJsonTraceEncoder >> resourceSpansDataFor: someSpans [

	^ (self groupedSpansFrom: someSpans) associations collect: [ :eachResourceGroup |
		  self
			  resourceSpansDataForResource: eachResourceGroup key
			  scopeGroups: eachResourceGroup value ]
]

{ #category : 'private - encoding' }
OTOtlpJsonTraceEncoder >> resourceSpansDataForResource: aResource scopeGroups: scopeGroups [

	| data |
	data := OrderedDictionary new.
	data
		at: 'resource' put: (self resourceDataFor: aResource);
		at: 'scopeSpans' put: (scopeGroups associations collect: [ :eachScopeGroup |
				 self
					 scopeSpansDataForScope: eachScopeGroup key
					 spans: eachScopeGroup value ]) asArray.
	aResource schemaUrl ifNotEmpty: [
		data at: 'schemaUrl' put: aResource schemaUrl ].
	^ data
]

{ #category : 'private - encoding' }
OTOtlpJsonTraceEncoder >> scopeDataFor: anInstrumentationScope [

	| data |
	anInstrumentationScope isEmpty ifTrue: [ ^ OrderedDictionary new ].
	data := OrderedDictionary new.
	anInstrumentationScope name ifNotEmpty: [
		data at: 'name' put: anInstrumentationScope name ].
	anInstrumentationScope version ifNotEmpty: [
		data at: 'version' put: anInstrumentationScope version ].
	data at: 'attributes' put: (self keyValueDataFrom: anInstrumentationScope allAttributes).
	^ data
]

{ #category : 'private - encoding' }
OTOtlpJsonTraceEncoder >> scopeSpansDataForScope: anInstrumentationScope spans: someSpans [

	| data |
	data := OrderedDictionary new.
	data
		at: 'scope' put: (self scopeDataFor: anInstrumentationScope);
		at: 'spans' put: (someSpans collect: [ :each | self spanDataFor: each ]) asArray.
	anInstrumentationScope schemaUrl ifNotEmpty: [
		data at: 'schemaUrl' put: anInstrumentationScope schemaUrl ].
	^ data
]

{ #category : 'private - encoding' }
OTOtlpJsonTraceEncoder >> spanDataFor: aSpan [

	| data parentContext traceState |
	data := OrderedDictionary new.
	parentContext := aSpan parent ifNil: [ nil ] ifNotNil: [ aSpan parent asSpanContext ].
	data
		at: 'traceId' put: aSpan traceId;
		at: 'spanId' put: aSpan spanId;
		at: 'parentSpanId' put: (parentContext ifNil: [ '' ] ifNotNil: [ parentContext spanIdHex ]);
		at: 'name' put: aSpan name;
		at: 'kind' put: (self kindCodeFor: aSpan);
		at: 'startTimeUnixNano' put: (self unixNanosecondsStringFor: aSpan startTime);
		at: 'endTimeUnixNano' put: (self unixNanosecondsStringFor: aSpan endTime);
		at: 'attributes' put: (self keyValueDataFrom: aSpan attributes);
		at: 'events' put: (aSpan events collect: [ :each | self eventDataFor: each ]) asArray;
		at: 'links' put: (aSpan links collect: [ :each | self linkDataFor: each ]) asArray;
		at: 'status' put: (self statusDataFor: aSpan);
		at: 'flags' put: (self flagsForParentContext: parentContext traceFlagsHex: aSpan traceFlags).
	traceState := aSpan traceState.
	traceState ifNotNil: [
		traceState isEmpty ifFalse: [
			data at: 'traceState' put: traceState asHeaderValue ] ].
	aSpan droppedAttributesCount > 0 ifTrue: [
		data at: 'droppedAttributesCount' put: aSpan droppedAttributesCount ].
	aSpan droppedEventsCount > 0 ifTrue: [
		data at: 'droppedEventsCount' put: aSpan droppedEventsCount ].
	aSpan droppedLinksCount > 0 ifTrue: [
		data at: 'droppedLinksCount' put: aSpan droppedLinksCount ].
	^ data
]

{ #category : 'private - encoding' }
OTOtlpJsonTraceEncoder >> statusDataFor: aSpan [

	| data |
	data := OrderedDictionary new.
	aSpan status = OTSpan ok ifTrue: [
		data at: 'code' put: 1.
		^ data ].
	aSpan status = OTSpan error ifTrue: [
		data at: 'code' put: 2.
		aSpan statusDescription ifNotEmpty: [
			data at: 'message' put: aSpan statusDescription ] ].
	^ data
]

{ #category : 'private - encoding' }
OTOtlpJsonTraceEncoder >> unixNanosecondsStringFor: aDateAndTime [

	| value |
	value := (((aDateAndTime ifNil: [ DateAndTime unixEpoch ]) offset: Duration zero)
		          - DateAndTime unixEpoch) asNanoSeconds.
	^ value asString
]
