"
An OTLP log encoder that emits the OpenTelemetry JSON protobuf shape for ExportLogsServiceRequest payloads.
"
Class {
	#name : 'OTOtlpJsonLogRecordEncoder',
	#superclass : 'OTOtlpJsonTraceEncoder',
	#category : 'OpenTelemetry-Logs',
	#package : 'OpenTelemetry-Logs'
}

{ #category : 'encoding' }
OTOtlpJsonLogRecordEncoder >> encodeLogRecords: someLogRecords [

	^ OrderedDictionary new
		at: 'resourceLogs' put: (self resourceLogsDataFor: someLogRecords);
		yourself
]

{ #category : 'private - encoding' }
OTOtlpJsonLogRecordEncoder >> flagsForLogRecord: anOTLogRecord [

	| traceFlags |
	traceFlags := anOTLogRecord traceFlags.
	traceFlags ifNil: [ ^ 0 ].
	traceFlags := traceFlags asString.
	traceFlags isEmpty ifTrue: [ ^ 0 ].
	^ Integer readFrom: traceFlags readStream base: 16
]

{ #category : 'private - encoding' }
OTOtlpJsonLogRecordEncoder >> groupedLogRecordsFrom: someLogRecords [

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

{ #category : 'private - encoding' }
OTOtlpJsonLogRecordEncoder >> logRecordDataFor: anOTLogRecord [

	| data flags |
	data := OrderedDictionary new.
	anOTLogRecord timestamp ifNotNil: [
		data
			at: 'timeUnixNano'
			put: (self unixNanosecondsStringFor: anOTLogRecord timestamp) ].
	anOTLogRecord observedTimestamp ifNotNil: [
		data
			at: 'observedTimeUnixNano'
			put: (self unixNanosecondsStringFor: anOTLogRecord observedTimestamp) ].
	anOTLogRecord severityNumber = OTSeverity undefined ifFalse: [
		data at: 'severityNumber' put: anOTLogRecord severityNumber ].
	anOTLogRecord severityText ifNotNil: [
		data at: 'severityText' put: anOTLogRecord severityText ].
	anOTLogRecord body ifNotNil: [
		data at: 'body' put: (self anyValueDataFor: anOTLogRecord body) ].
	anOTLogRecord attributes ifNotEmpty: [
		data at: 'attributes' put: (self keyValueDataFrom: anOTLogRecord attributes) ].
	anOTLogRecord droppedAttributesCount > 0 ifTrue: [
		data
			at: 'droppedAttributesCount'
			put: anOTLogRecord droppedAttributesCount ].
	flags := self flagsForLogRecord: anOTLogRecord.
	flags = 0 ifFalse: [ data at: 'flags' put: flags ].
	anOTLogRecord traceId ifNotNil: [ data at: 'traceId' put: anOTLogRecord traceId ].
	anOTLogRecord spanId ifNotNil: [ data at: 'spanId' put: anOTLogRecord spanId ].
	anOTLogRecord eventName ifNotNil: [
		data at: 'eventName' put: anOTLogRecord eventName ].
	^ data
]

{ #category : 'private - encoding' }
OTOtlpJsonLogRecordEncoder >> resourceLogsDataFor: someLogRecords [

	^ (self groupedLogRecordsFrom: someLogRecords) associations collect: [
		  :eachResourceGroup |
		  self
			  resourceLogsDataForResource: eachResourceGroup key
			  scopeGroups: eachResourceGroup value ]
]

{ #category : 'private - encoding' }
OTOtlpJsonLogRecordEncoder >> resourceLogsDataForResource: aResource scopeGroups: scopeGroups [

	| data |
	data := OrderedDictionary new.
	data
		at: 'resource' put: (self resourceDataFor: aResource);
		at: 'scopeLogs' put: (scopeGroups associations collect: [ :eachScopeGroup |
				 self
					 scopeLogsDataForScope: eachScopeGroup key
					 logRecords: eachScopeGroup value ]) asArray.
	aResource schemaUrl ifNotEmpty: [
		data at: 'schemaUrl' put: aResource schemaUrl ].
	^ data
]

{ #category : 'private - encoding' }
OTOtlpJsonLogRecordEncoder >> scopeLogsDataForScope: anInstrumentationScope logRecords: someLogRecords [

	| data |
	data := OrderedDictionary new.
	data
		at: 'scope' put: (self scopeDataFor: anInstrumentationScope);
		at: 'logRecords'
			put: (someLogRecords collect: [ :each | self logRecordDataFor: each ])
					asArray.
	anInstrumentationScope schemaUrl ifNotEmpty: [
		data at: 'schemaUrl' put: anInstrumentationScope schemaUrl ].
	^ data
]
