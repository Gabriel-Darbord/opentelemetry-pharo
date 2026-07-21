"
A backend-agnostic entry point to the tracing API. It owns Tracer instances and their shared configuration surface.
"
Class {
	#name : 'OTTracerProvider',
	#superclass : 'Object',
	#instVars : [
		'tracers',
		'stateLock',
		'shutdownRequested',
		'shutdownCompleted'
	],
	#classVars : [
		'Current'
	],
	#category : 'OpenTelemetry-Instrumentation',
	#package : 'OpenTelemetry-Instrumentation'
}

{ #category : 'instance creation' }
OTTracerProvider class >> configuredResource [

	| resource |
	resource := OTConfigurationSource configuredResource.
	^ resource ifNil: [ self resourceFromDetectors: self configuredResourceDetectors ]
]

{ #category : 'private' }
OTTracerProvider class >> configuredResourceAttributes [

	| rawValue |
	rawValue := self environmentValueAt: 'OTEL_RESOURCE_ATTRIBUTES'.
	rawValue ifNil: [ ^ OrderedDictionary new ].
	^ [ self resourceAttributesFromEnvironment: rawValue ]
		on: Error
		do: [ :error |
			self noteInvalidResourceAttributes: rawValue error: error.
			OrderedDictionary new ]
]

{ #category : 'instance creation' }
OTTracerProvider class >> configuredResourceDetectors [

	^ OTClassStateStore
		valueAt: #otResourceDetectors
		forClass: self
		ifAbsent: [ self defaultResourceDetectors ]
]

{ #category : 'instance creation' }
OTTracerProvider class >> configuredSampler [

	^ self configuredSamplerForResource: self configuredResource
]

{ #category : 'instance creation' }
OTTracerProvider class >> configuredSamplerForResource: anOTResource [

	| configuredSampler samplerName samplerArgument |
	configuredSampler := OTConfigurationSource configuredSamplerForResource: anOTResource.
	configuredSampler ifNotNil: [ ^ configuredSampler ].
	samplerName := self environmentValueAt: 'OTEL_TRACES_SAMPLER'.
	samplerName ifNil: [ ^ self defaultSampler ].
	samplerArgument := self environmentValueAt: 'OTEL_TRACES_SAMPLER_ARG'.
	^ self
		samplerFromEnvironmentName: samplerName
		argument: samplerArgument
		resource: anOTResource
]

{ #category : 'private' }
OTTracerProvider class >> configuredServiceName [

	^ self environmentValueAt: 'OTEL_SERVICE_NAME'
]

{ #category : 'instance creation' }
OTTracerProvider class >> configuredSpanLimits [

	| defaultLimits generalAttributeCountLimit generalValueLengthLimit limits |
	defaultLimits := OTSpanLimits default.
	generalAttributeCountLimit := self nonNegativeIntegerEnvironmentValueAt: 'OTEL_ATTRIBUTE_COUNT_LIMIT' default: defaultLimits attributeCountLimit.
	generalValueLengthLimit := self nonNegativeIntegerEnvironmentValueAt: 'OTEL_ATTRIBUTE_VALUE_LENGTH_LIMIT' default: defaultLimits attributeValueLengthLimit.
	limits := OTSpanLimits default.
	limits
		attributeCountLimit: (self nonNegativeIntegerEnvironmentValueAt: 'OTEL_SPAN_ATTRIBUTE_COUNT_LIMIT' default: generalAttributeCountLimit);
		attributeValueLengthLimit: (self nonNegativeIntegerEnvironmentValueAt: 'OTEL_SPAN_ATTRIBUTE_VALUE_LENGTH_LIMIT' default: generalValueLengthLimit);
		eventCountLimit: (self nonNegativeIntegerEnvironmentValueAt: 'OTEL_SPAN_EVENT_COUNT_LIMIT' default: defaultLimits eventCountLimit);
		linkCountLimit: (self nonNegativeIntegerEnvironmentValueAt: 'OTEL_SPAN_LINK_COUNT_LIMIT' default: defaultLimits linkCountLimit);
		attributePerEventCountLimit: (self nonNegativeIntegerEnvironmentValueAt: 'OTEL_EVENT_ATTRIBUTE_COUNT_LIMIT' default: defaultLimits attributePerEventCountLimit);
		attributePerLinkCountLimit: (self nonNegativeIntegerEnvironmentValueAt: 'OTEL_LINK_ATTRIBUTE_COUNT_LIMIT' default: defaultLimits attributePerLinkCountLimit).
	^ limits
]

{ #category : 'accessing' }
OTTracerProvider class >> current [

	^ self currentLock critical: [ Current ifNil: [ Current := self readConfiguration ] ]
]

{ #category : 'accessing' }
OTTracerProvider class >> current: aTracerProvider [

	self currentLock critical: [ Current := aTracerProvider ]
]

{ #category : 'instance creation' }
OTTracerProvider class >> currentImagePath [

	^ self systemAttributeAt: 1
]

{ #category : 'private' }
OTTracerProvider class >> currentLock [

	^ OTClassStateStore valueAt: #otCurrentLock forClass: self ifAbsent: [
			  | lock |
			  lock := Semaphore forMutualExclusion.
			  OTClassStateStore valueAt: #otCurrentLock forClass: self put: lock.
			  lock ]
]

{ #category : 'instance creation' }
OTTracerProvider class >> currentProcessId [

	| libc |
	libc := Smalltalk at: #LibC ifAbsent: [ ^ nil ].
	^ [ libc uniqueInstance currentProcessId ]
		on: Error
		do: [ nil ]
]

{ #category : 'private' }
OTTracerProvider class >> decodePercentEncoded: aString [

	^ String streamContents: [ :decoded |
		| index |
		index := 1.
		[ index <= aString size ] whileTrue: [
			| character |
			character := aString at: index.
			character = $%
				ifTrue: [
					index + 2 <= aString size ifFalse: [ Error signal: 'Malformed percent encoding' ].
					decoded nextPut: (Character value: (self hexadecimalValueFrom: (aString copyFrom: index + 1 to: index + 2))).
					index := index + 3 ]
				ifFalse: [
					decoded nextPut: character.
					index := index + 1 ] ] ]
]

{ #category : 'instance creation' }
OTTracerProvider class >> defaultHostArchitecture [

	^ [ | architecture |
		architecture := Smalltalk os current processorArchitecture asString trimBoth asLowercase.
		architecture isEmpty ifTrue: [ nil ] ifFalse: [ architecture ] ]
		on: Error
		do: [ nil ]
]

{ #category : 'instance creation' }
OTTracerProvider class >> defaultHostName [

	^ [ | hostName |
		hostName := NetNameResolver localHostName asString trimBoth.
		hostName isEmpty ifTrue: [ nil ] ifFalse: [ hostName ] ]
		on: Error
		do: [ nil ]
]

{ #category : 'instance creation' }
OTTracerProvider class >> defaultIdGenerator [

	^ OTIdGenerator default
]

{ #category : 'instance creation' }
OTTracerProvider class >> defaultOsDescription [

	| osSubtype osVersion parts |
	parts := OrderedCollection new.
	self defaultOsName ifNotNil: [ :value | parts add: value ].
	osVersion := [ Smalltalk os version asString trimBoth ]
		on: Error
		do: [ nil ].
	(osVersion notNil and: [ osVersion isNotEmpty ]) ifTrue: [ parts add: osVersion ].
	osSubtype := [ Smalltalk os subtype asString trimBoth ]
		on: Error
		do: [ nil ].
	(osSubtype notNil and: [ osSubtype isNotEmpty ]) ifTrue: [ parts add: osSubtype ].
	parts isEmpty ifTrue: [ ^ nil ].
	^ String streamContents: [ :stream |
		parts
			do: [ :each | stream nextPutAll: each ]
			separatedBy: [ stream space ] ]
]

{ #category : 'instance creation' }
OTTracerProvider class >> defaultOsName [

	^ [ | name |
		name := Smalltalk os name asString trimBoth.
		name isEmpty ifTrue: [ nil ] ifFalse: [ name ] ]
		on: Error
		do: [ nil ]
]

{ #category : 'instance creation' }
OTTracerProvider class >> defaultOsType [

	| os name |
	os := [ Smalltalk os current ] on: Error do: [ nil ].
	os ifNil: [ ^ nil ].
	(os isLinux) ifTrue: [ ^ 'linux' ].
	(os isWindows) ifTrue: [ ^ 'windows' ].
	((os isMacOS) or: [ os isMacOSX ]) ifTrue: [ ^ 'darwin' ].
	name := [ os name asString trimBoth asLowercase ] on: Error do: [ '' ].
	(name includesSubstring: 'freebsd') ifTrue: [ ^ 'freebsd' ].
	(name includesSubstring: 'netbsd') ifTrue: [ ^ 'netbsd' ].
	(name includesSubstring: 'openbsd') ifTrue: [ ^ 'openbsd' ].
	((name includesSubstring: 'sunos') or: [ name includesSubstring: 'solaris' ]) ifTrue: [ ^ 'solaris' ].
	(name includesSubstring: 'aix') ifTrue: [ ^ 'aix' ].
	((name includesSubstring: 'hp-ux') or: [ name includesSubstring: 'hpux' ]) ifTrue: [ ^ 'hpux' ].
	^ nil
]

{ #category : 'instance creation' }
OTTracerProvider class >> defaultProcessExecutableName [

	| path |
	path := self defaultProcessExecutablePath.
	path ifNil: [ ^ nil ].
	^ [ path asFileReference basename ]
		on: Error
		do: [ nil ]
]

{ #category : 'instance creation' }
OTTracerProvider class >> defaultProcessExecutablePath [

	^ self systemAttributeAt: 0
]

{ #category : 'instance creation' }
OTTracerProvider class >> defaultResource [

	^ OTResource
		attributes: (OrderedDictionary new
			at: 'service.name' put: self defaultServiceName;
			at: 'telemetry.sdk.name' put: 'opentelemetry';
			at: 'telemetry.sdk.language' put: 'pharo';
			at: 'telemetry.sdk.version' put: self sdkVersion;
			yourself)
		schemaUrl: self semanticConventionsSchemaUrl
]

{ #category : 'private - logging' }
OTTracerProvider class >> defaultResourceConfigurationWarningSink [

	^ OTDiagnosticLogger defaultWarningSink
]

{ #category : 'instance creation' }
OTTracerProvider class >> defaultResourceDetectors [

	^ OrderedCollection new
		add: (OTStaticResourceDetector named: 'sdk' resource: self defaultResource);
		add: OTHostResourceDetector new;
		add: OTProcessResourceDetector new;
		add: OTEnvironmentResourceDetector new;
		add: OTServiceNameResourceDetector new;
		yourself
]

{ #category : 'instance creation' }
OTTracerProvider class >> defaultSampler [

	^ OTParentBasedSampler default
]

{ #category : 'private - logging' }
OTTracerProvider class >> defaultSamplerConfigurationWarningSink [

	^ OTDiagnosticLogger defaultWarningSink
]

{ #category : 'instance creation' }
OTTracerProvider class >> defaultServiceInstanceId [

	| identifier |
	identifier := OTClassStateStore
		valueAt: #otDefaultServiceInstanceId
		forClass: self
		ifAbsent: [ nil ].
	identifier ifNil: [
		identifier := UUID new asString36.
		OTClassStateStore
			valueAt: #otDefaultServiceInstanceId
			forClass: self
			put: identifier ].
	^ identifier
]

{ #category : 'instance creation' }
OTTracerProvider class >> defaultServiceName [

	| executableName |
	executableName := self defaultProcessExecutableName.
	^ executableName
		ifNil: [ 'unknown_service' ]
		ifNotNil: [ 'unknown_service:' , executableName ]
]

{ #category : 'private - logging' }
OTTracerProvider class >> defaultSpanProcessorWarningSink [

	^ OTDiagnosticLogger defaultWarningSink
]

{ #category : 'private - logging' }
OTTracerProvider class >> defaultTracerConfigurationWarningSink [

	^ OTDiagnosticLogger defaultWarningSink
]

{ #category : 'private - logging' }
OTTracerProvider class >> defaultTracerNameWarningSink [

	^ OTDiagnosticLogger defaultWarningSink
]

{ #category : 'private' }
OTTracerProvider class >> environmentValueAt: aString [

	^ OTConfigurationSource environmentValueAt: aString
]

{ #category : 'private' }
OTTracerProvider class >> hexadecimalValueFrom: aString [

	| stream value |
	stream := aString readStream.
	value := [ Integer readFrom: stream base: 16 ] on: Error do: [ Error signal: 'Malformed percent encoding' ].
	stream atEnd ifFalse: [ Error signal: 'Malformed percent encoding' ].
	^ value
]

{ #category : 'private' }
OTTracerProvider class >> idGeneratorByProvider [

	^ self stateDictionaryAt: #otIdGeneratorByProvider
]

{ #category : 'private' }
OTTracerProvider class >> integerEnvironmentValueAt: aString default: aDefaultValue [

	| rawValue parsed |
	rawValue := self environmentValueAt: aString.
	rawValue ifNil: [ ^ aDefaultValue ].
	parsed := self strictPositiveIntegerFrom: rawValue.
	^ parsed ifNil: [ aDefaultValue ] ifNotNil: [ parsed ]
]

{ #category : 'private' }
OTTracerProvider class >> invalidateCurrent [

	| previous |
	previous := self currentLock critical: [
			            | captured |
			            captured := Current.
			            Current := nil.
			            captured ].
	previous ifNotNil: [ previous shutdown ]
]

{ #category : 'private' }
OTTracerProvider class >> jaegerRemoteSamplerForResource: anOTResource argument: anotherString parentBased: aBoolean [

	| configuredSampler options sampler samplerName |
	samplerName := aBoolean
		ifTrue: [ 'parentbased_jaeger_remote' ]
		ifFalse: [ 'jaeger_remote' ].
	OTJaegerRemoteSampler grpcDependenciesAvailable ifFalse: [
		self noteMissingGrpcDependencyForSampler: samplerName.
		^ self defaultSampler ].
	options := self strictJaegerRemoteSamplerOptionsFrom: anotherString.
	(anotherString notNil and: [ options isNil ]) ifTrue: [
		self noteInvalidSamplerArgument: anotherString forSampler: samplerName ].
	sampler := OTJaegerRemoteSampler serviceName: (self serviceNameForSamplerResource: anOTResource).
	options ifNotNil: [ self updateJaegerRemoteSampler: sampler withOptions: options ].
	configuredSampler := aBoolean
		ifTrue: [
			OTParentBasedSampler default
				rootSampler: sampler;
				yourself ]
		ifFalse: [ sampler ].
	^ configuredSampler
]

{ #category : 'private' }
OTTracerProvider class >> nonNegativeIntegerEnvironmentValueAt: aString default: aDefaultValue [

	| rawValue parsed |
	rawValue := self environmentValueAt: aString.
	rawValue ifNil: [ ^ aDefaultValue ].
	parsed := self strictNonNegativeIntegerFrom: rawValue.
	^ parsed ifNil: [ aDefaultValue ] ifNotNil: [ parsed ]
]

{ #category : 'private' }
OTTracerProvider class >> normalizedTracerNameFrom: aValue [

	| name |
	aValue ifNil: [
		self noteInvalidTracerName: aValue.
		^ '' ].
	name := aValue asString.
	name trimBoth isEmpty ifTrue: [
		self noteInvalidTracerName: aValue.
		^ '' ].
	^ name
]

{ #category : 'private - logging' }
OTTracerProvider class >> noteDuplicateResourceDetectorName: aString [

	self resourceConfigurationWarningSink value:
		'OpenTelemetry resource detector name was registered more than once: '
			, aString printString
]

{ #category : 'private - logging' }
OTTracerProvider class >> noteInvalidResourceAttributes: aValue error: anError [

	self resourceConfigurationWarningSink value:
		'OpenTelemetry resource attributes configuration was invalid and has been ignored: '
			, aValue printString
			, ' ('
			, anError messageText
			, ')'
]

{ #category : 'private - logging' }
OTTracerProvider class >> noteInvalidSamplerArgument: aValue forSampler: aSamplerName [

	self samplerConfigurationWarningSink value:
		'OpenTelemetry sampler argument was invalid and has been ignored for '
			, aSamplerName printString
			, ': '
			, aValue printString
]

{ #category : 'private - logging' }
OTTracerProvider class >> noteInvalidTracerName: aValue [

	self tracerNameWarningSink value:
		'OpenTelemetry tracer name was invalid and has been normalized to an empty string: '
			, (aValue ifNil: [ 'nil' ] ifNotNil: [ aValue printString ])
]

{ #category : 'private - logging' }
OTTracerProvider class >> noteMissingGrpcDependencyForSampler: aSamplerName [

	self samplerConfigurationWarningSink value:
		'OpenTelemetry sampler requires grpc-pharo to be loaded and has been ignored for '
			, aSamplerName printString
]

{ #category : 'private - logging' }
OTTracerProvider class >> noteResourceDetector: aDetector failedDuring: anOperationName error: anError [

	| message |
	message := 'OpenTelemetry resource detector failed during '
		, anOperationName
		, ' for '
		, aDetector class name
		, ' ('
		, aDetector detectorName printString
		, '): '
		, anError messageText.
	OTDiagnosticLogger current
		handleSuppressedError: anError
		message: message
		fallback: [ self resourceConfigurationWarningSink value: message ]
]

{ #category : 'private - logging' }
OTTracerProvider class >> noteSampler: aSampler failedDuring: anOperationName error: anError [

	| message |
	message := 'OpenTelemetry sampler callback failed during '
		, anOperationName
		, ' for '
		, aSampler class name
		, ': '
		, anError messageText.
	OTDiagnosticLogger current
		handleSuppressedError: anError
		message: message
		fallback: [ self samplerConfigurationWarningSink value: message ]
]

{ #category : 'private - logging' }
OTTracerProvider class >> noteSpanProcessor: aProcessor failedDuring: anOperationName error: anError [

	| message |
	message := 'OpenTelemetry span processor callback failed during '
		, anOperationName
		, ' for '
		, aProcessor class name
		, ': '
		, anError messageText.
	OTDiagnosticLogger current
		handleSuppressedError: anError
		message: message
		fallback: [ self spanProcessorWarningSink value: message ]
]

{ #category : 'private - logging' }
OTTracerProvider class >> noteTracerConfigurationFailedDuring: anOperationName error: anError [

	| message |
	message := 'OpenTelemetry tracer configuration callback failed during '
		, anOperationName
		, ': '
		, anError messageText.
	OTDiagnosticLogger current
		handleSuppressedError: anError
		message: message
		fallback: [ self tracerConfigurationWarningSink value: message ]
]

{ #category : 'private - logging' }
OTTracerProvider class >> noteUnknownSamplerName: aValue [

	self samplerConfigurationWarningSink value:
		'OpenTelemetry sampler name was unrecognized and has been ignored: '
			, aValue printString
]

{ #category : 'private - logging' }
OTTracerProvider class >> noteUnsupportedSamplerName: aValue [

	self samplerConfigurationWarningSink value:
		'OpenTelemetry sampler name is recognized but not supported by this SDK yet: '
			, aValue printString
]

{ #category : 'instance creation' }
OTTracerProvider class >> processCommandArguments [

	| arguments imagePath |
	arguments := OrderedCollection new.
	self defaultProcessExecutablePath ifNotNil: [ :value | arguments add: value ].
	imagePath := self currentImagePath.
	imagePath ifNotNil: [ arguments add: imagePath ].
	2 to: 32 do: [ :index |
		| value |
		value := self systemAttributeAt: index.
		value ifNil: [ ^ arguments asArray ].
		arguments add: value ].
	^ arguments asArray
]

{ #category : 'instance creation' }
OTTracerProvider class >> processCommandLine [

	| arguments |
	arguments := self processCommandArguments.
	arguments ifEmpty: [ ^ nil ].
	^ String streamContents: [ :stream |
		arguments doWithIndex: [ :each :index |
			index > 1 ifTrue: [ stream space ].
			self writeShellQuotedCommandArgument: each on: stream ] ]
]

{ #category : 'instance creation' }
OTTracerProvider class >> readConfiguration [

	| exporter explicitProcessor provider resource processors |
	provider := self new.
	exporter := OTSpanExporter current.
	explicitProcessor := OTSpanProcessor currentIfSet.
	resource := self configuredResource.
	provider
		resource: resource;
		sampler: (self configuredSamplerForResource: resource);
		spanLimits: self configuredSpanLimits;
		tracerConfigurator: OTConfigurationSource configuredTracerConfigurator.
	processors := explicitProcessor
		ifNil: [
			(self sdkDisabled or: [ exporter class == OTNoopSpanExporter ])
				ifTrue: [ #() ]
				ifFalse: [ OTSpanProcessor current componentProcessors ] ]
		ifNotNil: [ explicitProcessor componentProcessors ].
	provider spanProcessors: processors.
	^ provider
]

{ #category : 'class initialization' }
OTTracerProvider class >> reset [

	Current ifNotNil: [ Current shutdown ].
	OTConfigurationSource reset.
	Current := nil.
	self resourceDetectors: nil
]

{ #category : 'private' }
OTTracerProvider class >> resourceAttributesFromEnvironment: aString [

	| attributes start |
	aString ifEmpty: [ ^ OrderedDictionary new ].
	attributes := OrderedDictionary new.
	start := 1.
	1 to: aString size do: [ :index |
		(aString at: index) = $, ifTrue: [
			self resourceEnvironmentEntry: (aString copyFrom: start to: index - 1) into: attributes.
			start := index + 1 ] ].
	self resourceEnvironmentEntry: (aString copyFrom: start to: aString size) into: attributes.
	^ attributes
]

{ #category : 'private' }
OTTracerProvider class >> resourceByProvider [

	^ self stateDictionaryAt: #otResourceByProvider
]

{ #category : 'private - logging' }
OTTracerProvider class >> resourceConfigurationWarningSink [

	^ OTClassStateStore
		valueAt: #otResourceConfigurationWarningSink
		forClass: self
		ifAbsent: [ self defaultResourceConfigurationWarningSink ]
]

{ #category : 'private - logging' }
OTTracerProvider class >> resourceConfigurationWarningSink: aBlock [

	aBlock
		ifNil: [
			OTClassStateStore
				removeValueAt: #otResourceConfigurationWarningSink
				forClass: self
				ifAbsent: [  ] ]
		ifNotNil: [
			OTClassStateStore
				valueAt: #otResourceConfigurationWarningSink
				forClass: self
				put: aBlock ].
	^ self resourceConfigurationWarningSink
]

{ #category : 'instance creation' }
OTTracerProvider class >> resourceDetectors: aCollection [

	aCollection
		ifNil: [
			OTClassStateStore
				removeValueAt: #otResourceDetectors
				forClass: self
				ifAbsent: [  ] ]
		ifNotNil: [
			OTClassStateStore
				valueAt: #otResourceDetectors
				forClass: self
				put: aCollection ].
	^ self configuredResourceDetectors
]

{ #category : 'private' }
OTTracerProvider class >> resourceEnvironmentEntry: aString into: anOrderedDictionary [

	| separator key value |
	aString isEmpty ifTrue: [ Error signal: 'Malformed resource attribute entry' ].
	separator := aString indexOf: $=.
	separator = 0 ifTrue: [ Error signal: 'Malformed resource attribute entry' ].
	key := self decodePercentEncoded: (aString copyFrom: 1 to: separator - 1).
	value := self decodePercentEncoded: (aString copyFrom: separator + 1 to: aString size).
	key isEmpty ifTrue: [ Error signal: 'Resource attribute keys must not be empty' ].
	anOrderedDictionary at: key put: value
]

{ #category : 'private' }
OTTracerProvider class >> resourceFromDetectors: aCollection [

	| detectorNames resource |
	detectorNames := Set new.
	resource := OTResource empty.
	aCollection do: [ :detector |
		(detectorNames includes: detector detectorName) ifTrue: [
			self noteDuplicateResourceDetectorName: detector detectorName ].
		detectorNames add: detector detectorName.
		resource := [ resource merge: detector detectResource ]
			on: Error
			do: [ :error |
				self noteResourceDetector: detector failedDuring: 'resource detection' error: error.
				resource ] ].
	^ resource
]

{ #category : 'instance creation' }
OTTracerProvider class >> runtimeDescription [

	^ [ Smalltalk vm version trimBoth ]
		on: Error
		do: [ self runtimeName ]
]

{ #category : 'instance creation' }
OTTracerProvider class >> runtimeName [

	^ 'pharo'
]

{ #category : 'instance creation' }
OTTracerProvider class >> runtimeVersion [

	^ [ SystemVersion current dottedMajorMinor ]
		on: Error
		do: [ 'unknown' ]
]

{ #category : 'private' }
OTTracerProvider class >> samplerByProvider [

	^ self stateDictionaryAt: #otSamplerByProvider
]

{ #category : 'private - logging' }
OTTracerProvider class >> samplerConfigurationWarningSink [

	^ OTClassStateStore
		valueAt: #otSamplerConfigurationWarningSink
		forClass: self
		ifAbsent: [ self defaultSamplerConfigurationWarningSink ]
]

{ #category : 'private - logging' }
OTTracerProvider class >> samplerConfigurationWarningSink: aBlock [

	aBlock
		ifNil: [
			OTClassStateStore
				removeValueAt: #otSamplerConfigurationWarningSink
				forClass: self
				ifAbsent: [  ] ]
		ifNotNil: [
			OTClassStateStore
				valueAt: #otSamplerConfigurationWarningSink
				forClass: self
				put: aBlock ].
	^ self samplerConfigurationWarningSink
]

{ #category : 'private' }
OTTracerProvider class >> samplerFromEnvironmentName: aString argument: anotherString [

	^ self
		samplerFromEnvironmentName: aString
		argument: anotherString
		resource: self configuredResource
]

{ #category : 'private' }
OTTracerProvider class >> samplerFromEnvironmentName: aString argument: anotherString resource: anOTResource [

	| samplerName probability rootSampler |
	samplerName := aString asString trimBoth asLowercase.
	probability := self strictProbabilityFrom: anotherString.
	samplerName = 'always_on' ifTrue: [ ^ OTAlwaysOnSampler new ].
	samplerName = 'always_off' ifTrue: [ ^ OTAlwaysOffSampler new ].
	samplerName = 'traceidratio' ifTrue: [
		(anotherString notNil and: [ probability isNil ]) ifTrue: [
			self noteInvalidSamplerArgument: anotherString forSampler: samplerName ].
		^ OTTraceIdRatioBasedSampler new
			probability: (probability ifNil: [ 1 ]);
			yourself ].
	samplerName = 'parentbased_always_on' ifTrue: [
		^ OTParentBasedSampler default
			rootSampler: OTAlwaysOnSampler new;
			yourself ].
	samplerName = 'parentbased_always_off' ifTrue: [
		^ OTParentBasedSampler default
			rootSampler: OTAlwaysOffSampler new;
			yourself ].
	samplerName = 'parentbased_traceidratio' ifTrue: [
		(anotherString notNil and: [ probability isNil ]) ifTrue: [
			self noteInvalidSamplerArgument: anotherString forSampler: samplerName ].
		rootSampler := OTTraceIdRatioBasedSampler new
			probability: (probability ifNil: [ 1 ]);
			yourself.
		^ OTParentBasedSampler default
			rootSampler: rootSampler;
			yourself ].
	samplerName = 'jaeger_remote' ifTrue: [
		^ self
			jaegerRemoteSamplerForResource: anOTResource
			argument: anotherString
			parentBased: false ].
	samplerName = 'parentbased_jaeger_remote' ifTrue: [
		^ self
			jaegerRemoteSamplerForResource: anOTResource
			argument: anotherString
			parentBased: true ].
	samplerName = 'xray' ifTrue: [
		self noteUnsupportedSamplerName: samplerName.
		^ self defaultSampler ].
	self noteUnknownSamplerName: samplerName.
	^ self defaultSampler
]

{ #category : 'private' }
OTTracerProvider class >> sdkDisabled [

	| value |
	value := self environmentValueAt: 'OTEL_SDK_DISABLED'.
	value ifNil: [ ^ false ].
	^ value asLowercase = 'true'
]

{ #category : 'instance creation' }
OTTracerProvider class >> sdkVersion [

	^ 'dev'
]

{ #category : 'instance creation' }
OTTracerProvider class >> semanticConventionsSchemaUrl [

	^ 'https://opentelemetry.io/schemas/1.21.0'
]

{ #category : 'private' }
OTTracerProvider class >> serviceNameForSamplerResource: anOTResource [

	anOTResource ifNil: [ ^ self defaultServiceName ].
	^ anOTResource serviceName ifNil: [ self defaultServiceName ]
]

{ #category : 'private - lifecycle' }
OTTracerProvider class >> shutdownByProvider [

	^ self stateDictionaryAt: #otShutdownByProvider
]

{ #category : 'private' }
OTTracerProvider class >> spanLimitsByProvider [

	^ self stateDictionaryAt: #otSpanLimitsByProvider
]

{ #category : 'private - logging' }
OTTracerProvider class >> spanProcessorWarningSink [

	^ OTClassStateStore
		valueAt: #otSpanProcessorWarningSink
		forClass: self
		ifAbsent: [ self defaultSpanProcessorWarningSink ]
]

{ #category : 'private - logging' }
OTTracerProvider class >> spanProcessorWarningSink: aBlock [

	aBlock
		ifNil: [
			OTClassStateStore
				removeValueAt: #otSpanProcessorWarningSink
				forClass: self
				ifAbsent: [  ] ]
		ifNotNil: [
			OTClassStateStore
				valueAt: #otSpanProcessorWarningSink
				forClass: self
				put: aBlock ].
	^ self spanProcessorWarningSink
]

{ #category : 'private' }
OTTracerProvider class >> spanProcessorsByProvider [

	^ self stateDictionaryAt: #otSpanProcessorsByProvider
]

{ #category : 'private' }
OTTracerProvider class >> stateDictionaryAt: aSymbol [

	| dictionary |
	dictionary := OTClassStateStore
		valueAt: aSymbol
		forClass: self
		ifAbsent: [ nil ].
	dictionary ifNil: [
		dictionary := WeakIdentityKeyDictionary new.
		OTClassStateStore
			valueAt: aSymbol
			forClass: self
			put: dictionary ].
	^ dictionary
]

{ #category : 'private' }
OTTracerProvider class >> strictJaegerRemoteSamplerOption: aString into: anOrderedDictionary [

	| key parsedValue separator value |
	aString isEmpty ifTrue: [ Error signal: 'Malformed Jaeger remote sampler option' ].
	separator := aString indexOf: $=.
	separator <= 1 ifTrue: [ Error signal: 'Malformed Jaeger remote sampler option' ].
	key := (aString copyFrom: 1 to: separator - 1) trimBoth.
	value := (aString copyFrom: separator + 1 to: aString size) trimBoth.
	value isEmpty ifTrue: [ Error signal: 'Malformed Jaeger remote sampler option' ].
	key = 'endpoint' ifTrue: [
		parsedValue := OTJaegerRemoteSampler normalizedEndpoint: value.
		anOrderedDictionary at: key put: parsedValue.
		^ self ].
	key = 'pollingIntervalMs' ifTrue: [
		parsedValue := self strictPositiveIntegerFrom: value.
		parsedValue ifNil: [ Error signal: 'Invalid Jaeger remote polling interval' ].
		anOrderedDictionary at: key put: parsedValue.
		^ self ].
	key = 'initialSamplingRate' ifTrue: [
		parsedValue := self strictProbabilityFrom: value.
		parsedValue ifNil: [ Error signal: 'Invalid Jaeger remote initial sampling rate' ].
		anOrderedDictionary at: key put: parsedValue.
		^ self ].
	Error signal: 'Unrecognized Jaeger remote sampler option'
]

{ #category : 'private' }
OTTracerProvider class >> strictJaegerRemoteSamplerOptionsFrom: aString [

	| options rawValue |
	aString ifNil: [ ^ OrderedDictionary new ].
	rawValue := aString asString trimBoth.
	rawValue isEmpty ifTrue: [ ^ OrderedDictionary new ].
	options := OrderedDictionary new.
	[ (rawValue substrings: ',') do: [ :each |
		self strictJaegerRemoteSamplerOption: each trimBoth into: options ] ]
		on: Error
		do: [ ^ nil ].
	^ options
]

{ #category : 'private' }
OTTracerProvider class >> strictNonNegativeIntegerFrom: aString [

	| stream value |
	stream := aString trimBoth readStream.
	stream atEnd ifTrue: [ ^ nil ].
	value := [ Integer readFrom: stream ] on: Error do: [ ^ nil ].
	stream atEnd ifFalse: [ ^ nil ].
	value >= 0 ifFalse: [ ^ nil ].
	^ value
]

{ #category : 'private' }
OTTracerProvider class >> strictPositiveIntegerFrom: aString [

	| stream value |
	stream := aString trimBoth readStream.
	stream atEnd ifTrue: [ ^ nil ].
	value := [ Integer readFrom: stream ] on: Error do: [ ^ nil ].
	stream atEnd ifFalse: [ ^ nil ].
	value > 0 ifFalse: [ ^ nil ].
	^ value
]

{ #category : 'private' }
OTTracerProvider class >> strictProbabilityFrom: aString [

	| stream value |
	aString ifNil: [ ^ nil ].
	stream := aString trimBoth readStream.
	stream atEnd ifTrue: [ ^ nil ].
	value := [ Number readFrom: stream ] on: Error do: [ ^ nil ].
	stream atEnd ifFalse: [ ^ nil ].
	(value isNumber and: [ value >= 0 and: [ value <= 1 ] ]) ifFalse: [ ^ nil ].
	^ value
]

{ #category : 'instance creation' }
OTTracerProvider class >> systemAttributeAt: anInteger [

	| value |
	value := [ Smalltalk getSystemAttribute: anInteger ]
		on: Error
		do: [ nil ].
	value ifNil: [ ^ nil ].
	value := value asString trimBoth.
	^ value isEmpty ifTrue: [ nil ] ifFalse: [ value ]
]

{ #category : 'private - logging' }
OTTracerProvider class >> tracerConfigurationWarningSink [

	^ OTClassStateStore
		valueAt: #otTracerConfigurationWarningSink
		forClass: self
		ifAbsent: [ self defaultTracerConfigurationWarningSink ]
]

{ #category : 'private - logging' }
OTTracerProvider class >> tracerConfigurationWarningSink: aBlock [

	aBlock
		ifNil: [
			OTClassStateStore
				removeValueAt: #otTracerConfigurationWarningSink
				forClass: self
				ifAbsent: [  ] ]
		ifNotNil: [
			OTClassStateStore
				valueAt: #otTracerConfigurationWarningSink
				forClass: self
				put: aBlock ].
	^ self tracerConfigurationWarningSink
]

{ #category : 'private' }
OTTracerProvider class >> tracerConfiguratorByProvider [

	^ self stateDictionaryAt: #otTracerConfiguratorByProvider
]

{ #category : 'private - logging' }
OTTracerProvider class >> tracerNameWarningSink [

	^ OTClassStateStore
		valueAt: #otTracerNameWarningSink
		forClass: self
		ifAbsent: [ self defaultTracerNameWarningSink ]
]

{ #category : 'private - logging' }
OTTracerProvider class >> tracerNameWarningSink: aBlock [

	aBlock
		ifNil: [
			OTClassStateStore
				removeValueAt: #otTracerNameWarningSink
				forClass: self
				ifAbsent: [  ] ]
		ifNotNil: [
			OTClassStateStore
				valueAt: #otTracerNameWarningSink
				forClass: self
				put: aBlock ].
	^ self tracerNameWarningSink
]

{ #category : 'private' }
OTTracerProvider class >> updateJaegerRemoteSampler: aSampler withOptions: options [

	options at: 'endpoint' ifPresent: [ :value |
		aSampler endpoint: value ].
	options at: 'pollingIntervalMs' ifPresent: [ :value |
		aSampler pollingIntervalMillis: value ].
	options at: 'initialSamplingRate' ifPresent: [ :value |
		aSampler initialSampler: (OTSampler probabilityOrAlwaysOff: value) ]
]

{ #category : 'private' }
OTTracerProvider class >> writeShellQuotedCommandArgument: anObject on: aStream [

	| argument escapeCharacter needsQuoting quoteCharacter |
	argument := anObject asString.
	escapeCharacter := Character value: 92.
	quoteCharacter := Character value: 34.
	argument isEmpty ifTrue: [ ^ aStream nextPutAll: '""' ].
	needsQuoting := argument anySatisfy: [ :each |
		each isSeparator or: [ each = quoteCharacter or: [ each = escapeCharacter ] ] ].
	needsQuoting ifFalse: [ ^ aStream nextPutAll: argument ].
	aStream nextPut: quoteCharacter.
	argument do: [ :each |
		(each = quoteCharacter or: [ each = escapeCharacter ]) ifTrue: [ aStream nextPut: escapeCharacter ].
		aStream nextPut: each ].
	aStream nextPut: quoteCharacter
]

{ #category : 'accessing' }
OTTracerProvider >> addSpanProcessor: aSpanProcessor [

	stateLock critical: [
			self ensureOpenLocked.
			(self class spanProcessorsByProvider at: self ifAbsentPut: [ OrderedCollection new ]) add: aSpanProcessor ].
	^ aSpanProcessor
]

{ #category : 'private' }
OTTracerProvider >> asTwoDigitLowercaseHex: anInteger [

	^ String streamContents: [ :stream |
		stream
			nextPut: ('0123456789abcdef' at: ((anInteger bitShift: -4) bitAnd: 16rF) + 1);
			nextPut: ('0123456789abcdef' at: (anInteger bitAnd: 16rF) + 1) ]
]

{ #category : 'private - lifecycle' }
OTTracerProvider >> ensureOpen [

	stateLock critical: [ self ensureOpenLocked ].
	self
]

{ #category : 'private - lifecycle' }
OTTracerProvider >> ensureOpenLocked [

	(shutdownRequested = true or: [ shutdownCompleted = true ]) ifTrue: [ Error signal: 'This tracer provider has been shut down' ].
	self
]

{ #category : 'processing' }
OTTracerProvider >> forceFlush [

	| processors allFlushed stopping |
	processors := stateLock critical: [
			              stopping := shutdownRequested = true or: [ shutdownCompleted = true ].
			              (self class spanProcessorsByProvider at: self ifAbsent: [ OrderedCollection new ]) copy ].
	stopping ifTrue: [ ^ false ].
	processors isEmpty ifTrue: [ ^ true ].
	allFlushed := true.
	processors do: [ :each |
			allFlushed := (self
				               withSpanProcessor: each
				               operationNamed: 'forceFlush'
				               default: false
				               do: [ each forceFlush ]) & allFlushed ].
	^ allFlushed
]

{ #category : 'accessing' }
OTTracerProvider >> idGenerator [

	^ stateLock critical: [ self class idGeneratorByProvider at: self ifAbsentPut: [ self class defaultIdGenerator ] ]
]

{ #category : 'accessing' }
OTTracerProvider >> idGenerator: anIdGenerator [

	stateLock critical: [
			self ensureOpenLocked.
			self class idGeneratorByProvider
				at: self
				put: (anIdGenerator ifNil: [ self class defaultIdGenerator ] ifNotNil: [ anIdGenerator ]) ].
	^ self idGenerator
]

{ #category : 'initialization' }
OTTracerProvider >> initialize [

	super initialize.
	tracers := Dictionary new.
	stateLock := Semaphore forMutualExclusion.
	shutdownRequested := false.
	shutdownCompleted := false
]

{ #category : 'testing' }
OTTracerProvider >> isShutdown [

	^ stateLock critical: [ shutdownCompleted = true ]
]

{ #category : 'testing' }
OTTracerProvider >> isStopping [

	^ stateLock critical: [ shutdownRequested = true ]
]

{ #category : 'tracing' }
OTTracerProvider >> nonRecordingSpanContext: aSpanContext context: aContext parent: aSpan instrumentationScope: anInstrumentationScope [

	^ OTNonRecordingSpan
		spanContext: aSpanContext
		context: aContext
		parent: aSpan
		instrumentationScope: anInstrumentationScope
]

{ #category : 'tracing' }
OTTracerProvider >> nonRecordingSpanIn: aContext [

	^ self nonRecordingSpanIn: aContext instrumentationScope: (OTInstrumentationScope named: '')
]

{ #category : 'tracing' }
OTTracerProvider >> nonRecordingSpanIn: aContext instrumentationScope: anInstrumentationScope [

	| baseContext parentSpan span |
	baseContext := aContext ifNil: [ OTContext new ] ifNotNil: [ aContext ].
	parentSpan := baseContext span.
	parentSpan
		ifNotNil: [
				parentSpan isRecording ifFalse: [ ^ parentSpan ].
				span := OTSpan wrapping: parentSpan spanContext ]
		ifNil: [ span := OTSpan wrapping: OTSpanContext invalid ].
	span
		restoreContext: (baseContext withSpan: span);
		restoreInstrumentationScope: anInstrumentationScope;
		restoreResource: self resource.
	^ span
]

{ #category : 'tracing' }
OTTracerProvider >> nonRecordingSpanIn: aContext parent: aSpan traceId: aTraceId samplingResult: aSamplingResult instrumentationScope: anInstrumentationScope [

	| baseContext traceState spanContext span |
	baseContext := aContext ifNil: [ OTContext new ] ifNotNil: [ aContext ].
	traceState := aSamplingResult traceState ifNil: [ aSpan ifNotNil: [ aSpan spanContext traceState ] ].
	spanContext := OTSpanContext
		               traceId: aTraceId
		               spanId: self idGenerator generateSpanIdHex
		               traceFlags: (self traceFlagsForSamplingResult: aSamplingResult parentSpan: aSpan)
		               traceState: traceState
		               remote: false.
	span := self
		        nonRecordingSpanContext: spanContext
		        context: baseContext
		        parent: aSpan
		        instrumentationScope: anInstrumentationScope.
	span
		restoreContext: (baseContext withSpan: span);
		restoreResource: self resource.
	^ span
]

{ #category : 'processing' }
OTTracerProvider >> processEndedSpan: aSpan [

	| processors allProcessed |
	self isStopping ifTrue: [ ^ false ].
	processors := self spanProcessors.
	processors isEmpty ifTrue: [ ^ false ].
	allProcessed := true.
	processors do: [ :each |
			allProcessed := (self
				                 withSpanProcessor: each
				                 operationNamed: 'onEnd'
				                 default: false
				                 do: [ each onEnd: aSpan ]) & allProcessed ].
	^ allProcessed
]

{ #category : 'processing' }
OTTracerProvider >> processEndingSpan: aSpan [

	| processors allProcessed |
	self isStopping ifTrue: [ ^ false ].
	processors := self spanProcessors.
	processors isEmpty ifTrue: [ ^ false ].
	allProcessed := true.
	processors do: [ :each |
			allProcessed := (self
				                 withSpanProcessor: each
				                 operationNamed: 'onEnding'
				                 default: false
				                 do: [
						                 each onEnding: aSpan.
						                 true ]) & allProcessed ].
	^ allProcessed
]

{ #category : 'processing' }
OTTracerProvider >> processStartedSpan: aSpan parentContext: aContext [

	| processors allProcessed |
	self isStopping ifTrue: [ ^ false ].
	processors := self spanProcessors.
	processors isEmpty ifTrue: [ ^ false ].
	allProcessed := true.
	processors do: [ :each |
			allProcessed := (self
				                 withSpanProcessor: each
				                 operationNamed: 'onStart'
				                 default: false
				                 do: [
						                 each onStart: aSpan parentContext: aContext.
						                 true ]) & allProcessed ].
	^ allProcessed
]

{ #category : 'tracing' }
OTTracerProvider >> recordingSpanIn: aContext parent: aSpan instrumentationScope: anInstrumentationScope [

	| span |
	span := aSpan ifNil: [ OTSpan rootInInternal: aContext ] ifNotNil: [ OTSpan underInternal: aSpan ].
	span restoreInstrumentationScope: anInstrumentationScope.
	^ span
]

{ #category : 'accessing' }
OTTracerProvider >> resource [

	^ stateLock critical: [ self class resourceByProvider at: self ifAbsentPut: [ OTResource empty ] ]
]

{ #category : 'accessing' }
OTTracerProvider >> resource: anOTResource [

	stateLock critical: [
			self ensureOpenLocked.
			self class resourceByProvider at: self put: (anOTResource ifNil: [ OTResource empty ] ifNotNil: [ anOTResource ]) ].
	^ self resource
]

{ #category : 'accessing' }
OTTracerProvider >> sampler [

	^ stateLock critical: [ self class samplerByProvider at: self ifAbsentPut: [ self class defaultSampler ] ]
]

{ #category : 'accessing' }
OTTracerProvider >> sampler: anOTSampler [

	| effectiveSampler previousSampler |
	effectiveSampler := anOTSampler ifNil: [ self class defaultSampler ] ifNotNil: [ anOTSampler ].
	previousSampler := stateLock critical: [
			                   | previous |
			                   self ensureOpenLocked.
			                   previous := self class samplerByProvider at: self ifAbsent: [ nil ].
			                   previous == effectiveSampler ifFalse: [ self class samplerByProvider at: self put: effectiveSampler ].
			                   previous ].
	(previousSampler notNil and: [ previousSampler ~~ effectiveSampler ]) ifTrue: [ self shutdownSampler: previousSampler ].
	previousSampler == effectiveSampler ifFalse: [ self startSampler: effectiveSampler ].
	^ self sampler
]

{ #category : 'sampling' }
OTTracerProvider >> samplingResultIn: aContext traceId: aTraceId name: aString kind: aSpanKind attributes: someAttributes links: someLinks [

	^ self sampler
		shouldSampleIn: aContext
		traceId: aTraceId
		name: aString
		kind: aSpanKind
		attributes: someAttributes
		links: someLinks
]

{ #category : 'processing' }
OTTracerProvider >> shutdown [

	| allShutdown alreadyStopping processors sampler |
	processors := #(  ).
	sampler := nil.
	alreadyStopping := stateLock critical: [
			                   | stopping |
			                   stopping := shutdownRequested = true or: [ shutdownCompleted = true ].
			                   stopping ifFalse: [
					                   shutdownRequested := true.
					                   processors := (self class spanProcessorsByProvider at: self ifAbsent: [ OrderedCollection new ]) copy.
					                   sampler := self class samplerByProvider at: self ifAbsent: [ nil ] ].
			                   stopping ].
	alreadyStopping ifTrue: [ ^ false ].
	allShutdown := self shutdownSampler: sampler.
	processors do: [ :each |
			allShutdown := (self
				                withSpanProcessor: each
				                operationNamed: 'shutdown'
				                default: false
				                do: [ each shutdown ]) & allShutdown ].
	stateLock critical: [ shutdownCompleted := true ].
	^ allShutdown
]

{ #category : 'private - lifecycle' }
OTTracerProvider >> shutdownSampler: aSampler [

	aSampler ifNil: [ ^ true ].
	^ [ aSampler shutdown ]
		on: Error
		do: [ :error |
			self class noteSampler: aSampler failedDuring: 'shutdown' error: error.
			false ]
]

{ #category : 'accessing' }
OTTracerProvider >> spanLimits [

	^ stateLock critical: [ (self class spanLimitsByProvider at: self ifAbsentPut: [ OTSpanLimits default ]) copy ]
]

{ #category : 'accessing' }
OTTracerProvider >> spanLimits: anOTSpanLimits [

	stateLock critical: [
			self ensureOpenLocked.
			self class spanLimitsByProvider at: self put: (anOTSpanLimits ifNil: [ OTSpanLimits default ] ifNotNil: [ anOTSpanLimits ]) ].
	^ self spanLimits
]

{ #category : 'accessing' }
OTTracerProvider >> spanProcessor: aSpanProcessor [

	self spanProcessors: { aSpanProcessor }.
	^ aSpanProcessor
]

{ #category : 'accessing' }
OTTracerProvider >> spanProcessors [

	| processors |
	processors := stateLock critical: [ (self class spanProcessorsByProvider at: self ifAbsentPut: [ OrderedCollection new ]) copy ].
	^ processors
]

{ #category : 'accessing' }
OTTracerProvider >> spanProcessors: aCollection [

	stateLock critical: [
			self ensureOpenLocked.
			self class spanProcessorsByProvider
				at: self
				put: (aCollection ifNil: [ OrderedCollection new ] ifNotNil: [ aCollection asOrderedCollection ]) ].
	^ self spanProcessors
]

{ #category : 'private - lifecycle' }
OTTracerProvider >> startSampler: aSampler [

	aSampler ifNil: [ ^ true ].
	^ [ aSampler start.
		true ]
		on: Error
		do: [ :error |
			self class noteSampler: aSampler failedDuring: 'start' error: error.
			false ]
]

{ #category : 'sampling' }
OTTracerProvider >> traceFlagsForSamplingResult: aSamplingResult parentSpan: aSpan [

	| parentFlags |
	parentFlags := aSpan
		               ifNil: [
				               self idGenerator isRandom
					               ifTrue: [ 16r02 ]
					               ifFalse: [ 0 ] ]
		               ifNotNil: [ Integer readFrom: aSpan spanContext traceFlags readStream base: 16 ].
	parentFlags := (parentFlags bitAnd: 16rFE) bitOr: (aSamplingResult isRecordAndSample
			                ifTrue: [ 1 ]
			                ifFalse: [ 0 ]).
	^ self asTwoDigitLowercaseHex: parentFlags
]

{ #category : 'private' }
OTTracerProvider >> tracerConfigurationEnables: aTracer forSpanNamed: aString kind: aSpanKind inContext: aContext attributes: someAttributes links: someLinks [

	| configuredValue |
	self isStopping ifTrue: [ ^ false ].
	configuredValue := self
		                   tracerConfigurationValueFor: aTracer
		                   spanNamed: aString
		                   kind: aSpanKind
		                   inContext: aContext
		                   attributes: someAttributes
		                   links: someLinks.
	^ configuredValue ifNil: [ true ] ifNotNil: [ configuredValue ]
]

{ #category : 'private - error handling' }
OTTracerProvider >> tracerConfigurationValueFor: aTracer spanNamed: aString kind: aSpanKind inContext: aContext attributes: someAttributes links: someLinks [

	| arguments configuredValue |
	arguments := {
		aTracer instrumentationScope.
		aString.
		aSpanKind.
		aContext.
		someAttributes.
		someLinks }.
	configuredValue := self
		withTracerConfigurationDefault: nil
		operationNamed: 'enabled'
		do: [
			| configurator |
			configurator := self tracerConfigurator.
			configurator numArgs = 0
				ifTrue: [ configurator value ]
				ifFalse: [
					configurator valueWithArguments:
						(arguments copyFrom: 1 to: (configurator numArgs min: arguments size)) ] ].
	^ configuredValue
]

{ #category : 'accessing' }
OTTracerProvider >> tracerConfigurator [

	^ stateLock critical: [ self class tracerConfiguratorByProvider at: self ifAbsentPut: [ [ :scope | nil ] ] ]
]

{ #category : 'accessing' }
OTTracerProvider >> tracerConfigurator: aBlock [

	stateLock critical: [
			self ensureOpenLocked.
			self class tracerConfiguratorByProvider at: self put: (aBlock ifNil: [ [ :scope | nil ] ] ifNotNil: [ aBlock ]) ].
	^ self tracerConfigurator
]

{ #category : 'testing' }
OTTracerProvider >> tracerEnabled: aTracer [

	^ self
		tracerEnabled: aTracer
		forSpanNamed: nil
		kind: nil
		inContext: nil
		attributes: #()
		links: #()
]

{ #category : 'testing' }
OTTracerProvider >> tracerEnabled: aTracer forSpanNamed: aString kind: aSpanKind inContext: aContext attributes: someAttributes links: someLinks [

	(self
		 tracerConfigurationEnables: aTracer
		 forSpanNamed: aString
		 kind: aSpanKind
		 inContext: aContext
		 attributes: someAttributes
		 links: someLinks) ifFalse: [ ^ false ].
	^ self spanProcessors isNotEmpty
]

{ #category : 'tracing' }
OTTracerProvider >> tracerForInstrumentationScope: anInstrumentationScope [

	^ OTTracer
		forProvider: self
		instrumentationScope: anInstrumentationScope
]

{ #category : 'tracing' }
OTTracerProvider >> tracerNamed: aString [

	^ self tracerNamed: aString version: '' schemaUrl: '' attributes: #()
]

{ #category : 'tracing' }
OTTracerProvider >> tracerNamed: aString version: aVersionString schemaUrl: aSchemaUrlString attributes: aCollection [

	| scope |
	scope := OTInstrumentationScope
		         named: (self class normalizedTracerNameFrom: aString)
		         version: (aVersionString ifNil: [ '' ] ifNotNil: [ aVersionString asString ])
		         schemaUrl: (aSchemaUrlString ifNil: [ '' ] ifNotNil: [ aSchemaUrlString asString ])
		         attributes: aCollection.
	^ stateLock critical: [
			  (shutdownRequested = true or: [ shutdownCompleted = true ])
				  ifTrue: [ OTNoopTracer forProvider: self instrumentationScope: scope ]
				  ifFalse: [ tracers at: scope ifAbsentPut: [ self tracerForInstrumentationScope: scope ] ] ]
]

{ #category : 'private - error handling' }
OTTracerProvider >> withSpanProcessor: aProcessor operationNamed: anOperationName default: aDefaultValue do: aBlock [

	^ [ aBlock value ]
		on: Error
		do: [ :error |
			self class noteSpanProcessor: aProcessor failedDuring: anOperationName error: error.
			aDefaultValue ]
]

{ #category : 'private - error handling' }
OTTracerProvider >> withTracerConfigurationDefault: aDefaultValue operationNamed: anOperationName do: aBlock [

	^ [ aBlock value ]
		on: Error
		do: [ :error |
			self class noteTracerConfigurationFailedDuring: anOperationName error: error.
			aDefaultValue ]
]

{ #category : 'tracing' }
OTTracerProvider >> wrapSpanContext: aSpanContext [

	^ OTSpan wrapping: aSpanContext
]
