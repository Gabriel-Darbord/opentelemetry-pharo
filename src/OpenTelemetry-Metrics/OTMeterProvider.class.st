"
A backend-agnostic entry point to the metrics API.
"
Class {
	#name : 'OTMeterProvider',
	#superclass : 'Object',
	#instVars : [
		'meters',
		'shutdown',
		'meterConfigurator',
		'resource',
		'measurements',
		'metricReaders',
		'views',
		'exemplarFilter'
	],
	#classVars : [
		'Current'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'private' }
OTMeterProvider class >> configurationSourceClass [

	^ self environment at: #OTConfigurationSource ifAbsent: [ nil ]
]

{ #category : 'private - logging' }
OTMeterProvider class >> configurationWarningSink [

	^ OTClassStateStore valueAt: #otMetricConfigurationWarningSink forClass: self ifAbsent: [ self defaultConfigurationWarningSink ]
]

{ #category : 'private - logging' }
OTMeterProvider class >> configurationWarningSink: aBlock [

	OTClassStateStore
		valueAt: #otMetricConfigurationWarningSink
		forClass: self
		putOrRemoveIfNil: aBlock.
	^ self configurationWarningSink
]

{ #category : 'private - configuration' }
OTMeterProvider class >> configuredExemplarFilter [

	| rawValue |
	rawValue := self environmentValueAt: 'OTEL_METRICS_EXEMPLAR_FILTER'.
	rawValue ifNil: [ ^ OTMetricExemplarFilter traceBased ].
	(rawValue sameAs: 'always_on') ifTrue: [ ^ OTMetricExemplarFilter alwaysOn ].
	(rawValue sameAs: 'always_off') ifTrue: [ ^ OTMetricExemplarFilter alwaysOff ].
	(rawValue sameAs: 'trace_based') ifTrue: [ ^ OTMetricExemplarFilter traceBased ].
	self noteInvalidExemplarFilterName: rawValue.
	^ OTMetricExemplarFilter traceBased
]

{ #category : 'private - configuration' }
OTMeterProvider class >> configuredExporterNames [

	| rawValue |
	rawValue := self environmentValueAt: 'OTEL_METRICS_EXPORTER'.
	rawValue ifNil: [ ^ #( 'otlp' ) ].
	^ (self exporterNamesFromConfigurationValue: rawValue) ifNil: [ #( 'otlp' ) ] ifNotNil: [ :names | names ]
]

{ #category : 'private - configuration' }
OTMeterProvider class >> configuredOtlpExporter [

	| configuration |
	configuration := OTOtlpExporterConfiguration forSignalNamed: 'METRICS'.
	configuration protocol = OTOtlpGrpcMetricExporter supportedProtocol ifTrue: [
		^ OTOtlpGrpcMetricExporter configuration: configuration ].
	configuration protocol = OTOtlpHttpJsonMetricExporter supportedProtocol ifTrue: [
		^ OTOtlpHttpJsonMetricExporter configuration: configuration ].
	configuration protocol = OTOtlpHttpProtobufMetricExporter supportedProtocol ifTrue: [
		^ OTOtlpHttpProtobufMetricExporter configuration: configuration ].
	self noteUnsupportedOtlpProtocol: configuration protocol.
	^ OTOtlpHttpProtobufMetricExporter configuration: configuration
]

{ #category : 'private - configuration' }
OTMeterProvider class >> configuredPrometheusReader [

	^ OTPrometheusMetricReader new
		  host: self prometheusHost;
		  port: self prometheusPort;
		  yourself
]

{ #category : 'accessing' }
OTMeterProvider class >> current [

	^ OTClassStateStore currentValueForClass: self ifAbsentPut: [ self readConfiguration ]
]

{ #category : 'accessing' }
OTMeterProvider class >> current: anOTMeterProvider [

	OTClassStateStore
		valueAt: #otCurrent
		forClass: self
		putOrRemoveIfNil: anOTMeterProvider
]

{ #category : 'accessing' }
OTMeterProvider class >> currentOrNil [

	^ OTClassStateStore currentValueForClass: self ifAbsent: [ nil ]
]

{ #category : 'private - logging' }
OTMeterProvider class >> defaultConfigurationWarningSink [

	^ OTDiagnosticLogger defaultWarningSink
]

{ #category : 'private - logging' }
OTMeterProvider class >> defaultMeterNameWarningSink [

	^ OTDiagnosticLogger defaultWarningSink
]

{ #category : 'private' }
OTMeterProvider class >> environmentValueAt: aString [

	| configurationSourceClass |
	configurationSourceClass := self configurationSourceClass.
	^ configurationSourceClass ifNotNil: [ configurationSourceClass environmentValueAt: aString ]
]

{ #category : 'private - configuration' }
OTMeterProvider class >> exporterNamed: aString [

	aString = 'console' ifTrue: [ ^ OTConsoleMetricExporter new ].
	aString = 'logging' ifTrue: [ ^ OTConsoleMetricExporter new ].
	aString = 'none' ifTrue: [ ^ OTNoopMetricExporter new ].
	aString = 'otlp' ifTrue: [ ^ self configuredOtlpExporter ].
	aString = 'otlp/stdout' ifTrue: [ ^ OTOtlpStdoutMetricExporter new ].
	self noteUnknownExporterName: aString.
	^ nil
]

{ #category : 'private - configuration' }
OTMeterProvider class >> exporterNamesFromConfigurationValue: aString [

	| names seen |
	names := OrderedCollection new.
	seen := Set new.
	(aString substrings: ',') do: [ :each |
			| exporterName normalizedName |
			exporterName := each trimBoth.
			exporterName isEmpty ifFalse: [
					normalizedName := exporterName asLowercase.
					(seen includes: normalizedName) ifFalse: [
							(#( 'otlp' 'prometheus' 'otlp/stdout' 'console' 'logging' 'none' ) includes: normalizedName) ifFalse: [
									self noteUnknownExporterName: exporterName.
									^ nil ].
							seen add: normalizedName.
							names add: normalizedName ] ] ].
	names isEmpty ifTrue: [ ^ nil ].
	((names includes: 'none') and: [ names size > 1 ]) ifTrue: [
			self noteExporterNoneConflictIn: aString.
			^ nil ].
	^ names asArray
]

{ #category : 'private' }
OTMeterProvider class >> meterNameWarningSink [

	^ OTClassStateStore valueAt: #otMeterNameWarningSink forClass: self ifAbsent: [ self defaultMeterNameWarningSink ]
]

{ #category : 'private' }
OTMeterProvider class >> meterNameWarningSink: aBlock [

	OTClassStateStore
		valueAt: #otMeterNameWarningSink
		forClass: self
		putOrRemoveIfNil: aBlock.
	^ self meterNameWarningSink
]

{ #category : 'private - configuration' }
OTMeterProvider class >> metricExportIntervalDefaultForExporter: anExporter [

	anExporter class = OTConsoleMetricExporter ifTrue: [ ^ 10000 ].
	^ OTPeriodicExportingMetricReader new exportIntervalMillis
]

{ #category : 'private - configuration' }
OTMeterProvider class >> metricExportIntervalMillisForExporter: anExporter [

	^ self
		  positiveIntegerEnvironmentValueAt: 'OTEL_METRIC_EXPORT_INTERVAL'
		  default: (self metricExportIntervalDefaultForExporter: anExporter)
]

{ #category : 'private - configuration' }
OTMeterProvider class >> metricExportTimeoutMillis [

	^ self
		  positiveIntegerEnvironmentValueAt: 'OTEL_METRIC_EXPORT_TIMEOUT'
		  default: OTPeriodicExportingMetricReader new exportTimeoutMillis
]

{ #category : 'private' }
OTMeterProvider class >> nonNegativeIntegerEnvironmentValueAt: aString default: aDefaultValue [

	| parsed rawValue stream |
	rawValue := self environmentValueAt: aString.
	rawValue ifNil: [ ^ aDefaultValue ].
	stream := rawValue trimBoth readStream.
	stream atEnd ifTrue: [
			self noteInvalidPrometheusEnvironmentValue: rawValue forVariable: aString.
			^ aDefaultValue ].
	parsed := [ Integer readFrom: stream ]
		          on: Error
		          do: [ nil ].
	((parsed isInteger and: [ parsed >= 0 ]) and: [ stream atEnd ]) ifTrue: [ ^ parsed ].
	self noteInvalidPrometheusEnvironmentValue: rawValue forVariable: aString.
	^ aDefaultValue
]

{ #category : 'private' }
OTMeterProvider class >> normalizedMeterNameFrom: aValue [

	| meterName |
	aValue ifNil: [
			self noteInvalidMeterName: aValue.
			^ '' ].
	meterName := aValue asString.
	meterName trimBoth isEmpty ifTrue: [
			self noteInvalidMeterName: aValue.
			^ '' ].
	^ meterName
]

{ #category : 'private - logging' }
OTMeterProvider class >> noteExporterNoneConflictIn: aString [

	self configurationWarningSink value:
		'OpenTelemetry metrics exporter configuration mixes ''none'' with other exporters and has been ignored: ' , aString printString
]

{ #category : 'private - logging' }
OTMeterProvider class >> noteInvalidExemplarFilterName: aString [

	self configurationWarningSink value:
		'OpenTelemetry metrics exemplar filter was invalid and defaulted to trace_based: ' , aString printString
]

{ #category : 'private - logging' }
OTMeterProvider class >> noteInvalidMeterName: aValue [

	self meterNameWarningSink value: 'OpenTelemetry meter name was invalid and has been normalized to an empty string: '
		, (aValue ifNil: [ 'nil' ] ifNotNil: [ aValue printString ])
]

{ #category : 'private - logging' }
OTMeterProvider class >> noteInvalidPeriodicMetricReaderEnvironmentValue: aValue forVariable: aString [

	self configurationWarningSink value:
		'OpenTelemetry periodic metric reader configuration was invalid and has been ignored for ' , aString printString , ': '
		, aValue printString
]

{ #category : 'private - logging' }
OTMeterProvider class >> noteInvalidPrometheusEnvironmentValue: aValue forVariable: aString [

	self configurationWarningSink value:
		'OpenTelemetry Prometheus exporter configuration was invalid and has been ignored for ' , aString printString , ': '
		, aValue printString
]

{ #category : 'private - logging' }
OTMeterProvider class >> noteUnknownExporterName: aString [

	self configurationWarningSink value:
		'OpenTelemetry metrics exporter name was unrecognized and has been ignored: ' , aString printString
]

{ #category : 'private - logging' }
OTMeterProvider class >> noteUnsupportedExporterName: aString [

	self configurationWarningSink value:
		'OpenTelemetry metrics exporter name is recognized but not supported by this SDK yet and has been ignored: '
		, aString printString
]

{ #category : 'private - logging' }
OTMeterProvider class >> noteUnsupportedOtlpProtocol: aString [

	self configurationWarningSink value:
		'OpenTelemetry OTLP metrics exporter protocol was unsupported and defaulted to http/protobuf: ' , aString printString
]

{ #category : 'private' }
OTMeterProvider class >> positiveIntegerEnvironmentValueAt: aString default: aDefaultValue [

	| rawValue parsed |
	rawValue := self environmentValueAt: aString.
	rawValue ifNil: [ ^ aDefaultValue ].
	parsed := self strictPositiveIntegerFrom: rawValue.
	parsed ifNil: [
			self noteInvalidPeriodicMetricReaderEnvironmentValue: rawValue forVariable: aString.
			^ aDefaultValue ].
	^ parsed
]

{ #category : 'private - configuration' }
OTMeterProvider class >> prometheusHost [

	| rawValue |
	rawValue := self environmentValueAt: 'OTEL_EXPORTER_PROMETHEUS_HOST'.
	^ rawValue ifNil: [ 'localhost' ] ifNotNil: [ rawValue ]
]

{ #category : 'private - configuration' }
OTMeterProvider class >> prometheusPort [

	^ self nonNegativeIntegerEnvironmentValueAt: 'OTEL_EXPORTER_PROMETHEUS_PORT' default: 9464
]

{ #category : 'instance creation' }
OTMeterProvider class >> readConfiguration [

	| configurationSourceClass exporterNames provider readers views |
	provider := self new.
	configurationSourceClass := self configurationSourceClass.
	provider
		resource: OTTracerProvider configuredResource;
		exemplarFilter: self configuredExemplarFilter;
		meterConfigurator: (configurationSourceClass ifNotNil: [ configurationSourceClass configuredMeterConfigurator ]).
	views := configurationSourceClass ifNotNil: [ configurationSourceClass configuredMetricViews ] ifNil: [ #(  ) ].
	views do: [ :each | provider addView: each ].
	OTTracerProvider sdkDisabled ifTrue: [ ^ provider ].
	readers := configurationSourceClass ifNotNil: [ configurationSourceClass configuredMetricReaders ].
	readers ifNotNil: [
			readers do: [ :each | provider addMetricReader: each ].
			^ provider ].
	exporterNames := self configuredExporterNames.
	exporterNames do: [ :each |
			each = 'prometheus'
				ifTrue: [ provider addMetricReader: self configuredPrometheusReader ]
				ifFalse: [
						| exporter |
						exporter := self exporterNamed: each.
						exporter ifNotNil: [
							exporter class = OTNoopMetricExporter ifFalse: [ provider addMetricReader: (self readerForExporter: exporter) ] ] ] ].
	^ provider
]

{ #category : 'private - configuration' }
OTMeterProvider class >> readerForExporter: anExporter [

	| reader |
	reader := OTPeriodicExportingMetricReader exporter: anExporter.
	reader
		exportIntervalMillis: (self metricExportIntervalMillisForExporter: anExporter);
		exportTimeoutMillis: self metricExportTimeoutMillis.
	^ reader
]

{ #category : 'class initialization' }
OTMeterProvider class >> reset [

	| configurationSourceClass |
	self currentOrNil ifNotNil: [ :provider | provider shutdown ].
	configurationSourceClass := self configurationSourceClass.
	configurationSourceClass ifNotNil: [ configurationSourceClass reset ].
	OTClassStateStore removeCurrentValueForClass: self ifAbsent: [ ]
]

{ #category : 'private' }
OTMeterProvider class >> strictPositiveIntegerFrom: aString [

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

{ #category : 'accessing' }
OTMeterProvider >> addMetricReader: anOTMetricReader [

	anOTMetricReader ifNil: [ ^ self metricReaders ].
	anOTMetricReader attachToProvider: self.
	anOTMetricReader didRegisterWithProvider.
	self metricReaders add: anOTMetricReader.
	^ self metricReaders
]

{ #category : 'configuration' }
OTMeterProvider >> addView: anOTMetricView [

	anOTMetricView ifNil: [ ^ self views ].
	self views add: anOTMetricView.
	^ self views
]

{ #category : 'collecting' }
OTMeterProvider >> collectMeasurementsFor: anOTMetricReader [

	| collected |
	collected := self measurements copy.
	self meters valuesDo: [ :each | each collectMeasurementsFor: anOTMetricReader into: collected ].
	^ collected
]

{ #category : 'accessing' }
OTMeterProvider >> exemplarFilter [

	^ exemplarFilter ifNil: [ exemplarFilter := OTMetricExemplarFilter traceBased ]
]

{ #category : 'accessing' }
OTMeterProvider >> exemplarFilter: anOTMetricExemplarFilter [

	exemplarFilter := anOTMetricExemplarFilter ifNil: [ OTMetricExemplarFilter traceBased ] ifNotNil: [ anOTMetricExemplarFilter ].
	^ self exemplarFilter
]

{ #category : 'lifecycle' }
OTMeterProvider >> forceFlush [

	^ self metricReaders allSatisfy: [ :each | each forceFlush ]
]

{ #category : 'initialization' }
OTMeterProvider >> initialize [

	super initialize.
	meters := OrderedDictionary new.
	measurements := OrderedCollection new.
	metricReaders := OrderedCollection new.
	views := OrderedCollection new.
	exemplarFilter := OTMetricExemplarFilter traceBased.
	shutdown := false.
	meterConfigurator := nil.
	resource := OTResource empty
]

{ #category : 'testing' }
OTMeterProvider >> isShutdown [

	^ shutdown
]

{ #category : 'configuration' }
OTMeterProvider >> matchingViewsFor: anOTMetricInstrument [

	^ self views select: [ :each | each matchesInstrument: anOTMetricInstrument ]
]

{ #category : 'recording' }
OTMeterProvider >> measurementFor: anOTMetricInstrument value: aNumber attributes: aCollection [

	| measurement spanContext traceId spanId |
	measurement := OTMetricMeasurement instrument: anOTMetricInstrument value: aNumber attributes: aCollection.
	self exemplarFilter capturesMeasurements ifFalse: [ ^ measurement ].
	spanContext := OpenTelemetry currentSpan spanContext.
	spanContext isValid ifFalse: [ spanContext := nil ].
	traceId := spanContext ifNotNil: [ spanContext traceId ].
	spanId := spanContext ifNotNil: [ spanContext spanId ].
	measurement
		exemplarEligible: (self exemplarFilter isMeasurementEligibleWithSpanContext: spanContext);
		exemplarTraceId: traceId;
		exemplarSpanId: spanId.
	^ measurement
]

{ #category : 'accessing' }
OTMeterProvider >> measurements [

	^ measurements ifNil: [ measurements := OrderedCollection new ]
]

{ #category : 'configuration' }
OTMeterProvider >> meterConfigFor: anOTInstrumentationScope [

	| configured |
	meterConfigurator ifNil: [ ^ OTMeterConfig default ].
	configured := meterConfigurator value: anOTInstrumentationScope.
	configured ifNil: [ ^ OTMeterConfig default ].
	configured class = OTMeterConfig ifTrue: [ ^ configured copy ].
	(configured == true or: [ configured == false ]) ifTrue: [ ^ OTMeterConfig enabled: configured ].
	^ OTMeterConfig default
]

{ #category : 'configuration' }
OTMeterProvider >> meterConfigurator [

	^ meterConfigurator
]

{ #category : 'configuration' }
OTMeterProvider >> meterConfigurator: aBlockOrNil [

	meterConfigurator := aBlockOrNil
]

{ #category : 'accessing' }
OTMeterProvider >> meterNamed: aString [

	^ self
		  meterNamed: aString
		  version: ''
		  schemaUrl: ''
		  attributes: #(  )
]

{ #category : 'accessing' }
OTMeterProvider >> meterNamed: aString version: aVersionString schemaUrl: aSchemaUrlString attributes: aCollection [

	| scope |
	scope := OTInstrumentationScope
		         named: (self class normalizedMeterNameFrom: aString)
		         version: (aVersionString ifNil: [ '' ] ifNotNil: [ aVersionString asString ])
		         schemaUrl: (aSchemaUrlString ifNil: [ '' ] ifNotNil: [ aSchemaUrlString asString ])
		         attributes: aCollection.
	self isShutdown ifTrue: [ ^ OTMeter forProvider: nil instrumentationScope: scope ].
	^ self meters at: scope ifAbsentPut: [ OTMeter forProvider: self instrumentationScope: scope ]
]

{ #category : 'accessing' }
OTMeterProvider >> meters [

	^ meters ifNil: [ meters := OrderedDictionary new ]
]

{ #category : 'accessing' }
OTMeterProvider >> metricReaders [

	^ metricReaders ifNil: [ metricReaders := OrderedCollection new ]
]

{ #category : 'recording' }
OTMeterProvider >> recordMeasurementFor: anOTMetricInstrument value: aNumber attributes: aCollection [

	anOTMetricInstrument enabled ifFalse: [ ^ false ].
	self measurements add: (self measurementFor: anOTMetricInstrument value: aNumber attributes: aCollection).
	^ true
]

{ #category : 'accessing' }
OTMeterProvider >> registeredMetricInstruments [

	| instruments |
	instruments := OrderedCollection new.
	self meters valuesDo: [ :each | instruments addAll: each registeredMetricInstruments ].
	^ instruments asArray
]

{ #category : 'accessing' }
OTMeterProvider >> resource [

	^ resource ifNil: [ OTResource empty ]
]

{ #category : 'accessing' }
OTMeterProvider >> resource: anOTResource [

	resource := anOTResource ifNil: [ OTResource empty ] ifNotNil: [ anOTResource ].
	^ self resource
]

{ #category : 'lifecycle' }
OTMeterProvider >> shutdown [

	self metricReaders do: [ :each | each shutdown ].
	shutdown := true.
	^ true
]

{ #category : 'accessing' }
OTMeterProvider >> views [

	^ views ifNil: [ views := OrderedCollection new ]
]
