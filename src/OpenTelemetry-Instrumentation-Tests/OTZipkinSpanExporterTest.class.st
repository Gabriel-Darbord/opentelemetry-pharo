Class {
	#name : 'OTZipkinSpanExporterTest',
	#superclass : 'TestCase',
	#instVars : [
		'exporter'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'private' }
OTZipkinSpanExporterTest >> spanWithKind: aSpanKind attributes: someAttributes [

	| span |
	span := OTSpan new.
	span
		traceId: '12345678876543211234567887654321';
		spanId: '8765432112345678';
		name: 'operation';
		kind: aSpanKind;
		startTime: DateAndTime unixEpoch;
		endTime: (DateAndTime unixEpoch + 1 second);
		traceFlags: '01';
		attributes: someAttributes;
		resource: (OTResource attributes: (OrderedDictionary new
			at: 'service.name' put: 'local-service';
			yourself));
		instrumentationScope: (OTInstrumentationScope named: 'demo.scope').
	^ span
]

{ #category : 'private' }
OTZipkinSpanExporterTest >> transformedSpanForKind: aSpanKind attributes: someAttributes [

	^ (exporter transform: { (self spanWithKind: aSpanKind attributes: someAttributes) }) first
]

{ #category : 'running' }
OTZipkinSpanExporterTest >> setUp [

	super setUp.
	exporter := OTZipkinSpanExporter new
]

{ #category : 'tests' }
OTZipkinSpanExporterTest >> testClientSpanFallsBackToNetworkPeerAddressAndPortForRemoteEndpoint [

	| transformed |
	transformed := self
		transformedSpanForKind: OTSpan client
		attributes: (OrderedDictionary new
			at: 'network.peer.address' put: '1.2.3.4';
			at: 'network.peer.port' put: 5678;
			yourself).
	self assert: ((transformed at: 'remoteEndpoint') at: 'serviceName') equals: '1.2.3.4:5678'
]

{ #category : 'tests' }
OTZipkinSpanExporterTest >> testClientSpanUsesHighestRankedRemoteEndpointAttribute [

	| transformed |
	transformed := self
		transformedSpanForKind: OTSpan client
		attributes: (OrderedDictionary new
			at: 'peer.address' put: 'peer-address';
			at: 'server.address' put: 'server-address';
			at: 'peer.service' put: 'peer-service';
			yourself).
	self assert: ((transformed at: 'remoteEndpoint') at: 'serviceName') equals: 'peer-service'
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
