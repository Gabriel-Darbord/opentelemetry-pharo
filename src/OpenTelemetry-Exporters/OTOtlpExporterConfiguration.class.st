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
		'userAgent',
		'insecure',
		'certificateFile',
		'clientKeyFile',
		'clientCertificateFile'
	],
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'private' }
OTOtlpExporterConfiguration class >> certificateFileFromEnvironmentForSignalNamed: aSignalName [

	^ self firstEnvironmentValueAt: {
			  (self signalEnvironmentNameFor: aSignalName suffix: 'CERTIFICATE').
			  'OTEL_EXPORTER_OTLP_CERTIFICATE' }
]

{ #category : 'private' }
OTOtlpExporterConfiguration class >> clientCertificateFileFromEnvironmentForSignalNamed: aSignalName [

	^ self firstEnvironmentValueAt: {
			  (self signalEnvironmentNameFor: aSignalName suffix: 'CLIENT_CERTIFICATE').
			  'OTEL_EXPORTER_OTLP_CLIENT_CERTIFICATE' }
]

{ #category : 'private' }
OTOtlpExporterConfiguration class >> clientKeyFileFromEnvironmentForSignalNamed: aSignalName [

	^ self firstEnvironmentValueAt: {
			  (self signalEnvironmentNameFor: aSignalName suffix: 'CLIENT_KEY').
			  'OTEL_EXPORTER_OTLP_CLIENT_KEY' }
]

{ #category : 'private' }
OTOtlpExporterConfiguration class >> compressionFromEnvironmentForSignalNamed: aSignalName [

	| signalVariable sharedVariable value |
	signalVariable := self signalEnvironmentNameFor: aSignalName suffix: 'COMPRESSION'.
	value := self environmentValueAt: signalVariable.
	value ifNotNil: [
			value := value asLowercase.
			(#( 'none' 'gzip' ) includes: value)
				ifTrue: [ ^ value ]
				ifFalse: [ self noteInvalidEnvironmentValue: value forVariable: signalVariable ] ].
	sharedVariable := 'OTEL_EXPORTER_OTLP_COMPRESSION'.
	value := self environmentValueAt: sharedVariable.
	value ifNotNil: [
			value := value asLowercase.
			(#( 'none' 'gzip' ) includes: value)
				ifTrue: [ ^ value ]
				ifFalse: [ self noteInvalidEnvironmentValue: value forVariable: sharedVariable ] ].
	^ self defaultCompression
]

{ #category : 'private' }
OTOtlpExporterConfiguration class >> configurationSourceClass [

	^ OpenTelemetry dependencyClassNamed: #OTConfigurationSource ifAbsent: [ nil ]
]

{ #category : 'private' }
OTOtlpExporterConfiguration class >> decodedHeaderComponentFrom: aString [

	^ [ aString urlDecoded ]
		  on: Error
		  do: [ nil ]
]

{ #category : 'accessing' }
OTOtlpExporterConfiguration class >> defaultBaseGrpcEndpoint [

	^ 'http://localhost:4317'
]

{ #category : 'accessing' }
OTOtlpExporterConfiguration class >> defaultBaseHttpEndpoint [

	^ 'http://localhost:4318'
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

	^ 'OTel-OTLP-Exporter-Pharo/' , OTTracerProvider sdkVersion
]

{ #category : 'accessing' }
OTOtlpExporterConfiguration class >> defaultWarningSink [

	^ OTDiagnosticLogger defaultWarningSink
]

{ #category : 'private' }
OTOtlpExporterConfiguration class >> endpointFromEnvironmentForSignalNamed: aSignalName relativePath: aRelativePath [

	^ self
		  endpointFromEnvironmentForSignalNamed: aSignalName
		  relativePath: aRelativePath
		  protocol: (self protocolFromEnvironmentForSignalNamed: aSignalName)
		  insecure: (self insecureFromEnvironmentForSignalNamed: aSignalName)
]

{ #category : 'private' }
OTOtlpExporterConfiguration class >> endpointFromEnvironmentForSignalNamed: aSignalName relativePath: aRelativePath protocol: aProtocol insecure: anInsecureBoolean [

	| sharedEndpoint signalSpecificEndpoint |
	signalSpecificEndpoint := self environmentValueAt: (self signalEnvironmentNameFor: aSignalName suffix: 'ENDPOINT').
	signalSpecificEndpoint ifNotNil: [
			aProtocol = 'grpc' ifTrue: [ ^ self normalizedGrpcEndpoint: signalSpecificEndpoint insecure: anInsecureBoolean ].
			^ self normalizedSignalEndpoint: signalSpecificEndpoint ].
	sharedEndpoint := self environmentValueAt: 'OTEL_EXPORTER_OTLP_ENDPOINT'.
	sharedEndpoint ifNotNil: [
			aProtocol = 'grpc' ifTrue: [ ^ self normalizedGrpcEndpoint: sharedEndpoint insecure: anInsecureBoolean ].
			^ self normalizedBaseEndpoint: sharedEndpoint appendingRelativePath: aRelativePath ].
	aProtocol = 'grpc' ifTrue: [ ^ self normalizedGrpcEndpoint: self defaultBaseGrpcEndpoint insecure: false ].
	^ self normalizedBaseEndpoint: self defaultBaseHttpEndpoint appendingRelativePath: aRelativePath
]

{ #category : 'private' }
OTOtlpExporterConfiguration class >> environmentValueAt: aString [

	| configurationSourceClass |
	configurationSourceClass := self configurationSourceClass.
	^ configurationSourceClass ifNotNil: [ configurationSourceClass environmentValueAt: aString ]
]

{ #category : 'private' }
OTOtlpExporterConfiguration class >> firstEnvironmentValueAt: someEnvironmentNames [

	someEnvironmentNames do: [ :each | (self environmentValueAt: each) ifNotNil: [ :value | ^ value ] ].
	^ nil
]

{ #category : 'instance creation' }
OTOtlpExporterConfiguration class >> forSignalNamed: aString [

	^ self forSignalNamed: aString relativePath: (self defaultRelativePathForSignalNamed: aString)
]

{ #category : 'instance creation' }
OTOtlpExporterConfiguration class >> forSignalNamed: aString relativePath: aRelativePath [

	| insecure normalizedSignal protocol |
	normalizedSignal := aString asUppercase.
	protocol := self protocolFromEnvironmentForSignalNamed: normalizedSignal.
	insecure := self insecureFromEnvironmentForSignalNamed: normalizedSignal.
	^ self new
		  signalName: normalizedSignal;
		  relativePath: aRelativePath;
		  protocol: protocol;
		  insecure: insecure;
		  endpoint: (self
				   endpointFromEnvironmentForSignalNamed: normalizedSignal
				   relativePath: aRelativePath
				   protocol: protocol
				   insecure: insecure);
		  headers: (self headersFromEnvironmentForSignalNamed: normalizedSignal);
		  timeoutMillis: (self timeoutMillisFromEnvironmentForSignalNamed: normalizedSignal);
		  compression: (self compressionFromEnvironmentForSignalNamed: normalizedSignal);
		  certificateFile: (self certificateFileFromEnvironmentForSignalNamed: normalizedSignal);
		  clientKeyFile: (self clientKeyFileFromEnvironmentForSignalNamed: normalizedSignal);
		  clientCertificateFile: (self clientCertificateFileFromEnvironmentForSignalNamed: normalizedSignal);
		  userAgent: self defaultUserAgent;
		  yourself
]

{ #category : 'private' }
OTOtlpExporterConfiguration class >> headersFromEnvironmentForSignalNamed: aSignalName [

	| headers |
	headers := self parsedHeadersFrom: (self environmentValueAt: 'OTEL_EXPORTER_OTLP_HEADERS').
	(self parsedHeadersFrom: (self environmentValueAt: (self signalEnvironmentNameFor: aSignalName suffix: 'HEADERS')))
		associationsDo: [ :each | headers at: each key put: each value ].
	^ headers
]

{ #category : 'private' }
OTOtlpExporterConfiguration class >> insecureFromEnvironmentForSignalNamed: aSignalName [

	| parsedValue signalVariable sharedVariable value |
	signalVariable := self signalEnvironmentNameFor: aSignalName suffix: 'INSECURE'.
	value := self environmentValueAt: signalVariable.
	value ifNotNil: [
			parsedValue := self strictBooleanFrom: value.
			parsedValue ifNotNil: [ ^ parsedValue ].
			self noteInvalidEnvironmentValue: value forVariable: signalVariable ].
	sharedVariable := 'OTEL_EXPORTER_OTLP_INSECURE'.
	value := self environmentValueAt: sharedVariable.
	value ifNotNil: [
			parsedValue := self strictBooleanFrom: value.
			parsedValue ifNotNil: [ ^ parsedValue ].
			self noteInvalidEnvironmentValue: value forVariable: sharedVariable ].
	^ false
]

{ #category : 'accessing' }
OTOtlpExporterConfiguration class >> noTimeoutMillis [

	^ 2147483647
]

{ #category : 'private' }
OTOtlpExporterConfiguration class >> normalizedBaseEndpoint: aString appendingRelativePath: aRelativePath [

	| normalizedEndpoint |
	normalizedEndpoint := self normalizedSignalEndpoint: aString.
	(normalizedEndpoint endsWith: '/') ifFalse: [ normalizedEndpoint := normalizedEndpoint , '/' ].
	^ normalizedEndpoint , aRelativePath
]

{ #category : 'private' }
OTOtlpExporterConfiguration class >> normalizedGrpcEndpoint: aString insecure: aBoolean [

	| secureEndpoint url |
	url := [ ZnUrl fromString: aString ]
		       on: Error
		       do: [ nil ].
	(url notNil and: [ (#( 'http' 'https' ) includes: url scheme) and: [ url host notNil and: [ url host isNotEmpty ] ] ]) ifTrue: [
		^ url printString ].
	secureEndpoint := (aBoolean
		                   ifTrue: [ 'http://' ]
		                   ifFalse: [ 'https://' ]) , aString.
	url := [ ZnUrl fromString: secureEndpoint ]
		       on: Error
		       do: [ nil ].
	(url notNil and: [ url host notNil and: [ url host isNotEmpty ] ]) ifTrue: [ ^ url printString ].
	^ self normalizedSignalEndpoint: aString
]

{ #category : 'private' }
OTOtlpExporterConfiguration class >> normalizedSignalEndpoint: aString [

	^ [ (ZnUrl fromString: aString) printString ]
		  on: Error
		  do: [ aString ]
]

{ #category : 'private - logging' }
OTOtlpExporterConfiguration class >> noteInvalidEnvironmentValue: aValue forVariable: aString [

	self warningSink value:
		'OpenTelemetry OTLP exporter configuration was invalid and has been ignored for ' , aString printString , ': '
		, aValue printString
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
					keyValueMember := member copyUpTo: $;.
					keyValueSeparatorIndex := keyValueMember indexOf: $= ifAbsent: [ 0 ].
					keyValueSeparatorIndex > 1 ifTrue: [
							rawKey := (keyValueMember copyFrom: 1 to: keyValueSeparatorIndex - 1) trimBoth.
							rawValue := (keyValueMember copyFrom: keyValueSeparatorIndex + 1 to: keyValueMember size) trimBoth.
							(rawKey isNotEmpty and: [ rawValue isNotEmpty ]) ifTrue: [
									key := self decodedHeaderComponentFrom: rawKey.
									value := self decodedHeaderComponentFrom: rawValue.
									(key isNotNil and: [ value isNotNil ]) ifTrue: [ parsedHeaders at: key put: value ] ] ] ] ].
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

	| signalVariable sharedVariable value |
	signalVariable := self signalEnvironmentNameFor: aSignalName suffix: 'PROTOCOL'.
	value := self environmentValueAt: signalVariable.
	value ifNotNil: [
			value := value asLowercase.
			(#( 'grpc' 'http/protobuf' 'http/json' ) includes: value)
				ifTrue: [ ^ value ]
				ifFalse: [ self noteInvalidEnvironmentValue: value forVariable: signalVariable ] ].
	sharedVariable := 'OTEL_EXPORTER_OTLP_PROTOCOL'.
	value := self environmentValueAt: sharedVariable.
	value ifNotNil: [
			value := value asLowercase.
			(#( 'grpc' 'http/protobuf' 'http/json' ) includes: value)
				ifTrue: [ ^ value ]
				ifFalse: [ self noteInvalidEnvironmentValue: value forVariable: sharedVariable ] ].
	^ self defaultProtocol
]

{ #category : 'private' }
OTOtlpExporterConfiguration class >> signalEnvironmentNameFor: aSignalName suffix: aSuffix [

	^ 'OTEL_EXPORTER_OTLP_' , aSignalName asUppercase , '_' , aSuffix
]

{ #category : 'private' }
OTOtlpExporterConfiguration class >> strictBooleanFrom: aBooleanOrString [

	| value |
	(OTAttributeNormalizer isBoolean: aBooleanOrString) ifTrue: [ ^ aBooleanOrString ].
	(aBooleanOrString isString or: [ aBooleanOrString isSymbol ]) ifFalse: [ ^ nil ].
	value := aBooleanOrString asString trimBoth asLowercase.
	value = 'true' ifTrue: [ ^ true ].
	value = 'false' ifTrue: [ ^ false ].
	^ nil
]

{ #category : 'private' }
OTOtlpExporterConfiguration class >> strictNonNegativeIntegerFrom: aString [

	| stream value |
	stream := aString trimBoth readStream.
	stream atEnd ifTrue: [ ^ nil ].
	value := [ Integer readFrom: stream ]
		         on: Error
		         do: [ ^ nil ].
	stream atEnd ifFalse: [ ^ nil ].
	value >= 0 ifFalse: [ ^ nil ].
	^ value
]

{ #category : 'private' }
OTOtlpExporterConfiguration class >> strictPositiveIntegerFrom: aString [

	| stream value |
	stream := aString trimBoth readStream.
	stream atEnd ifTrue: [ ^ nil ].
	value := [ Integer readFrom: stream ]
		         on: Error
		         do: [ ^ nil ].
	stream atEnd ifFalse: [ ^ nil ].
	value > 0 ifFalse: [ ^ nil ].
	^ value
]

{ #category : 'private' }
OTOtlpExporterConfiguration class >> timeoutMillisFromEnvironmentForSignalNamed: aSignalName [

	| parsedValue signalVariable sharedVariable value |
	signalVariable := self signalEnvironmentNameFor: aSignalName suffix: 'TIMEOUT'.
	value := self environmentValueAt: signalVariable.
	value ifNotNil: [
			parsedValue := self strictNonNegativeIntegerFrom: value.
			parsedValue ifNotNil: [
					^ parsedValue = 0
						  ifTrue: [ self noTimeoutMillis ]
						  ifFalse: [ parsedValue ] ].
			self noteInvalidEnvironmentValue: value forVariable: signalVariable ].
	sharedVariable := 'OTEL_EXPORTER_OTLP_TIMEOUT'.
	value := self environmentValueAt: sharedVariable.
	value ifNotNil: [
			parsedValue := self strictNonNegativeIntegerFrom: value.
			parsedValue ifNotNil: [
					^ parsedValue = 0
						  ifTrue: [ self noTimeoutMillis ]
						  ifFalse: [ parsedValue ] ].
			self noteInvalidEnvironmentValue: value forVariable: sharedVariable ].
	^ self defaultTimeoutMillis
]

{ #category : 'private - logging' }
OTOtlpExporterConfiguration class >> warningSink [

	^ OTClassStateStore valueAt: #otWarningSink forClass: self ifAbsent: [ self defaultWarningSink ]
]

{ #category : 'private - logging' }
OTOtlpExporterConfiguration class >> warningSink: aBlock [

	aBlock
		ifNil: [ OTClassStateStore removeValueAt: #otWarningSink forClass: self ifAbsent: [ ] ]
		ifNotNil: [ OTClassStateStore valueAt: #otWarningSink forClass: self put: aBlock ].
	^ self warningSink
]

{ #category : 'comparing' }
OTOtlpExporterConfiguration >> = anObject [

	self == anObject ifTrue: [ ^ true ].
	anObject class == self class ifFalse: [ ^ false ].
	^ {
		  self signalName.
		  self relativePath.
		  self endpoint.
		  self protocol.
		  self headers.
		  self timeoutMillis.
		  self compression.
		  self userAgent.
		  self insecure.
		  self certificateFile.
		  self clientKeyFile.
		  self clientCertificateFile } = {
		  anObject signalName.
		  anObject relativePath.
		  anObject endpoint.
		  anObject protocol.
		  anObject headers.
		  anObject timeoutMillis.
		  anObject compression.
		  anObject userAgent.
		  anObject insecure.
		  anObject certificateFile.
		  anObject clientKeyFile.
		  anObject clientCertificateFile }
]

{ #category : 'accessing' }
OTOtlpExporterConfiguration >> certificateFile [

	^ certificateFile
]

{ #category : 'accessing' }
OTOtlpExporterConfiguration >> certificateFile: aStringOrNil [

	certificateFile := aStringOrNil
]

{ #category : 'accessing' }
OTOtlpExporterConfiguration >> clientCertificateFile [

	^ clientCertificateFile
]

{ #category : 'accessing' }
OTOtlpExporterConfiguration >> clientCertificateFile: aStringOrNil [

	clientCertificateFile := aStringOrNil
]

{ #category : 'accessing' }
OTOtlpExporterConfiguration >> clientKeyFile [

	^ clientKeyFile
]

{ #category : 'accessing' }
OTOtlpExporterConfiguration >> clientKeyFile: aStringOrNil [

	clientKeyFile := aStringOrNil
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
			  self isGrpcProtocol
				  ifTrue: [ self class normalizedGrpcEndpoint: self class defaultBaseGrpcEndpoint insecure: false ]
				  ifFalse: [ self class normalizedBaseEndpoint: self class defaultBaseHttpEndpoint appendingRelativePath: self relativePath ] ]
]

{ #category : 'accessing' }
OTOtlpExporterConfiguration >> endpoint: aString [

	endpoint := aString
]

{ #category : 'testing' }
OTOtlpExporterConfiguration >> hasClientCertificateConfiguration [

	^ self clientKeyFile notNil or: [ self clientCertificateFile notNil ]
]

{ #category : 'testing' }
OTOtlpExporterConfiguration >> hasTlsFileOverrides [

	^ self certificateFile notNil or: [ self hasClientCertificateConfiguration ]
]

{ #category : 'comparing' }
OTOtlpExporterConfiguration >> hash [

	^ {
		  self signalName.
		  self relativePath.
		  self endpoint.
		  self protocol.
		  self headers.
		  self timeoutMillis.
		  self compression.
		  self userAgent.
		  self insecure.
		  self certificateFile.
		  self clientKeyFile.
		  self clientCertificateFile } hash
]

{ #category : 'accessing' }
OTOtlpExporterConfiguration >> headers [

	^ headers ifNil: [ OrderedDictionary new ]
]

{ #category : 'accessing' }
OTOtlpExporterConfiguration >> headers: aDictionary [

	headers := aDictionary
]

{ #category : 'accessing' }
OTOtlpExporterConfiguration >> insecure [

	^ insecure ifNil: [ false ]
]

{ #category : 'accessing' }
OTOtlpExporterConfiguration >> insecure: aBoolean [

	insecure := aBoolean
]

{ #category : 'testing' }
OTOtlpExporterConfiguration >> isGrpcProtocol [

	^ self protocol = 'grpc'
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

	^ relativePath ifNil: [ self class defaultRelativePathForSignalNamed: self signalName ]
]

{ #category : 'accessing' }
OTOtlpExporterConfiguration >> relativePath: aString [

	relativePath := aString
]

{ #category : 'accessing' }
OTOtlpExporterConfiguration >> resolvedGrpcEndpoint [

	^ self class normalizedGrpcEndpoint: self endpoint insecure: self insecure
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
OTOtlpExporterConfiguration >> timeoutMillisOrNil [

	^ self usesUnlimitedTimeout
		  ifTrue: [ nil ]
		  ifFalse: [ self timeoutMillis ]
]

{ #category : 'accessing' }
OTOtlpExporterConfiguration >> userAgent [

	^ userAgent ifNil: [ self class defaultUserAgent ]
]

{ #category : 'accessing' }
OTOtlpExporterConfiguration >> userAgent: aString [

	userAgent := aString
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

{ #category : 'testing' }
OTOtlpExporterConfiguration >> usesSecureConnection [

	| endpointString url |
	endpointString := self isGrpcProtocol
		                  ifTrue: [ self resolvedGrpcEndpoint ]
		                  ifFalse: [ self endpoint ].
	url := [ ZnUrl fromString: endpointString ]
		       on: Error
		       do: [ ^ false ].
	^ url scheme = 'https'
]

{ #category : 'testing' }
OTOtlpExporterConfiguration >> usesUnlimitedTimeout [

	^ self timeoutMillis = self class noTimeoutMillis
]
