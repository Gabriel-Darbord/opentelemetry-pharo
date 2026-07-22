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
OTZipkinSpanExporter >> addAddressDetailsFrom: attributes toEndpoint: endpoint [

	| addressAndPort address port |
	addressAndPort := self remoteEndpointAddressAndPortFrom: attributes.
	addressAndPort ifNil: [ ^ endpoint ].
	address := addressAndPort first.
	port := addressAndPort second.
	(self isProbablyIpv4Address: address) ifTrue: [ endpoint at: 'ipv4' put: address ].
	(self isProbablyIpv6Address: address) ifTrue: [ endpoint at: 'ipv6' put: address ].
	port ifNotNil: [ endpoint at: 'port' put: port ].
	^ endpoint
]

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

{ #category : 'private - utilities' }
OTZipkinSpanExporter >> endpointValueFromAddressAttribute: addressAttributeName portAttribute: portAttributeName in: attributes [

	| address port |
	address := self stringAttributeNamed: addressAttributeName in: attributes.
	address ifNil: [ ^ nil ].
	port := self stringAttributeNamed: portAttributeName in: attributes.
	^ port
		ifNil: [ address ]
		ifNotNil: [ address , ':' , port ]
]

{ #category : 'exporting' }
OTZipkinSpanExporter >> export: spans [

	^ self withExportLockDo: [
			  self isShutdown ifTrue: [ ^ false ].
			  (self httpClient
				   contents: (self transform: spans);
				   execute;
				   response) code = 202 ]
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
OTZipkinSpanExporter >> firstRemoteEndpointValueFrom: attributes [

	^ {
		self stringAttributeNamed: 'peer.service' in: attributes.
		self stringAttributeNamed: 'server.address' in: attributes.
		self stringAttributeNamed: 'net.peer.name' in: attributes.
		self endpointValueFromAddressAttribute: 'network.peer.address' portAttribute: 'network.peer.port' in: attributes.
		self stringAttributeNamed: 'server.socket.domain' in: attributes.
		self endpointValueFromAddressAttribute: 'server.socket.address' portAttribute: 'server.socket.port' in: attributes.
		self stringAttributeNamed: 'net.sock.peer.name' in: attributes.
		self endpointValueFromAddressAttribute: 'net.sock.peer.addr' portAttribute: 'net.sock.peer.port' in: attributes.
		self stringAttributeNamed: 'peer.hostname' in: attributes.
		self stringAttributeNamed: 'peer.address' in: attributes.
		self stringAttributeNamed: 'db.name' in: attributes }
		detect: [ :each | each notNil ]
		ifNone: [ nil ]
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
OTZipkinSpanExporter >> integerAttributeNamed: aString in: attributes [

	| value |
	attributes ifNil: [ ^ nil ].
	value := attributes at: aString ifAbsent: [ ^ nil ].
	value isInteger ifTrue: [ ^ value ].
	value := value asString trimBoth.
	value isEmpty ifTrue: [ ^ nil ].
	^ [ Integer readFrom: value readStream ]
		on: Error
		do: [ nil ]
]

{ #category : 'private - utilities' }
OTZipkinSpanExporter >> isProbablyIpv4Address: aString [

	aString ifNil: [ ^ false ].
	(aString includes: $:) ifTrue: [ ^ false ].
	^ aString isEmpty not and: [
		aString allSatisfy: [ :each | each isDigit or: [ each = $. ] ] ]
]

{ #category : 'private - utilities' }
OTZipkinSpanExporter >> isProbablyIpv6Address: aString [

	aString ifNil: [ ^ false ].
	(aString includes: $:) ifFalse: [ ^ false ].
	^ aString isEmpty not and: [
		aString allSatisfy: [ :each |
			each isDigit
				or: [ 'abcdefABCDEF' includes: each
				or: [ each = $: ] ] ] ]
]

{ #category : 'private - utilities' }
OTZipkinSpanExporter >> remoteEndpointAddressAndPortFrom: attributes [

	| address port |
	address := self stringAttributeNamed: 'network.peer.address' in: attributes.
	address ifNotNil: [
		port := self integerAttributeNamed: 'network.peer.port' in: attributes.
		^ { address. port } ].
	address := self stringAttributeNamed: 'server.socket.address' in: attributes.
	address ifNotNil: [
		port := self integerAttributeNamed: 'server.socket.port' in: attributes.
		^ { address. port } ].
	address := self stringAttributeNamed: 'net.sock.peer.addr' in: attributes.
	address ifNotNil: [
		port := self integerAttributeNamed: 'net.sock.peer.port' in: attributes.
		^ { address. port } ].
	^ nil
]

{ #category : 'private - utilities' }
OTZipkinSpanExporter >> remoteEndpointFor: aSpan [

	| endpoint endpointValue |
	((aSpan kind = OTSpan client) or: [ aSpan kind = OTSpan producer ]) ifFalse: [ ^ nil ].
	endpointValue := self firstRemoteEndpointValueFrom: aSpan attributes.
	endpointValue ifNil: [ ^ nil ].
	endpoint := Dictionary new
		at: 'serviceName' put: endpointValue;
		yourself.
	^ self addAddressDetailsFrom: aSpan attributes toEndpoint: endpoint
]

{ #category : 'private - utilities' }
OTZipkinSpanExporter >> serviceNameFor: aSpan [

	^ aSpan resource serviceName
		ifNil: [ OTTracerProvider defaultResource serviceName ]
]

{ #category : 'private - utilities' }
OTZipkinSpanExporter >> stringAttributeNamed: aString in: attributes [

	| value |
	attributes ifNil: [ ^ nil ].
	value := attributes at: aString ifAbsent: [ ^ nil ].
	value := value asString trimBoth.
	^ value isEmpty ifTrue: [ nil ] ifFalse: [ value ]
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

	^ (spans ifNil: [ #(  ) ]) collect: [ :each |
			  | data parentContext remoteEndpoint span spanEvents tags |
			  span := OTSpanSnapshot fromExportableSpan: each.
			  data := Dictionary new.
			  parentContext := span parentSpanContext.
			  remoteEndpoint := self remoteEndpointFor: span.
			  data
				  at: 'traceId' put: span traceId;
				  at: 'id' put: span spanId;
				  at: 'name' put: span name;
				  at: 'timestamp' put: span startTime asUnixMicroseconds;
				  at: 'duration' put: (span endTime - span startTime) asMicroseconds.
			  parentContext ifNotNil: [ data at: 'parentId' put: parentContext spanId ].
			  span kind ifNotNil: [ :kind | kind = OTSpan internal ifFalse: [ data at: 'kind' put: kind ] ].
			  spanEvents := span events.
			  spanEvents ifNotEmpty: [ data at: 'annotations' put: (self annotationsFor: spanEvents) ].
			  tags := self exportableTagsFor: span.
			  tags ifNotEmpty: [ data at: 'tags' put: tags ].
			  data at: 'localEndpoint' put: (Dictionary new
					   at: 'serviceName' put: (self serviceNameFor: span);
					   yourself).
			  remoteEndpoint ifNotNil: [ data at: 'remoteEndpoint' put: remoteEndpoint ].
			  data ]
]
