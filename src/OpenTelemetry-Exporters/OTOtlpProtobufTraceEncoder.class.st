"
An OTLP trace encoder that emits protobuf-encoded ExportTraceServiceRequest payloads.
"
Class {
	#name : 'OTOtlpProtobufTraceEncoder',
	#superclass : 'OTOtlpTraceEncoder',
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'private - encoding' }
OTOtlpProtobufTraceEncoder >> encodeAnyValue: anObject on: aWriter [

	anObject isNil ifTrue: [ ^ self ].
	((anObject isString) or: [ anObject isSymbol ]) ifTrue: [
		aWriter
			writeTag: 1 wireType: 2;
			writeString: anObject asString.
		^ self ].
	(OTAttributeNormalizer isBoolean: anObject) ifTrue: [
		aWriter
			writeTag: 2 wireType: 0;
			writeVarint: (anObject ifTrue: [ 1 ] ifFalse: [ 0 ]).
		^ self ].
	anObject isInteger ifTrue: [
		aWriter
			writeTag: 3 wireType: 0;
			writeVarint: anObject.
		^ self ].
	anObject isNumber ifTrue: [
		aWriter
			writeTag: 4 wireType: 1;
			writeFixed64: anObject asFloat asIEEE64BitWord.
		^ self ].
	(anObject isKindOf: ByteArray) ifTrue: [
		aWriter
			writeTag: 7 wireType: 2;
			writeBytes: anObject.
		^ self ].
	(OTAttributeNormalizer isMapValue: anObject) ifTrue: [
		aWriter
			writeTag: 6 wireType: 2;
			writeEmbedded: [ :nested |
				self writeKeyValues: anObject associations fieldNumber: 1 on: nested ].
		^ self ].
	anObject isCollection ifTrue: [
		aWriter
			writeTag: 5 wireType: 2;
			writeEmbedded: [ :nested |
				anObject do: [ :each |
					nested
						writeTag: 1 wireType: 2;
						writeEmbedded: [ :anyValue |
							self encodeAnyValue: each on: anyValue ] ] ].
		^ self ].
	Error signal: 'Unsupported OTLP AnyValue: ' , anObject printString
]

