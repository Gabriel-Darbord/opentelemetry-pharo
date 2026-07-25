Class {
	#name : 'OTFileSpanExporterTest',
	#superclass : 'TestCase',
	#instVars : [
		'outputDirectory'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'private' }
OTFileSpanExporterTest >> sampleSpan [

	^ OTOtlpProtobufTraceEncoderTest new sampleSpan
]

{ #category : 'running' }
OTFileSpanExporterTest >> setUp [

	super setUp.
	outputDirectory := FileLocator temp / ('ot-file-exporter-' , UUID new asString36).
	outputDirectory ensureCreateDirectory
]

{ #category : 'running' }
OTFileSpanExporterTest >> tearDown [

	[ outputDirectory ifNotNil: [ outputDirectory ensureDeleteAll ] ] ensure: [ super tearDown ]
]

{ #category : 'tests' }
OTFileSpanExporterTest >> testJsonFileExporterWritesReadableSpanFields [

	| exporter payload record |
	exporter := OTJSONFileSpanExporter new directory: outputDirectory.
	self assert: (exporter export: { self sampleSpan }).
	payload := STONJSON fromString: outputDirectory children anyOne contents.
	record := payload first.
	self assert: (record at: 'droppedAttributesCount') equals: 2.
	self assert: (record at: 'droppedEventsCount') equals: 3.
	self assert: (record at: 'droppedLinksCount') equals: 4.
	self assert: ((record at: 'parentSpanContext') at: 'traceId') equals: '12345678876543211234567887654321'.
	self assert: ((record at: 'parentSpanContext') at: 'spanId') equals: 'bbbbbbbbbbbbbbbb'.
	self assert: ((record at: 'parentSpanContext') at: 'remote').
	self assert: ((record at: 'instrumentationScope') at: 'name') equals: 'demo.scope'.
	self assert: ((record at: 'instrumentationScope') at: 'version') equals: '1.2.3'.
	self assert: ((record at: 'instrumentationScope') at: 'schemaUrl') equals: 'https://scope.example/schema'.
	self assert: (((record at: 'instrumentationScope') at: 'attributes') at: 'scope.attr').
	self assert: ((record at: 'resource') at: 'schemaUrl') equals: 'https://resource.example/schema'.
	self assert: (((record at: 'resource') at: 'attributes') at: 'service.name') equals: 'demo-service'
]

{ #category : 'tests' }
OTFileSpanExporterTest >> testJsonFileExporterWritesSpanIdentityFields [

	| contents exporter |
	exporter := OTJSONFileSpanExporter new directory: outputDirectory.
	self assert: (exporter export: { self sampleSpan }).
	contents := outputDirectory children anyOne contents.
	self assert: (contents includesSubstring: '12345678876543211234567887654321').
	self assert: (contents includesSubstring: '8765432112345678').
	self assert: (contents includesSubstring: 'operation')
]

{ #category : 'tests' }
OTFileSpanExporterTest >> testStonFileExporterWritesReadableSpanFields [

	| exporter payload record |
	exporter := OTSTONFileSpanExporter new directory: outputDirectory.
	self assert: (exporter export: { self sampleSpan }).
	payload := STON fromString: outputDirectory children anyOne contents.
	record := payload first.
	self assert: (record at: #droppedAttributesCount) equals: 2.
	self assert: (record at: #droppedEventsCount) equals: 3.
	self assert: (record at: #droppedLinksCount) equals: 4.
	self assert: (record at: #parentSpanContext) traceId equals: '12345678876543211234567887654321'.
	self assert: (record at: #parentSpanContext) spanId equals: 'bbbbbbbbbbbbbbbb'.
	self assert: (record at: #parentSpanContext) isRemote.
	self assert: (record at: #instrumentationScope) name equals: 'demo.scope'.
	self assert: (record at: #instrumentationScope) version equals: '1.2.3'.
	self assert: (record at: #instrumentationScope) schemaUrl equals: 'https://scope.example/schema'.
	self assert: ((record at: #instrumentationScope) attributeAt: 'scope.attr') equals: true.
	self assert: (record at: #resource) schemaUrl equals: 'https://resource.example/schema'.
	self assert: ((record at: #resource) attributeAt: 'service.name') equals: 'demo-service'
]
