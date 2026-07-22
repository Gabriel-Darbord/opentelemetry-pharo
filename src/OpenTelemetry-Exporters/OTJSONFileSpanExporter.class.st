"
I am used for exporting spans to local files in JSON format.
By default, spans are exported to the `pharo-local/OpenTelemetry/traces` folder of the image.
"
Class {
	#name : 'OTJSONFileSpanExporter',
	#superclass : 'OTFileSpanExporter',
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'exporting' }
OTJSONFileSpanExporter >> export: spans [

	^ self withExportLockDo: [
			  self isShutdown ifTrue: [ ^ false ].
			  self withOperationNamed: 'export' default: false do: [
					  (self directory asFileReference / DateAndTime now asString , 'json') ensureCreateFile writeStreamDo: [ :stream |
						  STON put: (spans collect: [ :each | self jsonValueFrom: each asExportRecord ]) asArray asJsonOnStream: stream ].
					  true ] ]
]

{ #category : 'private' }
OTJSONFileSpanExporter >> jsonValueFrom: anObject [

	| converted |
	anObject isNil ifTrue: [ ^ nil ].
	(anObject isString or: [ anObject isNumber ]) ifTrue: [ ^ anObject ].
	anObject == true ifTrue: [ ^ true ].
	anObject == false ifTrue: [ ^ false ].
	anObject isSymbol ifTrue: [ ^ anObject asString ].
	(anObject isKindOf: DateAndTime) ifTrue: [ ^ anObject asString ].
	(anObject isKindOf: ByteArray) ifTrue: [ ^ anObject asArray ].
	(anObject isKindOf: OTSpanContext) ifTrue: [ ^ self jsonValueFromSpanContext: anObject ].
	(anObject isKindOf: OTInstrumentationScope) ifTrue: [ ^ self jsonValueFromInstrumentationScope: anObject ].
	(anObject isKindOf: OTResource) ifTrue: [ ^ self jsonValueFromResource: anObject ].
	(anObject isKindOf: OTSpanEvent) ifTrue: [ ^ self jsonValueFromSpanEvent: anObject ].
	(anObject isKindOf: OTSpanLink) ifTrue: [ ^ self jsonValueFromSpanLink: anObject ].
	(anObject isKindOf: OTTraceState) ifTrue: [ ^ anObject asHeaderValue ].
	anObject isDictionary ifTrue: [
			converted := OrderedDictionary new.
			anObject associationsDo: [ :each | converted at: each key asString put: (self jsonValueFrom: each value) ].
			^ converted ].
	(anObject isCollection and: [ anObject isString not ]) ifTrue: [ ^ anObject collect: [ :each | self jsonValueFrom: each ] ].
	^ anObject asString
]

{ #category : 'private' }
OTJSONFileSpanExporter >> jsonValueFromInstrumentationScope: anInstrumentationScope [

	| data |
	data := OrderedDictionary new.
	data at: 'name' put: anInstrumentationScope name.
	anInstrumentationScope version ifNotEmpty: [ data at: 'version' put: anInstrumentationScope version ].
	anInstrumentationScope schemaUrl ifNotEmpty: [ data at: 'schemaUrl' put: anInstrumentationScope schemaUrl ].
	anInstrumentationScope attributes ifNotEmpty: [
		data at: 'attributes' put: (self jsonValueFrom: anInstrumentationScope attributes) ].
	^ data
]

{ #category : 'private' }
OTJSONFileSpanExporter >> jsonValueFromResource: aResource [

	| data |
	data := OrderedDictionary new.
	aResource attributes ifNotEmpty: [ data at: 'attributes' put: (self jsonValueFrom: aResource attributes) ].
	aResource schemaUrl ifNotEmpty: [ data at: 'schemaUrl' put: aResource schemaUrl ].
	^ data
]

{ #category : 'private' }
OTJSONFileSpanExporter >> jsonValueFromSpanContext: aSpanContext [

	| data |
	data := OrderedDictionary new.
	data
		at: 'traceId' put: aSpanContext traceId;
		at: 'spanId' put: aSpanContext spanId;
		at: 'traceFlags' put: aSpanContext traceFlags;
		at: 'remote' put: aSpanContext isRemote.
	aSpanContext traceState ifNotNil: [ :aTraceState | data at: 'traceState' put: aTraceState asHeaderValue ].
	^ data
]

{ #category : 'private' }
OTJSONFileSpanExporter >> jsonValueFromSpanEvent: anEvent [

	| data |
	data := OrderedDictionary new.
	data
		at: 'name' put: anEvent name;
		at: 'timestamp' put: anEvent timestamp asString.
	anEvent attributes ifNotEmpty: [ data at: 'attributes' put: (self jsonValueFrom: anEvent attributes) ].
	anEvent droppedAttributesCount > 0 ifTrue: [ data at: 'droppedAttributesCount' put: anEvent droppedAttributesCount ].
	^ data
]

{ #category : 'private' }
OTJSONFileSpanExporter >> jsonValueFromSpanLink: aLink [

	| data |
	data := OrderedDictionary new.
	data at: 'spanContext' put: (self jsonValueFromSpanContext: aLink spanContext).
	aLink attributes ifNotEmpty: [ data at: 'attributes' put: (self jsonValueFrom: aLink attributes) ].
	aLink droppedAttributesCount > 0 ifTrue: [ data at: 'droppedAttributesCount' put: aLink droppedAttributesCount ].
	^ data
]
