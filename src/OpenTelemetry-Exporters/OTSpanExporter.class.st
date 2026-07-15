"
I am a fundamental component within the OpenTelemetry framework that facilitates the export of recorded spans to external systems or backends.
Developers can implement custom subclasses to integrate OpenTelemetry with specific telemetry data consumers, enabling compatibility with various third-party systems.
"
Class {
	#name : 'OTSpanExporter',
	#superclass : 'Object',
	#classVars : [
		'Current'
	],
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'instance creation' }
OTSpanExporter class >> beCurrent [

	<script>
	self isAbstract
		ifTrue: [ Error signal: self name , ' is abstract' ]
		ifFalse: [
			^ self == Current class
				  ifTrue: [ Current ]
				  ifFalse: [ Current := self new ] ]
]

{ #category : 'accessing' }
OTSpanExporter class >> current [

	^ Current ifNil: [ Current := self readConfiguration ]
]

{ #category : 'accessing' }
OTSpanExporter class >> current: aSpanExporter [

	Current := aSpanExporter
]

{ #category : 'instance creation' }
OTSpanExporter class >> configuredExporters [

	| configuredValue exporters |
	configuredValue := self environmentValueAt: 'OTEL_TRACES_EXPORTER'.
	configuredValue ifNil: [ ^ { self defaultExporter } ].
	exporters := self exportersFromConfigurationValue: configuredValue.
	^ exporters ifEmpty: [ { self defaultExporter } ] ifNotEmpty: [ exporters ]
]

{ #category : 'instance creation' }
OTSpanExporter class >> defaultExporter [

	^ self configuredOtlpExporter ifNil: [ self defaultFileExporter ]
]

{ #category : 'instance creation' }
OTSpanExporter class >> defaultFileExporter [

	^ OTJSONFileSpanExporter new
]

{ #category : 'private - logging' }
OTSpanExporter class >> defaultWarningSink [

	^ OTDiagnosticLogger defaultWarningSink
]

{ #category : 'instance creation' }
OTSpanExporter class >> defaultZipkinEndpoint [

	^ 'http://localhost:9411/api/v2/spans'
]

{ #category : 'instance creation' }
OTSpanExporter class >> defaultZipkinTimeoutMillis [

	^ 10000
]

{ #category : 'instance creation' }
OTSpanExporter class >> defaultZipkinExporter [

	| exporter |
	exporter := OTZipkinSpanExporter new.
	exporter httpClient url: self defaultZipkinEndpoint.
	^ exporter
]

{ #category : 'private' }
OTSpanExporter class >> environmentValueAt: aString [

	| value |
	value := Smalltalk os environment at: aString ifAbsent: [ ^ nil ].
	value := value asString trimBoth.
	^ value isEmpty ifTrue: [ nil ] ifFalse: [ value ]
]

{ #category : 'instance creation' }
OTSpanExporter class >> exporterFromEnvironmentName: aString [

	| exporterName |
	exporterName := aString asLowercase.
	exporterName = 'console' ifTrue: [ ^ OTConsoleSpanExporter new ].
	exporterName = 'logging' ifTrue: [ ^ OTConsoleSpanExporter new ].
	exporterName = 'none' ifTrue: [ ^ OTNoopSpanExporter new ].
	exporterName = 'otlp' ifTrue: [ ^ self configuredOtlpExporter ].
	exporterName = 'otlp/stdout' ifTrue: [ ^ OTOtlpStdoutSpanExporter new ].
	exporterName = 'zipkin' ifTrue: [ ^ self configuredZipkinExporter ].
	aString ifNotEmpty: [ self noteUnknownTraceExporterName: aString ].
	^ nil
]

{ #category : 'instance creation' }
OTSpanExporter class >> exporterNamesFromConfigurationValue: aString [

	| names seen |
	names := OrderedCollection new.
	seen := Set new.
	(aString substrings: ',') do: [ :each |
		| exporterName normalizedName |
		exporterName := each trimBoth.
		exporterName ifNotEmpty: [
			normalizedName := exporterName asLowercase.
			(seen includes: normalizedName) ifFalse: [
				seen add: normalizedName.
				names add: exporterName ] ] ].
	^ names asArray
]

{ #category : 'instance creation' }
OTSpanExporter class >> exportersFromConfigurationValue: aString [

	| exporterNames exporters |
	exporterNames := self exporterNamesFromConfigurationValue: aString.
	(exporterNames size > 1 and: [
		 exporterNames anySatisfy: [ :each | each asLowercase = 'none' ] ]) ifTrue: [
		self noteTraceExporterNoneConflictIn: aString.
		^ #() ].
	exporters := OrderedCollection new.
	exporterNames do: [ :each |
		| exporter |
		exporter := self exporterFromEnvironmentName: each.
		exporter ifNotNil: [
			exporter class == OTNoopSpanExporter ifTrue: [ ^ { exporter } ].
			exporters add: exporter ] ].
	^ exporters asArray
]

{ #category : 'exporting' }
OTSpanExporter class >> forceFlush [

	<script>
	^ Current ifNil: [ false ] ifNotNil: [ Current forceFlush ]
]

{ #category : 'testing' }
OTSpanExporter class >> isAbstract [

	^ self == OTSpanExporter
]

{ #category : 'private - lifecycle' }
OTSpanExporter class >> isShutdown: anExporter [

	^ (self lifecycleStateByExporter at: anExporter ifAbsent: [ false ]) = true
]

{ #category : 'private - lifecycle' }
OTSpanExporter class >> lifecycleStateByExporter [

	^ OTClassStateStore
		valueAt: #otLifecycleStateByExporter
		forClass: self
		ifAbsent: [
			| states |
			states := WeakIdentityKeyDictionary new.
			OTClassStateStore
				valueAt: #otLifecycleStateByExporter
				forClass: self
				put: states.
			states ]
]

{ #category : 'private - lifecycle' }
OTSpanExporter class >> markShutdown: anExporter [

	self lifecycleStateByExporter at: anExporter put: true.
	^ anExporter
]

{ #category : 'private' }
OTSpanExporter class >> positiveIntegerEnvironmentValueAt: aString default: aDefaultValue [

	| rawValue parsed |
	rawValue := self environmentValueAt: aString.
	rawValue ifNil: [ ^ aDefaultValue ].
	parsed := self strictPositiveIntegerFrom: rawValue.
	^ parsed ifNil: [ aDefaultValue ] ifNotNil: [ parsed ]
]

{ #category : 'instance creation' }
OTSpanExporter class >> configuredZipkinExporter [

	| endpoint exporter timeout |
	exporter := self defaultZipkinExporter.
	endpoint := self environmentValueAt: 'OTEL_EXPORTER_ZIPKIN_ENDPOINT'.
	endpoint ifNotNil: [ exporter httpClient url: endpoint ].
	timeout := self
		positiveIntegerEnvironmentValueAt: 'OTEL_EXPORTER_ZIPKIN_TIMEOUT'
		default: self defaultZipkinTimeoutMillis.
	exporter httpClient timeout: timeout.
	^ exporter
]

{ #category : 'instance creation' }
OTSpanExporter class >> configuredOtlpExporter [

	| configuration |
	configuration := OTOtlpExporterConfiguration forSignalNamed: 'TRACES'.
	configuration protocol = OTOtlpGrpcSpanExporter supportedProtocol
		ifTrue: [ ^ OTOtlpGrpcSpanExporter configuration: configuration ].
	configuration protocol = OTOtlpHttpProtobufSpanExporter supportedProtocol
		ifTrue: [ ^ OTOtlpHttpProtobufSpanExporter configuration: configuration ].
	configuration protocol = OTOtlpHttpJsonSpanExporter supportedProtocol
		ifTrue: [ ^ OTOtlpHttpJsonSpanExporter configuration: configuration ].
	self noteUnsupportedOtlpProtocol: configuration protocol.
	configuration protocol: OTOtlpExporterConfiguration defaultProtocol.
	^ OTOtlpHttpProtobufSpanExporter configuration: configuration
]

{ #category : 'instance creation' }
OTSpanExporter class >> readConfiguration [

	| exporters |
	exporters := self configuredExporters.
	^ exporters size = 1
		ifTrue: [ exporters first ]
		ifFalse: [ OTCompositeSpanExporter withAll: exporters ]
]

{ #category : 'class initialization' }
OTSpanExporter class >> reset [

	<script>
	self shutdown.
	self resetLifecycleState.
	Current := nil
]

{ #category : 'private - lifecycle' }
OTSpanExporter class >> resetLifecycleState [

	OTClassStateStore
		removeValueAt: #otLifecycleStateByExporter
		forClass: self
		ifAbsent: [  ]
]

{ #category : 'exporting' }
OTSpanExporter class >> shutdown [

	<script>
	^ Current ifNil: [ false ] ifNotNil: [ Current shutdown ]
]

{ #category : 'private' }
OTSpanExporter class >> strictPositiveIntegerFrom: aString [

	| stream value |
	stream := aString trimBoth readStream.
	stream atEnd ifTrue: [ ^ nil ].
	value := [ Integer readFrom: stream ] on: Error do: [ ^ nil ].
	stream atEnd ifFalse: [ ^ nil ].
	value > 0 ifFalse: [ ^ nil ].
	^ value
]

{ #category : 'private - logging' }
OTSpanExporter class >> noteTraceExporterNoneConflictIn: aString [

	self warningSink value:
		'OpenTelemetry trace exporter configuration mixes ''none'' with other exporters and has been ignored: '
			, aString printString
]

{ #category : 'private - logging' }
OTSpanExporter class >> noteUnknownTraceExporterName: aString [

	self warningSink value:
		'OpenTelemetry trace exporter name was unrecognized and has been ignored: '
			, aString printString
]

{ #category : 'private - logging' }
OTSpanExporter class >> noteUnsupportedOtlpProtocol: aString [

	self warningSink value:
		'OpenTelemetry OTLP traces exporter protocol is recognized but not supported by this SDK yet: '
			, aString printString
]

{ #category : 'private - logging' }
OTSpanExporter class >> warningSink [

	^ OTClassStateStore
		valueAt: #otWarningSink
		forClass: self
		ifAbsent: [ self defaultWarningSink ]
]

{ #category : 'private - logging' }
OTSpanExporter class >> warningSink: aBlock [

	aBlock
		ifNil: [
			OTClassStateStore
				removeValueAt: #otWarningSink
				forClass: self
				ifAbsent: [  ] ]
		ifNotNil: [
			OTClassStateStore
				valueAt: #otWarningSink
				forClass: self
				put: aBlock ].
	^ self warningSink
]

{ #category : 'accessing' }
OTSpanExporter >> beCurrent [

	^ Current := self
]

{ #category : 'accessing' }
OTSpanExporter >> componentExporters [

	^ { self }
]

{ #category : 'exporting' }
OTSpanExporter >> export: spans [

	self subclassResponsibility
]

{ #category : 'exporting' }
OTSpanExporter >> forceFlush [

	^ self isShutdown not
]

{ #category : 'testing' }
OTSpanExporter >> isShutdown [

	^ self class isShutdown: self
]

{ #category : 'private - lifecycle' }
OTSpanExporter >> markShutdown [

	self class markShutdown: self.
	^ self
]

{ #category : 'exporting' }
OTSpanExporter >> shutdown [

	self isShutdown ifTrue: [ ^ false ].
	self markShutdown.
	^ true
]
