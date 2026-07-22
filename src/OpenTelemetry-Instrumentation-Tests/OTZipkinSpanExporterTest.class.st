Class {
	#name : 'OTZipkinSpanExporterTest',
	#superclass : 'TestCase',
	#instVars : [
		'exporter'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'running' }
OTZipkinSpanExporterTest >> setUp [

	super setUp.
	exporter := OTZipkinSpanExporter new
]

{ #category : 'private' }
OTZipkinSpanExporterTest >> spanWithKind: aSpanKind attributes: someAttributes [

	| provider span tracer |
	provider := OTTracerProvider new.
	provider
		spanProcessor: OTSimpleSpanProcessor new;
		idGenerator: (OTFixedIdGenerator traceIdHex: '12345678876543211234567887654321' spanIdHex: '8765432112345678' random: false).
	tracer := provider tracerNamed: 'exporter.test'.
	span := (tracer spanBuilderNamed: 'operation')
		        kind: aSpanKind;
		        startTimestamp: DateAndTime unixEpoch;
		        startSpan.
	span
		restoreAttributes: someAttributes;
		restoreResource: (OTResource attributes: (OrderedDictionary new
						  at: 'service.name' put: 'local-service';
						  yourself));
		restoreInstrumentationScope: (OTInstrumentationScope named: 'demo.scope');
		end: DateAndTime unixEpoch + 1 second.
	^ span
]

{ #category : 'tests' }
OTZipkinSpanExporterTest >> testClientSpanFallsBackToNetworkPeerAddressAndPortForRemoteEndpoint [

	| remoteEndpoint transformed |
	transformed := self
		transformedSpanForKind: OTSpan client
		attributes: (OrderedDictionary new
			at: 'network.peer.address' put: '1.2.3.4';
			at: 'network.peer.port' put: 5678;
			yourself).
	remoteEndpoint := transformed at: 'remoteEndpoint'.
	self assert: (remoteEndpoint at: 'serviceName') equals: '1.2.3.4:5678'.
	self assert: (remoteEndpoint at: 'ipv4') equals: '1.2.3.4'.
	self assert: (remoteEndpoint at: 'port') equals: 5678
]

{ #category : 'tests' }
OTZipkinSpanExporterTest >> testClientSpanUsesHighestRankedRemoteEndpointAttribute [

	| remoteEndpoint transformed |
	transformed := self
		transformedSpanForKind: OTSpan client
		attributes: (OrderedDictionary new
			at: 'server.socket.address' put: '8.8.8.8';
			at: 'server.socket.port' put: 42;
			at: 'peer.address' put: 'peer-address';
			at: 'server.address' put: 'server-address';
			at: 'peer.service' put: 'peer-service';
			yourself).
	remoteEndpoint := transformed at: 'remoteEndpoint'.
	self assert: (remoteEndpoint at: 'serviceName') equals: 'peer-service'.
	self assert: (remoteEndpoint at: 'ipv4') equals: '8.8.8.8'.
	self assert: (remoteEndpoint at: 'port') equals: 42
]

{ #category : 'tests' }
OTZipkinSpanExporterTest >> testExportReturnsFalseOnClientFailureAndWarns [

	| client |
	client := OTRecordingHttpClient new.
	client shouldRaiseOnExecute: true.
	exporter httpClient: client.
	self withExporterWarningsDo: [ :warnings |
			self deny: (exporter export: { (self spanWithKind: OTSpan internal attributes: #(  )) }).
			self assert: client executionCount equals: 1.
			self assert: warnings size equals: 1.
			self assert: (warnings first includesSubstring: 'during export').
			self assert: (warnings first includesSubstring: 'OTZipkinSpanExporter').
			self assert: (warnings first includesSubstring: 'simulated HTTP failure') ]
]

{ #category : 'tests' }
OTZipkinSpanExporterTest >> testExportReturnsFalseOnNonAcceptedResponseCode [

	| client |
	client := OTRecordingHttpClient new.
	client responseCode: 500.
	exporter httpClient: client.
	self withExporterWarningsDo: [ :warnings |
			self deny: (exporter export: { (self spanWithKind: OTSpan internal attributes: #(  )) }).
			self assert: client executionCount equals: 1.
			self assert: warnings isEmpty ]
]

{ #category : 'tests' }
OTZipkinSpanExporterTest >> testServerSpanOmitsRemoteEndpointEvenWhenPeerAttributesExist [

	| transformed |
	transformed := self
		transformedSpanForKind: OTSpan server
		attributes: (OrderedDictionary new
			at: 'peer.service' put: 'peer-service';
			at: 'server.address' put: 'server-address';
			yourself).
	self deny: (transformed includesKey: 'remoteEndpoint')
]

{ #category : 'tests' }
OTZipkinSpanExporterTest >> testTransformIncludesReadableSpanFieldsInTagsAndParentMapping [

	| tags transformed |
	transformed := (exporter transform: { OTOtlpProtobufTraceEncoderTest new sampleSpan }) first.
	tags := transformed at: 'tags'.
	self assert: (transformed at: 'parentId') equals: 'bbbbbbbbbbbbbbbb'.
	self assert: ((transformed at: 'localEndpoint') at: 'serviceName') equals: 'demo-service'.
	self assert: (tags at: 'otel.scope.name') equals: 'demo.scope'.
	self assert: (tags at: 'otel.scope.version') equals: '1.2.3'.
	self assert: (tags at: 'otel.library.name') equals: 'demo.scope'.
	self assert: (tags at: 'otel.library.version') equals: '1.2.3'.
	self assert: (tags at: 'scope.attr') equals: 'true'.
	self assert: (tags at: 'otel.dropped_attributes_count') equals: '2'.
	self assert: (tags at: 'otel.dropped_events_count') equals: '3'.
	self assert: (tags at: 'otel.dropped_links_count') equals: '4'.
	self assert: (tags at: 'otel.status_code') equals: 'ERROR'.
	self assert: (tags at: 'error') equals: 'boom'
]

{ #category : 'tests' }
OTZipkinSpanExporterTest >> testUsesDefaultResourceServiceNameWhenSpanResourceHasNone [

	| span transformed |
	span := self spanWithKind: OTSpan internal attributes: #(  ).
	span restoreResource: OTResource empty.
	transformed := (exporter transform: { span }) first.
	self assert: ((transformed at: 'localEndpoint') at: 'serviceName') equals: OTTracerProvider defaultResource serviceName
]

{ #category : 'private' }
OTZipkinSpanExporterTest >> transformedSpanForKind: aSpanKind attributes: someAttributes [

	^ (exporter transform: { (self spanWithKind: aSpanKind attributes: someAttributes) }) first
]

{ #category : 'private' }
OTZipkinSpanExporterTest >> withExporterWarningsDo: aBlock [

	| logger warnings |
	logger := OTDiagnosticLogger current.
	warnings := OrderedCollection new.
	OTDiagnosticLogger current: OTDiagnosticLogger new.
	OTSpanExporter warningSink: [ :message | warnings add: message ].
	[ ^ aBlock value: warnings ] ensure: [
			OTSpanExporter warningSink: nil.
			OTDiagnosticLogger current: logger ]
]
