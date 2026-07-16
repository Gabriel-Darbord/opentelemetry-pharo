"
An OTLP log encoder that emits protobuf-encoded ExportLogsServiceRequest payloads.
"
Class {
	#name : 'OTOtlpProtobufLogRecordEncoder',
	#superclass : 'OTOtlpProtobufTraceEncoder',
	#category : 'OpenTelemetry-Logs',
	#package : 'OpenTelemetry-Logs'
}

{ #category : 'encoding' }
OTOtlpProtobufLogRecordEncoder >> encodeLogRecords: someLogRecords [

	| writer |
	writer := OTProtobufWriter withBytes.
	(self groupedLogRecordsFrom: someLogRecords) associationsDo: [ :resourceGroup |
		writer
			writeTag: 1 wireType: 2;
			writeEmbedded: [ :resourceLogs |
				self
					encodeResource: resourceGroup key
					scopeGroups: resourceGroup value
					on: resourceLogs ] ].
	^ writer contents
]

{ #category : 'private - encoding' }
OTOtlpProtobufLogRecordEncoder >> encodeLogRecord: anOTLogRecord on: aWriter [

	| flags |
	anOTLogRecord timestamp ifNotNil: [
		aWriter
			writeTag: 1 wireType: 1;
			writeFixed64: (self unixNanosecondsFor: anOTLogRecord timestamp) ].
	anOTLogRecord severityNumber = OTSeverity undefined ifFalse: [
		aWriter
			writeTag: 2 wireType: 0;
			writeVarint: anOTLogRecord severityNumber ].
	anOTLogRecord severityText ifNotNil: [
		aWriter
			writeTag: 3 wireType: 2;
			writeString: anOTLogRecord severityText ].
	anOTLogRecord body ifNotNil: [
		aWriter
			writeTag: 5 wireType: 2;
			writeEmbedded: [ :value |
				self encodeAnyValue: anOTLogRecord body on: value ] ].
	self writeAttributes: anOTLogRecord attributes fieldNumber: 6 on: aWriter.
	anOTLogRecord droppedAttributesCount > 0 ifTrue: [
		aWriter
			writeTag: 7 wireType: 0;
			writeVarint: anOTLogRecord droppedAttributesCount ].
	flags := self flagsForLogRecord: anOTLogRecord.
	flags = 0 ifFalse: [
		aWriter
			writeTag: 8 wireType: 5;
			writeFixed32: flags ].
	anOTLogRecord traceId ifNotNil: [
		aWriter
			writeTag: 9 wireType: 2;
			writeBytes: (OTSpanContext
				 byteArrayFromHex: anOTLogRecord traceId
				 size: 16) ].
	anOTLogRecord spanId ifNotNil: [
		aWriter
			writeTag: 10 wireType: 2;
			writeBytes: (OTSpanContext
				 byteArrayFromHex: anOTLogRecord spanId
				 size: 8) ].
	anOTLogRecord observedTimestamp ifNotNil: [
		aWriter
			writeTag: 11 wireType: 1;
			writeFixed64: (self unixNanosecondsFor: anOTLogRecord observedTimestamp) ].
	anOTLogRecord eventName ifNotNil: [
		aWriter
			writeTag: 12 wireType: 2;
			writeString: anOTLogRecord eventName ]
]

{ #category : 'private - encoding' }
OTOtlpProtobufLogRecordEncoder >> encodeResource: aResource scopeGroups: scopeGroups on: aWriter [

	aWriter
		writeTag: 1 wireType: 2;
		writeEmbedded: [ :resource |
			self encodeResource: aResource on: resource ].
	scopeGroups associationsDo: [ :scopeGroup |
		aWriter
			writeTag: 2 wireType: 2;
			writeEmbedded: [ :scopeLogs |
				self
					encodeScope: scopeGroup key
					logRecords: scopeGroup value
					on: scopeLogs ] ].
	aResource schemaUrl ifNotEmpty: [
		aWriter
			writeTag: 3 wireType: 2;
			writeString: aResource schemaUrl ]
]

{ #category : 'private - encoding' }
OTOtlpProtobufLogRecordEncoder >> encodeScope: anInstrumentationScope logRecords: someLogRecords on: aWriter [

	aWriter
		writeTag: 1 wireType: 2;
		writeEmbedded: [ :scope |
			self encodeInstrumentationScope: anInstrumentationScope on: scope ].
	someLogRecords do: [ :logRecord |
		aWriter
			writeTag: 2 wireType: 2;
			writeEmbedded: [ :embedded |
				self encodeLogRecord: logRecord on: embedded ] ].
	anInstrumentationScope schemaUrl ifNotEmpty: [
		aWriter
			writeTag: 3 wireType: 2;
			writeString: anInstrumentationScope schemaUrl ]
]

{ #category : 'private - encoding' }
OTOtlpProtobufLogRecordEncoder >> flagsForLogRecord: anOTLogRecord [

	| traceFlags |
	traceFlags := anOTLogRecord traceFlags.
	traceFlags ifNil: [ ^ 0 ].
	traceFlags := traceFlags asString.
	traceFlags isEmpty ifTrue: [ ^ 0 ].
	^ Integer readFrom: traceFlags readStream base: 16
]

{ #category : 'private - encoding' }
OTOtlpProtobufLogRecordEncoder >> groupedLogRecordsFrom: someLogRecords [

	| groupedLogRecords |
	groupedLogRecords := OrderedDictionary new.
	(someLogRecords ifNil: [ #() ]) do: [ :eachLogRecord |
		| resource scope scopeGroups |
		resource := eachLogRecord resource.
		scope := eachLogRecord instrumentationScope.
		scopeGroups := groupedLogRecords
			at: resource
			ifAbsentPut: [ OrderedDictionary new ].
		(scopeGroups
			at: scope
			ifAbsentPut: [ OrderedCollection new ]) add: eachLogRecord ].
	^ groupedLogRecords
]
