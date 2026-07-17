"
A reusable OTLP exporter configuration value that reads signal-specific and shared environment variables according to the OpenTelemetry exporter specification.
"
Class {
	#name : 'OTOtlpExporterConfiguration',
	#superclass : 'Object',
	#instVars : [
		'signalName',
		'relativePath',
		'endpoint',
		'protocol',
		'headers',
		'timeoutMillis',
		'compression',
		'userAgent'
	],
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'instance creation' }
OTOtlpExporterConfiguration class >> forSignalNamed: aString [

	^ self
		forSignalNamed: aString
		relativePath: (self defaultRelativePathForSignalNamed: aString)
]

{ #category : 'instance creation' }
OTOtlpExporterConfiguration class >> forSignalNamed: aString relativePath: aRelativePath [

	| normalizedSignal |
	normalizedSignal := aString asUppercase.
	^ self new
		signalName: normalizedSignal;
		relativePath: aRelativePath;
		endpoint:
			(self
				endpointFromEnvironmentForSignalNamed: normalizedSignal
				relativePath: aRelativePath);
		protocol: (self protocolFromEnvironmentForSignalNamed: normalizedSignal);
		headers: (self headersFromEnvironmentForSignalNamed: normalizedSignal);
		timeoutMillis: (self timeoutMillisFromEnvironmentForSignalNamed: normalizedSignal);
		compression: (self compressionFromEnvironmentForSignalNamed: normalizedSignal);
		userAgent: self defaultUserAgent;
		yourself
]

{ #category : 'accessing' }
OTOtlpExporterConfiguration class >> defaultBaseHttpEndpoint [

	^ 'http://localhost:4318'
]

{ #category : 'accessing' }
OTOtlpExporterConfiguration class >> defaultBaseGrpcEndpoint [

	^ 'http://localhost:4317'
]

{ #category : 'accessing' }
OTOtlpExporterConfiguration class >> defaultCompression [

	^ 'none'
]

{ #category : 'accessing' }
OTOtlpExporterConfiguration class >> defaultProtocol [

	^ 'http/protobuf'
]

{ #category : 'accessing' }
OTOtlpExporterConfiguration class >> defaultRelativePathForSignalNamed: aString [

	| normalizedSignal |
	normalizedSignal := aString asUppercase.
	normalizedSignal = 'TRACES' ifTrue: [ ^ 'v1/traces' ].
	normalizedSignal = 'METRICS' ifTrue: [ ^ 'v1/metrics' ].
	normalizedSignal = 'LOGS' ifTrue: [ ^ 'v1/logs' ].
	Error signal: 'Unsupported OTLP signal name: ' , aString
]

{ #category : 'accessing' }
OTOtlpExporterConfiguration class >> defaultTimeoutMillis [

	^ 10000
]

{ #category : 'accessing' }
OTOtlpExporterConfiguration class >> defaultUserAgent [

	^ 'OTel-OTLP-Exporter-Pharo/', OTTracerProvider sdkVersion
]

{ #category : 'private' }
OTOtlpExporterConfiguration class >> decodedHeaderComponentFrom: aString [

	^[ aString urlDecoded ]
		on: Error
		do: [ nil ]
]

{ #category : 'private' }
OTOtlpExporterConfiguration class >> environmentValueAt: aString [

	^ OTConfigurationSource environmentValueAt: aString
]

{ #category : 'private' }
OTOtlpExporterConfiguration class >> endpointFromEnvironmentForSignalNamed: aSignalName relativePath: aRelativePath [

	| protocol signalSpecificEndpoint sharedEndpoint |
	protocol := self protocolFromEnvironmentForSignalNamed: aSignalName.
	signalSpecificEndpoint := self
		environmentValueAt: (self signalEnvironmentNameFor: aSignalName suffix: 'ENDPOINT').
	signalSpecificEndpoint ifNotNil: [ ^ self normalizedSignalEndpoint: signalSpecificEndpoint ].
	sharedEndpoint := self environmentValueAt: 'OTEL_EXPORTER_OTLP_ENDPOINT'.
	sharedEndpoint ifNotNil: [
		protocol = 'grpc' ifTrue: [ ^ self normalizedSignalEndpoint: sharedEndpoint ].
		^ self
			normalizedBaseEndpoint: sharedEndpoint
			appendingRelativePath: aRelativePath ].
	protocol = 'grpc' ifTrue: [
		^ self normalizedSignalEndpoint: self defaultBaseGrpcEndpoint ].
	^ self
		normalizedBaseEndpoint: self defaultBaseHttpEndpoint
		appendingRelativePath: aRelativePath
]

{ #category : 'private' }
OTOtlpExporterConfiguration class >> compressionFromEnvironmentForSignalNamed: aSignalName [

	| value |
	value := self
		firstEnvironmentValueAt:
			{ (self signalEnvironmentNameFor: aSignalName suffix: 'COMPRESSION').
			'OTEL_EXPORTER_OTLP_COMPRESSION' }.
	value ifNil: [ ^ self defaultCompression ].
	value := value asLowercase.
	(#( 'none' 'gzip' ) includes: value) ifTrue: [ ^ value ].
	^ self defaultCompression
]

{ #category : 'private' }
OTOtlpExporterConfiguration class >> firstEnvironmentValueAt: someEnvironmentNames [

	someEnvironmentNames do: [ :each |
		(self environmentValueAt: each) ifNotNil: [ :value | ^ value ] ].
	^ nil
]

{ #category : 'private' }
OTOtlpExporterConfiguration class >> headersFromEnvironmentForSignalNamed: aSignalName [

	| headers |
	headers := self
		parsedHeadersFrom:
			(self environmentValueAt: 'OTEL_EXPORTER_OTLP_HEADERS').
	(self
		parsedHeadersFrom:
			(self
				environmentValueAt:
					(self signalEnvironmentNameFor: aSignalName suffix: 'HEADERS'))) associationsDo: [ :each |
		headers at: each key put: each value ].
	^ headers
]

{ #category : 'private' }
OTOtlpExporterConfiguration class >> normalizedBaseEndpoint: aString appendingRelativePath: aRelativePath [

	| normalizedEndpoint |
	normalizedEndpoint := self normalizedSignalEndpoint: aString.
	(normalizedEndpoint endsWith: '/') ifFalse: [
		normalizedEndpoint := normalizedEndpoint , '/' ].
	^ normalizedEndpoint , aRelativePath
]

{ #category : 'private' }
OTOtlpExporterConfiguration class >> normalizedSignalEndpoint: aString [

	^[ (ZnUrl fromString: aString) printString ]
		on: Error
		do: [ aString ]
]

{ #category : 'private' }
OTOtlpExporterConfiguration class >> parsedHeadersFrom: aString [

	| parsedHeaders |
	parsedHeaders := OrderedDictionary new.
	aString ifNil: [ ^ parsedHeaders ].
	(aString substrings: ',') do: [ :each |
		| member keyValueSeparatorIndex keyValueMember rawKey rawValue key value |
		member := each trimBoth.
		member ifNotEmpty: [
			keyValueMember := member
				copyUpTo: $;.
			keyValueSeparatorIndex := keyValueMember indexOf: $= ifAbsent: [ 0 ].
			keyValueSeparatorIndex > 1 ifTrue: [
				rawKey := (keyValueMember copyFrom: 1 to: keyValueSeparatorIndex - 1) trimBoth.
				rawValue := (keyValueMember copyFrom: keyValueSeparatorIndex + 1 to: keyValueMember size) trimBoth.
				(rawKey isNotEmpty and: [ rawValue isNotEmpty ]) ifTrue: [
					key := self decodedHeaderComponentFrom: rawKey.
					value := self decodedHeaderComponentFrom: rawValue.
					(key isNotNil and: [ value isNotNil ]) ifTrue: [
						parsedHeaders at: key put: value ] ] ] ] ].
	^ parsedHeaders
]

{ #category : 'private' }
OTOtlpExporterConfiguration class >> positiveIntegerEnvironmentValueAt: aString default: aDefaultValue [

	| rawValue parsed |
	rawValue := self environmentValueAt: aString.
	rawValue ifNil: [ ^ aDefaultValue ].
	parsed := self strictPositiveIntegerFrom: rawValue.
	^ parsed ifNil: [ aDefaultValue ] ifNotNil: [ parsed ]
]

{ #category : 'private' }
OTOtlpExporterConfiguration class >> protocolFromEnvironmentForSignalNamed: aSignalName [

	| value |
	value := self
		firstEnvironmentValueAt:
			{ (self signalEnvironmentNameFor: aSignalName suffix: 'PROTOCOL').
			'OTEL_EXPORTER_OTLP_PROTOCOL' }.
	value ifNil: [ ^ self defaultProtocol ].
	value := value asLowercase.
	(#( 'grpc' 'http/protobuf' 'http/json' ) includes: value)
		ifTrue: [ ^ value ].
	^ self defaultProtocol
]

{ #category : 'private' }
OTOtlpExporterConfiguration class >> signalEnvironmentNameFor: aSignalName suffix: aSuffix [

	^ 'OTEL_EXPORTER_OTLP_', aSignalName asUppercase, '_', aSuffix
]

{ #category : 'private' }
OTOtlpExporterConfiguration class >> strictPositiveIntegerFrom: aString [

	| stream value |
	stream := aString trimBoth readStream.
	stream atEnd ifTrue: [ ^ nil ].
	value := [ Integer readFrom: stream ] on: Error do: [ ^ nil ].
	stream atEnd ifFalse: [ ^ nil ].
	value > 0 ifFalse: [ ^ nil ].
	^ value
]

{ #category : 'private' }
OTOtlpExporterConfiguration class >> timeoutMillisFromEnvironmentForSignalNamed: aSignalName [

	| signalSpecific shared |
	signalSpecific := self
		positiveIntegerEnvironmentValueAt:
			(self signalEnvironmentNameFor: aSignalName suffix: 'TIMEOUT')
		default: nil.
	signalSpecific ifNotNil: [ ^ signalSpecific ].
	shared := self
		positiveIntegerEnvironmentValueAt: 'OTEL_EXPORTER_OTLP_TIMEOUT'
		default: nil.
	^ shared ifNil: [ self defaultTimeoutMillis ] ifNotNil: [ shared ]
]

{ #category : 'comparing' }
OTOtlpExporterConfiguration >> = anObject [

	self == anObject ifTrue: [ ^ true ].
	anObject class == self class ifFalse: [ ^ false ].
	^ self signalName = anObject signalName
		and: [ self relativePath = anObject relativePath
		and: [ self endpoint = anObject endpoint
		and: [ self protocol = anObject protocol
		and: [ self headers = anObject headers
		and: [ self timeoutMillis = anObject timeoutMillis
		and: [ self compression = anObject compression
		and: [ self userAgent = anObject userAgent ] ] ] ] ] ] ]
]

{ #category : 'accessing' }
OTOtlpExporterConfiguration >> compression [

	^ compression ifNil: [ self class defaultCompression ]
]

{ #category : 'accessing' }
OTOtlpExporterConfiguration >> compression: aString [

	compression := aString
]

{ #category : 'accessing' }
OTOtlpExporterConfiguration >> endpoint [

	^ endpoint ifNil: [
		  self class
			  normalizedBaseEndpoint: self class defaultBaseHttpEndpoint
			  appendingRelativePath: self relativePath ]
]

{ #category : 'accessing' }
OTOtlpExporterConfiguration >> endpoint: aString [

	endpoint := aString
]

{ #category : 'accessing' }
OTOtlpExporterConfiguration >> headers [

	^ headers ifNil: [ OrderedDictionary new ]
]

{ #category : 'accessing' }
OTOtlpExporterConfiguration >> headers: aDictionary [

	headers := aDictionary
]

{ #category : 'comparing' }
OTOtlpExporterConfiguration >> hash [

	^ { self signalName.
	self relativePath.
	self endpoint.
	self protocol.
	self headers.
	self timeoutMillis.
	self compression.
	self userAgent } hash
]

{ #category : 'testing' }
OTOtlpExporterConfiguration >> isGrpcProtocol [

	^ self protocol = 'grpc'
]

{ #category : 'testing' }
OTOtlpExporterConfiguration >> usesGzipCompression [

	^ self compression = 'gzip'
]

{ #category : 'testing' }
OTOtlpExporterConfiguration >> usesHttpTransport [

	^ self protocol beginsWith: 'http/'
]

{ #category : 'testing' }
OTOtlpExporterConfiguration >> usesJsonEncoding [

	^ self protocol = 'http/json'
]

{ #category : 'testing' }
OTOtlpExporterConfiguration >> usesProtobufEncoding [

	^ self protocol = 'http/protobuf' or: [ self protocol = 'grpc' ]
]

{ #category : 'accessing' }
OTOtlpExporterConfiguration >> protocol [

	^ protocol ifNil: [ self class defaultProtocol ]
]

{ #category : 'accessing' }
OTOtlpExporterConfiguration >> protocol: aString [

	protocol := aString
]

{ #category : 'accessing' }
OTOtlpExporterConfiguration >> relativePath [

	^ relativePath ifNil: [
		  self class defaultRelativePathForSignalNamed: self signalName ]
]

{ #category : 'accessing' }
OTOtlpExporterConfiguration >> relativePath: aString [

	relativePath := aString
]

{ #category : 'accessing' }
OTOtlpExporterConfiguration >> signalName [

	^ signalName ifNil: [ 'TRACES' ]
]

{ #category : 'accessing' }
OTOtlpExporterConfiguration >> signalName: aString [

	signalName := aString
]

{ #category : 'accessing' }
OTOtlpExporterConfiguration >> timeoutMillis [

	^ timeoutMillis ifNil: [ self class defaultTimeoutMillis ]
]

{ #category : 'accessing' }
OTOtlpExporterConfiguration >> timeoutMillis: anInteger [

	timeoutMillis := anInteger
]

{ #category : 'accessing' }
OTOtlpExporterConfiguration >> userAgent [

	^ userAgent ifNil: [ self class defaultUserAgent ]
]

{ #category : 'accessing' }
OTOtlpExporterConfiguration >> userAgent: aString [

	userAgent := aString
]
