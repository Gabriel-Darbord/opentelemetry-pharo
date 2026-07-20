Class {
	#name : 'OTInstrumenterTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'running' }
OTInstrumenterTest >> setUp [

	super setUp.
	OTTracerProvider current: nil.
	OTSpanProcessor current: nil.
	OTSpanExporter current: nil.
	OTInstrumenter configurationWarningSink: nil.
	OTTracerProvider tracerConfigurationWarningSink: nil.
	OTSpan reset
]

{ #category : 'running' }
OTInstrumenterTest >> tearDown [

	[
		OTDiagnosticLogger reset.
		OTTracerProvider current: nil.
		OTSpanProcessor current: nil.
		OTSpanExporter current: nil.
		OTInstrumenter configurationWarningSink: nil.
		OTTracerProvider tracerConfigurationWarningSink: nil.
		OTSpan reset ]
		ensure: [ super tearDown ]
]

{ #category : 'tests' }
OTInstrumenterTest >> testCurrentContextFailureInvokesDiagnosticErrorHandler [

	| handled instrumenter provider span |
	handled := OrderedCollection new.
	OTDiagnosticLogger current: (OTDiagnosticLogger new
		errorHandler: [ :error :message | handled add: { error messageText. message } ];
		yourself).
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	instrumenter := OTInstrumenter forInstrumentationNamed: 'demo.scope'.
	instrumenter
		tracerProvider: provider;
		contextProducer: [ Error signal: 'boom' ].
	span := instrumenter startRequest: 'request'.
	self assert: span parent isNil.
	self
		assert: handled asArray
		equals: {
			{ 'boom'. 'OpenTelemetry instrumenter callback failed during contextProducer: boom' } }
]

{ #category : 'tests' }
OTInstrumenterTest >> testCurrentContextFallsBackToEmptyContextWhenContextProducerFails [

	self
		withInstrumenterWarningsDo: [ :warnings |
			| instrumenter provider span |
			provider := OTTracerProvider new.
			provider spanProcessor: OTSimpleSpanProcessor new.
			instrumenter := OTInstrumenter forInstrumentationNamed: 'demo.scope'.
			instrumenter
				tracerProvider: provider;
				contextProducer: [ Error signal: 'boom' ].
			span := instrumenter startRequest: 'request'.
			self assert: span parent isNil.
			self assert: warnings asArray equals:
				{ 'OpenTelemetry instrumenter callback failed during contextProducer: boom' } ]
]

{ #category : 'tests' }
OTInstrumenterTest >> testShouldStartUnderFallsBackToTrueWhenSuppressionStrategyFails [

	self
		withInstrumenterWarningsDo: [ :warnings |
			| instrumenter provider |
			provider := OTTracerProvider new.
			provider spanProcessor: OTSimpleSpanProcessor new.
			instrumenter := OTInstrumenter forInstrumentationNamed: 'demo.scope'.
			instrumenter
				tracerProvider: provider;
				spanSuppressionStrategy: [ :span :kind | Error signal: 'boom' ].
			self assert: (instrumenter shouldStartUnder: nil request: 'request').
			self assert: warnings asArray equals:
				{ 'OpenTelemetry instrumenter callback failed during spanSuppressionStrategy: boom' } ]
]

{ #category : 'tests' }
OTInstrumenterTest >> testShouldStartUnderUsesTracerEnablementForDerivedSpanName [

	| instrumenter provider |
	provider := OTTracerProvider new.
	provider spanProcessor: OTSimpleSpanProcessor new.
	provider tracerConfigurator: [ :scope :spanName :kind :context :attributes :links |
		spanName = 'blocked' ifTrue: [ false ] ifFalse: [ nil ] ].
	instrumenter := OTInstrumenter forInstrumentationNamed: 'demo.scope'.
	instrumenter
		tracerProvider: provider;
		spanNameExtractor: [ :request | request ].
	self deny: (instrumenter shouldStartUnder: nil request: 'blocked').
	self assert: (instrumenter shouldStartUnder: nil request: 'allowed')
]

{ #category : 'tests' }
OTInstrumenterTest >> testStartInFallsBackToDefaultSpanKindWhenExtractorFails [

	self withInstrumenterWarningsDo: [ :warnings |
			| exportRecord instrumenter provider span |
			provider := OTTracerProvider new.
			provider spanProcessor: OTSimpleSpanProcessor new.
			instrumenter := OTInstrumenter forInstrumentationNamed: 'demo.scope'.
			instrumenter
				tracerProvider: provider;
				spanKindExtractor: [ :request | Error signal: 'boom' ].
			span := instrumenter startRequest: 'request'.
			exportRecord := span asExportRecord.
			self assert: (exportRecord at: #kind) equals: OTSpan internal.
			self assert: warnings asArray equals: { 'OpenTelemetry instrumenter callback failed during spanKindExtractor: boom' } ]
]

{ #category : 'tests' }
OTInstrumenterTest >> testStartInFallsBackToDefaultSpanNameWhenExtractorFails [

	self withInstrumenterWarningsDo: [ :warnings |
			| exportRecord instrumenter provider span |
			provider := OTTracerProvider new.
			provider spanProcessor: OTSimpleSpanProcessor new.
			instrumenter := OTInstrumenter forInstrumentationNamed: 'demo.scope'.
			instrumenter
				tracerProvider: provider;
				spanNameExtractor: [ :request | Error signal: 'boom' ].
			span := instrumenter startRequest: 'request'.
			exportRecord := span asExportRecord.
			self assert: (exportRecord at: #name) equals: (OTInstrumenter defaultSpanNameExtractor value: 'request').
			self assert: warnings asArray equals: { 'OpenTelemetry instrumenter callback failed during spanNameExtractor: boom' } ]
]

{ #category : 'private' }
OTInstrumenterTest >> withInstrumenterWarningsDo: aBlock [

	| warnings |
	warnings := OrderedCollection new.
	OTInstrumenter configurationWarningSink: [ :message | warnings add: message ].
	[
		^ aBlock value: warnings ]
		ensure: [ OTInstrumenter configurationWarningSink: nil ]
]
