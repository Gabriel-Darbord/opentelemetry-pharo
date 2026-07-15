Class {
	#name : 'OTDiagnosticLoggerTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'running' }
OTDiagnosticLoggerTest >> tearDown [

	[
		OTDiagnosticLogger reset ]
		ensure: [ super tearDown ]
]

{ #category : 'tests' }
OTDiagnosticLoggerTest >> testExporterDefaultWarningSinkUsesCurrentDiagnosticLogger [

	| warnings |
	warnings := OrderedCollection new.
	OTDiagnosticLogger current:
		(OTDiagnosticLogger onWarningDo: [ :message | warnings add: message ]).

	OTSpanExporter defaultWarningSink value: 'exporter warning'.

	self
		assert: warnings asArray
		equals: #( 'exporter warning' )
]

{ #category : 'tests' }
OTDiagnosticLoggerTest >> testInstrumentationDefaultWarningSinkUsesCurrentDiagnosticLogger [

	| warnings |
	warnings := OrderedCollection new.
	OTDiagnosticLogger current:
		(OTDiagnosticLogger onWarningDo: [ :message | warnings add: message ]).

	OTTracerProvider defaultSamplerConfigurationWarningSink value: 'sampler warning'.
	OTSpan defaultLimitWarningSink value: 'limit warning'.

	self
		assert: warnings asArray
		equals: #( 'sampler warning' 'limit warning' )
]
