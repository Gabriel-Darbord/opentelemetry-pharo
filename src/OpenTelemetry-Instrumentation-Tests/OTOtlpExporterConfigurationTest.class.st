Class {
	#name : 'OTOtlpExporterConfigurationTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'private' }
OTOtlpExporterConfigurationTest >> setEnvironmentValue: aValue forKey: aKey [

	| environment currentValue |
	environment := Smalltalk os environment.
	currentValue := environment at: aKey ifAbsent: [ nil ].
	aValue
		ifNil: [ currentValue ifNotNil: [ environment removeKey: aKey ] ]
		ifNotNil: [ environment at: aKey put: aValue ]
]

{ #category : 'tests' }
OTOtlpExporterConfigurationTest >> testDefaultsFollowTraceHttpExporterSpec [

	| configuration |
	self
		withEnvironmentValues: Dictionary new
		during: [
			configuration := OTOtlpExporterConfiguration forSignalNamed: 'TRACES'.
			self assert: configuration signalName equals: 'TRACES'.
			self assert: configuration endpoint equals: 'http://localhost:4318/v1/traces'.
			self assert: configuration protocol equals: 'http/protobuf'.
			self assert: configuration headers isEmpty.
			self assert: configuration timeoutMillis equals: 10000.
			self assert: configuration compression equals: 'none'.
			self assert: configuration usesHttpTransport.
			self assert: configuration usesProtobufEncoding.
			self deny: configuration usesJsonEncoding.
			self deny: configuration usesGzipCompression.
			self assert: configuration userAgent equals: 'OTel-OTLP-Exporter-Pharo/', OTTracerProvider sdkVersion ]
]

{ #category : 'tests' }
OTOtlpExporterConfigurationTest >> testGrpcAuthorityEndpointDefaultsToSecureTransport [

	| configuration |
	self
		withEnvironmentValues: (Dictionary new
				 at: 'OTEL_EXPORTER_OTLP_PROTOCOL' put: 'grpc';
				 at: 'OTEL_EXPORTER_OTLP_ENDPOINT' put: 'collector:4317';
				 yourself)
		during: [
				configuration := OTOtlpExporterConfiguration forSignalNamed: 'TRACES'.
				self assert: configuration endpoint equals: 'https://collector:4317/'.
				self deny: configuration insecure ]
]

{ #category : 'tests' }
OTOtlpExporterConfigurationTest >> testGrpcAuthorityEndpointUsesInsecureTransportWhenConfigured [

	| configuration |
	self
		withEnvironmentValues: (Dictionary new
				 at: 'OTEL_EXPORTER_OTLP_PROTOCOL' put: 'grpc';
				 at: 'OTEL_EXPORTER_OTLP_ENDPOINT' put: 'collector:4317';
				 at: 'OTEL_EXPORTER_OTLP_INSECURE' put: 'true';
				 yourself)
		during: [
				configuration := OTOtlpExporterConfiguration forSignalNamed: 'TRACES'.
				self assert: configuration endpoint equals: 'http://collector:4317/'.
				self assert: configuration insecure ]
]

{ #category : 'tests' }
OTOtlpExporterConfigurationTest >> testGrpcDefaultsFollowTraceExporterSpec [

	| configuration |
	self
		withEnvironmentValues: (Dictionary new
			at: 'OTEL_EXPORTER_OTLP_PROTOCOL' put: 'grpc';
			yourself)
			during: [
				configuration := OTOtlpExporterConfiguration forSignalNamed: 'TRACES'.
				self assert: configuration endpoint equals: 'http://localhost:4317/'.
				self assert: configuration protocol equals: 'grpc'.
				self deny: configuration usesHttpTransport.
				self deny: configuration usesJsonEncoding.
				self assert: configuration usesProtobufEncoding ]
]

{ #category : 'tests' }
OTOtlpExporterConfigurationTest >> testGrpcExplicitSchemeOverridesInsecureSetting [

	| configuration |
	self
		withEnvironmentValues: (Dictionary new
				 at: 'OTEL_EXPORTER_OTLP_PROTOCOL' put: 'grpc';
				 at: 'OTEL_EXPORTER_OTLP_ENDPOINT' put: 'https://collector:4317';
				 at: 'OTEL_EXPORTER_OTLP_INSECURE' put: 'true';
				 yourself)
		during: [
				configuration := OTOtlpExporterConfiguration forSignalNamed: 'TRACES'.
				self assert: configuration endpoint equals: 'https://collector:4317/'.
				self assert: configuration insecure ]
]

{ #category : 'tests' }
OTOtlpExporterConfigurationTest >> testGrpcSharedEndpointIsUsedAsIs [

	self
		withEnvironmentValues: (Dictionary new
			at: 'OTEL_EXPORTER_OTLP_PROTOCOL' put: 'grpc';
			at: 'OTEL_EXPORTER_OTLP_ENDPOINT' put: 'http://collector:4317/mycollector';
			yourself)
			during: [
				self assert:
					(OTOtlpExporterConfiguration forSignalNamed: 'TRACES') endpoint
					equals: 'http://collector:4317/mycollector' ]
]

{ #category : 'tests' }
OTOtlpExporterConfigurationTest >> testHeadersMergeSharedAndSignalSpecificValues [

	| configuration |
	self
		withEnvironmentValues: (Dictionary new
			at: 'OTEL_EXPORTER_OTLP_HEADERS' put: 'authorization=Bearer%20123,tenant=global';
			at: 'OTEL_EXPORTER_OTLP_TRACES_HEADERS' put: 'authorization=Token%2042;ignored=true,trace-header=present';
			yourself)
		during: [
			configuration := OTOtlpExporterConfiguration forSignalNamed: 'TRACES'.
			self assert: configuration headers size equals: 3.
			self assert: (configuration headers at: 'authorization') equals: 'Token 42'.
			self assert: (configuration headers at: 'tenant') equals: 'global'.
			self assert: (configuration headers at: 'trace-header') equals: 'present' ]
]

{ #category : 'tests' }
OTOtlpExporterConfigurationTest >> testInvalidHeaderEntriesAreIgnored [

	| configuration |
	self
		withEnvironmentValues: (Dictionary new
			at: 'OTEL_EXPORTER_OTLP_TRACES_HEADERS' put: 'good=value,bad%ZZ=value,missingEquals,empty=';
			yourself)
		during: [
			configuration := OTOtlpExporterConfiguration forSignalNamed: 'TRACES'.
			self assert: configuration headers size equals: 1.
			self assert: (configuration headers at: 'good') equals: 'value' ]
]

{ #category : 'tests' }
OTOtlpExporterConfigurationTest >> testInvalidScalarSettingsFallBackToSpecDefaults [

	| configuration |
	self
		withEnvironmentValues: (Dictionary new
				 at: 'OTEL_EXPORTER_OTLP_PROTOCOL' put: 'udp';
				 at: 'OTEL_EXPORTER_OTLP_COMPRESSION' put: 'brotli';
				 at: 'OTEL_EXPORTER_OTLP_INSECURE' put: 'maybe';
				 yourself)
		during: [
				configuration := OTOtlpExporterConfiguration forSignalNamed: 'TRACES'.
				self assert: configuration protocol equals: 'http/protobuf'.
				self assert: configuration timeoutMillis equals: 10000.
				self assert: configuration compression equals: 'none'.
				self deny: configuration insecure ]
]

{ #category : 'tests' }
OTOtlpExporterConfigurationTest >> testInvalidSharedScalarSettingsFallBackToSpecDefaultsAndWarn [

	self withWarningsDo: [ :warnings |
			| configuration |
			self
				withEnvironmentValues: (Dictionary new
						 at: 'OTEL_EXPORTER_OTLP_PROTOCOL' put: 'udp';
						 at: 'OTEL_EXPORTER_OTLP_TIMEOUT' put: '-1';
						 at: 'OTEL_EXPORTER_OTLP_COMPRESSION' put: 'brotli';
						 at: 'OTEL_EXPORTER_OTLP_INSECURE' put: 'maybe';
						 yourself)
				during: [
						configuration := OTOtlpExporterConfiguration forSignalNamed: 'TRACES'.
						self assert: configuration protocol equals: 'http/protobuf'.
						self assert: configuration timeoutMillis equals: 10000.
						self assert: configuration compression equals: 'none'.
						self deny: configuration insecure ].
			self
				assert: warnings asArray
				equals:
					{ 'OpenTelemetry OTLP exporter configuration was invalid and has been ignored for ''OTEL_EXPORTER_OTLP_PROTOCOL'': ''udp'''.
					'OpenTelemetry OTLP exporter configuration was invalid and has been ignored for ''OTEL_EXPORTER_OTLP_INSECURE'': ''maybe'''.
					'OpenTelemetry OTLP exporter configuration was invalid and has been ignored for ''OTEL_EXPORTER_OTLP_TIMEOUT'': ''-1'''.
					'OpenTelemetry OTLP exporter configuration was invalid and has been ignored for ''OTEL_EXPORTER_OTLP_COMPRESSION'': ''brotli''' } ]
]

{ #category : 'tests' }
OTOtlpExporterConfigurationTest >> testInvalidSignalSpecificScalarSettingsFallBackToSharedValuesAndWarn [

	self withWarningsDo: [ :warnings |
			| configuration |
			self
				withEnvironmentValues: (Dictionary new
						 at: 'OTEL_EXPORTER_OTLP_PROTOCOL' put: 'grpc';
						 at: 'OTEL_EXPORTER_OTLP_TRACES_PROTOCOL' put: 'udp';
						 at: 'OTEL_EXPORTER_OTLP_COMPRESSION' put: 'gzip';
						 at: 'OTEL_EXPORTER_OTLP_TRACES_COMPRESSION' put: 'brotli';
						 at: 'OTEL_EXPORTER_OTLP_INSECURE' put: 'true';
						 at: 'OTEL_EXPORTER_OTLP_TRACES_INSECURE' put: 'maybe';
						 at: 'OTEL_EXPORTER_OTLP_TIMEOUT' put: '20000';
						 at: 'OTEL_EXPORTER_OTLP_TRACES_TIMEOUT' put: '-1';
						 yourself)
				during: [
						configuration := OTOtlpExporterConfiguration forSignalNamed: 'TRACES'.
						self assert: configuration protocol equals: 'grpc'.
						self assert: configuration compression equals: 'gzip'.
						self assert: configuration insecure.
						self assert: configuration timeoutMillis equals: 20000 ].
			self
				assert: warnings asArray
				equals:
					{ 'OpenTelemetry OTLP exporter configuration was invalid and has been ignored for ''OTEL_EXPORTER_OTLP_TRACES_PROTOCOL'': ''udp'''.
					'OpenTelemetry OTLP exporter configuration was invalid and has been ignored for ''OTEL_EXPORTER_OTLP_TRACES_INSECURE'': ''maybe'''.
					'OpenTelemetry OTLP exporter configuration was invalid and has been ignored for ''OTEL_EXPORTER_OTLP_TRACES_TIMEOUT'': ''-1'''.
					'OpenTelemetry OTLP exporter configuration was invalid and has been ignored for ''OTEL_EXPORTER_OTLP_TRACES_COMPRESSION'': ''brotli''' } ]
]

{ #category : 'tests' }
OTOtlpExporterConfigurationTest >> testSharedEndpointAppendsTracePath [

	self
		withEnvironmentValues: (Dictionary new
			at: 'OTEL_EXPORTER_OTLP_ENDPOINT' put: 'http://collector:4318/mycollector';
			yourself)
		during: [
			self assert:
				(OTOtlpExporterConfiguration forSignalNamed: 'TRACES') endpoint
				equals: 'http://collector:4318/mycollector/v1/traces' ]
]

{ #category : 'tests' }
OTOtlpExporterConfigurationTest >> testSignalSpecificEndpointIsUsedAsIsExceptForMissingRootPath [

	self
		withEnvironmentValues: (Dictionary new
			at: 'OTEL_EXPORTER_OTLP_ENDPOINT' put: 'http://collector:4318/base';
			at: 'OTEL_EXPORTER_OTLP_TRACES_ENDPOINT' put: 'http://collector:4318';
			yourself)
		during: [
			self assert:
				(OTOtlpExporterConfiguration forSignalNamed: 'TRACES') endpoint
				equals: 'http://collector:4318/' ]
]

{ #category : 'tests' }
OTOtlpExporterConfigurationTest >> testSignalSpecificScalarSettingsOverrideSharedOnes [

	| configuration |
	self
		withEnvironmentValues: (Dictionary new
			at: 'OTEL_EXPORTER_OTLP_PROTOCOL' put: 'grpc';
			at: 'OTEL_EXPORTER_OTLP_TRACES_PROTOCOL' put: 'http/json';
			at: 'OTEL_EXPORTER_OTLP_TIMEOUT' put: '20000';
			at: 'OTEL_EXPORTER_OTLP_TRACES_TIMEOUT' put: '1500';
			at: 'OTEL_EXPORTER_OTLP_COMPRESSION' put: 'gzip';
			at: 'OTEL_EXPORTER_OTLP_TRACES_COMPRESSION' put: 'none';
			yourself)
		during: [
			configuration := OTOtlpExporterConfiguration forSignalNamed: 'TRACES'.
			self assert: configuration protocol equals: 'http/json'.
			self assert: configuration timeoutMillis equals: 1500.
			self assert: configuration compression equals: 'none'.
			self assert: configuration usesHttpTransport.
			self assert: configuration usesJsonEncoding.
			self deny: configuration usesProtobufEncoding.
			self deny: configuration usesGzipCompression ]
]

{ #category : 'tests' }
OTOtlpExporterConfigurationTest >> testSignalSpecificSecuritySettingsOverrideSharedOnes [

	| configuration |
	self
		withEnvironmentValues: (Dictionary new
				 at: 'OTEL_EXPORTER_OTLP_PROTOCOL' put: 'grpc';
				 at: 'OTEL_EXPORTER_OTLP_ENDPOINT' put: 'collector:4317';
				 at: 'OTEL_EXPORTER_OTLP_INSECURE' put: 'true';
				 at: 'OTEL_EXPORTER_OTLP_TRACES_INSECURE' put: 'false';
				 yourself)
		during: [
				configuration := OTOtlpExporterConfiguration forSignalNamed: 'TRACES'.
				self assert: configuration endpoint equals: 'https://collector:4317/'.
				self deny: configuration insecure ]
]

{ #category : 'tests' }
OTOtlpExporterConfigurationTest >> testSignalSpecificTlsFileSettingsOverrideSharedOnes [

	| configuration |
	self
		withEnvironmentValues: (Dictionary new
				 at: 'OTEL_EXPORTER_OTLP_CERTIFICATE' put: '/shared-ca.pem';
				 at: 'OTEL_EXPORTER_OTLP_TRACES_CERTIFICATE' put: '/trace-ca.pem';
				 at: 'OTEL_EXPORTER_OTLP_CLIENT_KEY' put: '/shared-key.pem';
				 at: 'OTEL_EXPORTER_OTLP_TRACES_CLIENT_KEY' put: '/trace-key.pem';
				 at: 'OTEL_EXPORTER_OTLP_CLIENT_CERTIFICATE' put: '/shared-cert.pem';
				 at: 'OTEL_EXPORTER_OTLP_TRACES_CLIENT_CERTIFICATE' put: '/trace-cert.pem';
				 yourself)
		during: [
				configuration := OTOtlpExporterConfiguration forSignalNamed: 'TRACES'.
				self assert: configuration certificateFile equals: '/trace-ca.pem'.
				self assert: configuration clientKeyFile equals: '/trace-key.pem'.
				self assert: configuration clientCertificateFile equals: '/trace-cert.pem' ]
]

{ #category : 'tests' }
OTOtlpExporterConfigurationTest >> testTimeoutZeroMeansNoLimit [

	| configuration |
	self
		withEnvironmentValues: (Dictionary new
				 at: 'OTEL_EXPORTER_OTLP_TIMEOUT' put: '0';
				 yourself)
		during: [
				configuration := OTOtlpExporterConfiguration forSignalNamed: 'TRACES'.
				self assert: configuration timeoutMillis equals: OTOtlpExporterConfiguration noTimeoutMillis ]
]

{ #category : 'private' }
OTOtlpExporterConfigurationTest >> withEnvironmentValues: aDictionary during: aBlock [

	| absent effectiveValues environment managedKeys snapshot |
	absent := Object new.
	environment := Smalltalk os environment.
	effectiveValues := aDictionary copy.
	managedKeys := (environment keys
		select: [ :each | each beginsWith: 'OTEL_' ])
		asOrderedCollection.
	effectiveValues keysDo: [ :each |
		(managedKeys includes: each) ifFalse: [ managedKeys add: each ] ].
	snapshot := Dictionary new.
	managedKeys do: [ :key |
		| value |
		value := effectiveValues at: key ifAbsent: [ nil ].
		snapshot at: key put: (environment at: key ifAbsent: [ absent ]).
		self setEnvironmentValue: value forKey: key ].
	[
		^ aBlock value ]
		ensure: [
			managedKeys do: [ :key |
				| value |
				value := snapshot at: key.
				self
					setEnvironmentValue: (value == absent ifTrue: [ nil ] ifFalse: [ value ])
					forKey: key ] ]
]

{ #category : 'private' }
OTOtlpExporterConfigurationTest >> withWarningsDo: aBlock [

	| warnings |
	warnings := OrderedCollection new.
	OTOtlpExporterConfiguration warningSink: [ :message | warnings add: message ].
	[ ^ aBlock value: warnings ] ensure: [ OTOtlpExporterConfiguration warningSink: nil ]
]