{ #category : 'private - encoding' }
OTOtlpProtobufTraceEncoder >> encodeEvent: anEvent on: aWriter [

	aWriter
		writeTag: 1 wireType: 1;
		writeFixed64: (self unixNanosecondsFor: anEvent timestamp);
		writeTag: 2 wireType: 2;
		writeString: anEvent name.
	self writeAttributes: anEvent attributes fieldNumber: 3 on: aWriter.
	aWriter
		writeTag: 4 wireType: 0;
		writeVarint: anEvent droppedAttributesCount
]

{ #category : 'private - encoding' }
OTOtlpProtobufTraceEncoder >> encodeInstrumentationScope: anInstrumentationScope on: aWriter [

	anInstrumentationScope name ifNotEmpty: [
		aWriter
			writeTag: 1 wireType: 2;
			writeString: anInstrumentationScope name ].
	anInstrumentationScope version ifNotEmpty: [
		aWriter
			writeTag: 2 wireType: 2;
			writeString: anInstrumentationScope version ].
	self writeAttributes: anInstrumentationScope allAttributes fieldNumber: 3 on: aWriter.
	aWriter
		writeTag: 4 wireType: 0;
		writeVarint: 0
]

{ #category : 'private - encoding' }
OTOtlpProtobufTraceEncoder >> encodeLink: aLink on: aWriter [

	| linkContext |
	linkContext := aLink spanContext.
	aWriter
		writeTag: 1 wireType: 2;
		writeBytes: linkContext traceIdBytes;
		writeTag: 2 wireType: 2;
		writeBytes: linkContext spanIdBytes.
	linkContext traceState ifNotNil: [ :traceState |
		traceState isEmpty ifFalse: [
			aWriter
				writeTag: 3 wireType: 2;
				writeString: traceState asHeaderValue ] ].
	self writeAttributes: aLink attributes fieldNumber: 4 on: aWriter.
	aWriter
		writeTag: 5 wireType: 0;
		writeVarint: aLink droppedAttributesCount.
	(self flagsForSpanContext: linkContext) = 0 ifFalse: [
		aWriter
			writeTag: 6 wireType: 5;
			writeFixed32: (self flagsForSpanContext: linkContext) ]
]

{ #category : 'private - encoding' }
OTOtlpProtobufTraceEncoder >> encodeResource: aResource on: aWriter [

	self writeAttributes: aResource allAttributes fieldNumber: 1 on: aWriter.
	aWriter
		writeTag: 2 wireType: 0;
		writeVarint: 0
]

{ #category : 'private - encoding' }
OTOtlpProtobufTraceEncoder >> encodeResource: aResource scopeGroups: scopeGroups on: aWriter [

	aWriter
		writeTag: 1 wireType: 2;
		writeEmbedded: [ :resource |
			self encodeResource: aResource on: resource ].
	scopeGroups associationsDo: [ :scopeGroup |
		aWriter
			writeTag: 2 wireType: 2;
			writeEmbedded: [ :scopeSpans |
				self
					encodeScope: scopeGroup key
					spans: scopeGroup value
					on: scopeSpans ] ].
	aResource schemaUrl ifNotEmpty: [
		aWriter
			writeTag: 3 wireType: 2;
			writeString: aResource schemaUrl ]
]

{ #category : 'private - encoding' }
OTOtlpProtobufTraceEncoder >> encodeScope: anInstrumentationScope spans: someSpans on: aWriter [

	aWriter
		writeTag: 1 wireType: 2;
		writeEmbedded: [ :scope |
			self encodeInstrumentationScope: anInstrumentationScope on: scope ].
	someSpans do: [ :span |
		aWriter
			writeTag: 2 wireType: 2;
			writeEmbedded: [ :embedded |
				self encodeSpan: span on: embedded ] ].
	anInstrumentationScope schemaUrl ifNotEmpty: [
		aWriter
			writeTag: 3 wireType: 2;
			writeString: anInstrumentationScope schemaUrl ]
]

{ #category : 'private - encoding' }
OTOtlpProtobufTraceEncoder >> encodeSpan: aSpan on: aWriter [

	| parentContext traceState |
	parentContext := aSpan parentSpanContext.
	aWriter
		writeTag: 1 wireType: 2;
		writeBytes: aSpan spanContext traceIdBytes;
		writeTag: 2 wireType: 2;
		writeBytes: aSpan spanContext spanIdBytes.
	traceState := aSpan traceState.
	traceState ifNotNil: [
		traceState isEmpty ifFalse: [
			aWriter
				writeTag: 3 wireType: 2;
				writeString: traceState asHeaderValue ] ].
	parentContext ifNotNil: [
		aWriter
			writeTag: 4 wireType: 2;
			writeBytes: parentContext spanIdBytes ].
	aWriter
		writeTag: 5 wireType: 2;
		writeString: aSpan name.
	(self kindCodeFor: aSpan) = 0 ifFalse: [
		aWriter
			writeTag: 6 wireType: 0;
			writeVarint: (self kindCodeFor: aSpan) ].
	aWriter
		writeTag: 7 wireType: 1;
		writeFixed64: (self unixNanosecondsFor: aSpan startTime);
		writeTag: 8 wireType: 1;
		writeFixed64: (self unixNanosecondsFor: aSpan endTime).
	self writeAttributes: aSpan attributes fieldNumber: 9 on: aWriter.
	aWriter
		writeTag: 10 wireType: 0;
		writeVarint: aSpan droppedAttributesCount.
	aSpan events do: [ :event |
		aWriter
			writeTag: 11 wireType: 2;
			writeEmbedded: [ :embedded |
				self encodeEvent: event on: embedded ] ].
	aWriter
		writeTag: 12 wireType: 0;
		writeVarint: aSpan droppedEventsCount.
	aSpan links do: [ :link |
		aWriter
			writeTag: 13 wireType: 2;
			writeEmbedded: [ :embedded |
				self encodeLink: link on: embedded ] ].
	aWriter
		writeTag: 14 wireType: 0;
		writeVarint: aSpan droppedLinksCount;
		writeTag: 15 wireType: 2;
		writeEmbedded: [ :status |
			self encodeStatusFor: aSpan on: status ].
	(self flagsForParentContext: parentContext traceFlagsHex: aSpan traceFlags) = 0 ifFalse: [
		aWriter
			writeTag: 16 wireType: 5;
			writeFixed32: (self
				 flagsForParentContext: parentContext
				 traceFlagsHex: aSpan traceFlags) ]
]

{ #category : 'encoding' }
OTOtlpProtobufTraceEncoder >> encodeSpans: someSpans [

	| writer |
	writer := OTProtobufWriter withBytes.
	(self groupedSpansFrom: someSpans) associationsDo: [ :resourceGroup |
		writer
			writeTag: 1 wireType: 2;
			writeEmbedded: [ :resourceSpans |
				self
					encodeResource: resourceGroup key
					scopeGroups: resourceGroup value
					on: resourceSpans ] ].
	^ writer contents
]

{ #category : 'private - encoding' }
OTOtlpProtobufTraceEncoder >> encodeStatusFor: aSpan on: aWriter [

	| description |
	description := aSpan statusDescription.
	description ifNotNil: [
		description ifNotEmpty: [
			aWriter
				writeTag: 2 wireType: 2;
				writeString: description ] ].
	aWriter
		writeTag: 3 wireType: 0;
		writeVarint: (self statusCodeFor: aSpan)
]

{ #category : 'private - encoding' }
OTOtlpProtobufTraceEncoder >> flagsForParentContext: aSpanContext traceFlagsHex: aString [

	| flags |
	flags := Integer readFrom: aString readStream base: 16.
	aSpanContext ifNil: [ ^ flags ].
	flags := flags bitOr: 16r100.
	aSpanContext isRemote ifTrue: [ flags := flags bitOr: 16r200 ].
	^ flags
]

{ #category : 'private - encoding' }
OTOtlpProtobufTraceEncoder >> flagsForSpanContext: aSpanContext [

	^ self
		flagsForParentContext: aSpanContext
		traceFlagsHex: aSpanContext traceFlags
]

{ #category : 'private - encoding' }
OTOtlpProtobufTraceEncoder >> groupedSpansFrom: someSpans [

	| groupedSpans |
	groupedSpans := OrderedDictionary new.
	(self normalizedSpansFrom: someSpans) do: [ :eachSpan |
			| resource scope scopeGroups |
			resource := eachSpan resource.
			scope := eachSpan instrumentationScope.
			scopeGroups := groupedSpans at: resource ifAbsentPut: [ OrderedDictionary new ].
			(scopeGroups at: scope ifAbsentPut: [ OrderedCollection new ]) add: eachSpan ].
	^ groupedSpans
]

{ #category : 'private - encoding' }
OTOtlpProtobufTraceEncoder >> kindCodeFor: aSpan [

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
OTOtlpProtobufTraceEncoder >> statusCodeFor: aSpan [

	aSpan status = OTSpan ok ifTrue: [ ^ 1 ].
	aSpan status = OTSpan error ifTrue: [ ^ 2 ].
	^ 0
]

{ #category : 'private - encoding' }
OTOtlpProtobufTraceEncoder >> unixNanosecondsFor: aDateAndTime [

	^ (((aDateAndTime ifNil: [ DateAndTime unixEpoch ]) offset: Duration zero)
		   - DateAndTime unixEpoch) asNanoSeconds
]

{ #category : 'private - encoding' }
OTOtlpProtobufTraceEncoder >> writeAttributes: aCollection fieldNumber: aFieldNumber on: aWriter [

	self writeKeyValues: aCollection associations fieldNumber: aFieldNumber on: aWriter
]

{ #category : 'private - encoding' }
OTOtlpProtobufTraceEncoder >> writeKeyValue: anAssociation on: aWriter [

	aWriter
		writeTag: 1 wireType: 2;
		writeString: anAssociation key asString;
		writeTag: 2 wireType: 2;
		writeEmbedded: [ :value |
			self encodeAnyValue: anAssociation value on: value ]
]

{ #category : 'private - encoding' }
OTOtlpProtobufTraceEncoder >> writeKeyValues: someAssociations fieldNumber: aFieldNumber on: aWriter [

	someAssociations do: [ :association |
		aWriter
			writeTag: aFieldNumber wireType: 2;
			writeEmbedded: [ :keyValue |
				self writeKeyValue: association on: keyValue ] ]
]
