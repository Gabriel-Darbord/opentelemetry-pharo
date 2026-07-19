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
		        startSpan.
	span
		startTime: DateAndTime unixEpoch;
		endTime: DateAndTime unixEpoch + 1 second;
		attributes: someAttributes;
		resource: (OTResource attributes: (OrderedDictionary new
						  at: 'service.name' put: 'local-service';
						  yourself));
		instrumentationScope: (OTInstrumentationScope named: 'demo.scope').
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
OTZipkinSpanExporterTest >> testUsesDefaultResourceServiceNameWhenSpanResourceHasNone [

	| span transformed |
	span := self spanWithKind: OTSpan internal attributes: #().
	span resource: OTResource empty.
	transformed := (exporter transform: { span }) first.
	self
		assert: ((transformed at: 'localEndpoint') at: 'serviceName')
		equals: OTTracerProvider defaultResource serviceName
]

{ #category : 'private' }
OTZipkinSpanExporterTest >> transformedSpanForKind: aSpanKind attributes: someAttributes [

	^ (exporter transform: { (self spanWithKind: aSpanKind attributes: someAttributes) }) first
]
