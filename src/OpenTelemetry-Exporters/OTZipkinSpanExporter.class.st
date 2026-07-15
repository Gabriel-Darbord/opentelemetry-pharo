"
I am an exporter specifically for the [Zipkin](https://zipkin.io/) distributed tracing system.
"
Class {
	#name : 'OTZipkinSpanExporter',
	#superclass : 'OTSpanExporter',
	#instVars : [
		'httpClient'
	],
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'private - utilities' }
OTZipkinSpanExporter >> addDroppedCountTagsFrom: aSpan to: tags [

	aSpan droppedAttributesCount > 0 ifTrue: [
		tags at: 'otel.dropped_attributes_count' put: (self tagStringFor: aSpan droppedAttributesCount) ].
	aSpan droppedEventsCount > 0 ifTrue: [
		tags at: 'otel.dropped_events_count' put: (self tagStringFor: aSpan droppedEventsCount) ].
	aSpan droppedLinksCount > 0 ifTrue: [
		tags at: 'otel.dropped_links_count' put: (self tagStringFor: aSpan droppedLinksCount) ].
	^ tags
]

{ #category : 'private - utilities' }
OTZipkinSpanExporter >> addInstrumentationScopeTagsFrom: aSpan to: tags [

	| scope |
	scope := aSpan instrumentationScope.
	scope isEmpty ifTrue: [ ^ tags ].
	scope name ifNotEmpty: [
		tags
			at: 'otel.scope.name' put: scope name;
			at: 'otel.library.name' put: scope name ].
	scope version ifNotEmpty: [
		tags
			at: 'otel.scope.version' put: scope version;
			at: 'otel.library.version' put: scope version ].
	scope allAttributes associationsDo: [ :each |
		tags at: each key put: (self tagStringFor: each value) ].
	^ tags
]

{ #category : 'private - utilities' }
OTZipkinSpanExporter >> annotationValueFor: anEvent [

	| eventAttributes |
	eventAttributes := self exportableEventAttributesFor: anEvent.
	^ eventAttributes isEmpty
		ifTrue: [ anEvent name ]
		ifFalse: [ anEvent name , (String with: $: with: Character space) , (self formattedAttributes: eventAttributes) ]
]

{ #category : 'private - utilities' }
OTZipkinSpanExporter >> annotationsFor: someEvents [

	^ someEvents collect: [ :each |
		Dictionary new
			at: 'timestamp' put: each timestamp asUnixMicroseconds;
			at: 'value' put: (self annotationValueFor: each);
			yourself ]
]

{ #category : 'exporting' }
OTZipkinSpanExporter >> export: spans [

	self isShutdown ifTrue: [ ^ false ].
	^ (self httpClient
		   contents: (self transform: spans);
		   execute;
		   response) code = 202
]

{ #category : 'private - utilities' }
OTZipkinSpanExporter >> exportableEventAttributesFor: anEvent [

	| exported |
	exported := anEvent allAttributes copy.
	anEvent droppedAttributesCount > 0 ifTrue: [
		exported at: 'otel.dropped_attributes_count' put: anEvent droppedAttributesCount ].
	^ exported
]

{ #category : 'private - utilities' }
OTZipkinSpanExporter >> exportableTagsFor: aSpan [

	| tags |
	tags := Dictionary new.
	aSpan attributes ifNotNil: [ :attributes |
		attributes associationsDo: [ :each |
			tags at: each key put: (self tagStringFor: each value) ] ].
	self addInstrumentationScopeTagsFrom: aSpan to: tags.
	self addDroppedCountTagsFrom: aSpan to: tags.
	aSpan status = OTSpan unset ifFalse: [
		tags at: 'otel.status_code' put: aSpan status asString.
		aSpan status = OTSpan error ifTrue: [
			tags at: 'error' put: (aSpan statusDescription ifNil: [ '' ]) ] ].
	^ tags
]

{ #category : 'private - utilities' }
OTZipkinSpanExporter >> formattedAttributes: someAttributes [

	^ String streamContents: [ :stream |
		stream nextPut: ${.
		someAttributes associations doWithIndex: [ :each :index |
			index > 1 ifTrue: [ stream nextPut: $,; space ].
			stream
				nextPut: $';
				nextPutAll: each key asString;
				nextPut: $';
				nextPut: $:;
				nextPut: $';
				nextPutAll: each value asString;
				nextPut: $' ].
		stream nextPut: $} ]
]

{ #category : 'private - utilities' }
OTZipkinSpanExporter >> formattedAttributesFor: anEvent [

	^ self formattedAttributes: (self exportableEventAttributesFor: anEvent)
]

{ #category : 'accessing' }
OTZipkinSpanExporter >> httpClient [
	"Configured to localhost:9411 by default."

	^ httpClient ifNil: [
		  (httpClient := ZnClient new)
			  http;
			  host: 'localhost';
			  port: 9411;
			  addPathSegment: 'api';
			  addPathSegment: 'v2';
			  addPathSegment: 'spans';
			  method: #POST;
			  accept: ZnMimeType applicationJson;
			  contentWriter: [ :data |
				  ZnEntity json: (ZnUtils defaultJSONWriter toString: data) ] ]
]

{ #category : 'private - utilities' }
OTZipkinSpanExporter >> serviceNameFor: aSpan [

	^ aSpan resource serviceName
		ifNil: [ aSpan instrumentationName ]
]

{ #category : 'private - utilities' }
OTZipkinSpanExporter >> tagStringFor: anObject [

	anObject isNil ifTrue: [ ^ '' ].
	(anObject isString or: [ anObject isSymbol ]) ifTrue: [ ^ anObject asString ].
	(anObject == true) ifTrue: [ ^ 'true' ].
	(anObject == false) ifTrue: [ ^ 'false' ].
	anObject isNumber ifTrue: [ ^ anObject asString ].
	anObject isCollection ifTrue: [
		^ ZnUtils defaultJSONWriter toString: anObject ].
	^ anObject asString
]

{ #category : 'private - utilities' }
OTZipkinSpanExporter >> transform: spans [
	"Transform OpenTelemetry spans into the Zipkin format following the rules at https://opentelemetry.io/docs/specs/otel/trace/sdk_exporters/zipkin/"

	^ spans collect: [ :span |
		| data tags spanEvents |
		data := Dictionary new.
		data
			at: 'traceId' put: span traceId;
			at: 'id' put: span spanId;
			at: 'name' put: span name;
			at: 'timestamp' put: span startTime asUnixMicroseconds;
			at: 'duration' put: (span endTime - span startTime) asMicroseconds.
		span parent ifNotNil: [ :parent |
			data at: 'parentId' put: parent spanId ].
		span kind ifNotNil: [ :kind |
			kind = OTSpan internal ifFalse: [ data at: 'kind' put: kind ] ].
		spanEvents := span events.
		spanEvents ifNotEmpty: [ data at: 'annotations' put: (self annotationsFor: spanEvents) ].
		tags := self exportableTagsFor: span.
		tags ifNotEmpty: [ data at: 'tags' put: tags ].
		data at: 'localEndpoint' put: (Dictionary new at: 'serviceName' put: (self serviceNameFor: span); yourself).
		data ]
]
