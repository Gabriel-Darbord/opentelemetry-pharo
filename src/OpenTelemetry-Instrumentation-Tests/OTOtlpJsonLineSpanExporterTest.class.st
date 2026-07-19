Class {
	#name : 'OTOtlpJsonLineSpanExporterTest',
	#superclass : 'TestCase',
	#instVars : [
		'exporter',
		'outputFile'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'private' }
OTOtlpJsonLineSpanExporterTest >> sampleSpan [

	| provider span tracer |
	provider := OTTracerProvider new.
	provider
		spanProcessor: OTSimpleSpanProcessor new;
		idGenerator: (OTFixedIdGenerator traceIdHex: '12345678876543211234567887654321' spanIdHex: '8765432112345678' random: false).
	tracer := provider tracerNamed: 'exporter.test'.
	span := ((tracer spanBuilderNamed: 'operation')
		        kind: OTSpan internal;
		        startTimestamp: DateAndTime unixEpoch + (Duration milliSeconds: 1);
		        startSpan).
	span
		attributes: (Dictionary new
				 at: 'service.name' put: 'demo';
				 yourself);
		events: #(  );
		links: #(  );
		end: DateAndTime unixEpoch + (Duration milliSeconds: 2).
	^ span
]

{ #category : 'running' }
OTOtlpJsonLineSpanExporterTest >> setUp [

	super setUp.
	exporter := OTRecordingOtlpJsonLineSpanExporter new.
	outputFile := FileLocator temp / ('otlp-json-lines-', UUID new asString36, '.jsonl')
]

{ #category : 'running' }
OTOtlpJsonLineSpanExporterTest >> tearDown [

	[ outputFile ifNotNil: [ outputFile ensureDelete ] ]
		ensure: [ super tearDown ]
]

{ #category : 'tests' }
OTOtlpJsonLineSpanExporterTest >> testEnvironmentConfigurationSupportsOtlpStdoutExporterSelection [

	| processor |
	OTSpanExporter current: nil.
	OTSpanProcessor current: nil.
	[
		Smalltalk os environment
			at: 'OTEL_TRACES_EXPORTER' put: 'otlp/stdout'.
		self assert: OTSpanExporter current class identicalTo: OTOtlpStdoutSpanExporter.
		processor := OTSpanProcessor current.
		self assert: processor class identicalTo: OTBatchSpanProcessor ]
		ensure: [
			(Smalltalk os environment includesKey: 'OTEL_TRACES_EXPORTER') ifTrue: [
				Smalltalk os environment removeKey: 'OTEL_TRACES_EXPORTER' ].
			OTSpanExporter current: nil.
			OTSpanProcessor current: nil ]
]

{ #category : 'tests' }
OTOtlpJsonLineSpanExporterTest >> testFileExporterAppendsOneJsonLinePerExport [

	| fileExporter lines |
	fileExporter := OTOtlpJsonFileSpanExporter new.
	fileExporter fileReference: outputFile.
	self assert: (fileExporter export: { self sampleSpan }).
	self assert: (fileExporter export: { self sampleSpan }).
	lines := outputFile contents lines.
	self assert: lines size equals: 2.
	self assert: ((STONJSON fromString: lines first) at: 'resourceSpans') size equals: 1
]

{ #category : 'tests' }
OTOtlpJsonLineSpanExporterTest >> testJsonLineExporterWritesOneValidJsonLinePerExport [

	| line payload |
	self assert: (exporter export: { self sampleSpan }).
	self assert: exporter writtenLines size equals: 1.
	line := exporter writtenLines first.
	self assert: line last equals: Character lf.
	payload := STONJSON fromString: line allButLast.
	self assert: (payload at: 'resourceSpans') size equals: 1
]
