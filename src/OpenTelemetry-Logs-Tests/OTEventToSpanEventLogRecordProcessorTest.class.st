Class {
	#name : 'OTEventToSpanEventLogRecordProcessorTest',
	#superclass : 'TestCase',
	#instVars : [
		'loggerProvider',
		'exporter',
		'bridgeProcessor',
		'tracerProvider',
		'tracer'
	],
	#category : 'OpenTelemetry-Logs-Tests',
	#package : 'OpenTelemetry-Logs-Tests'
}

{ #category : 'running' }
OTEventToSpanEventLogRecordProcessorTest >> setUp [

	super setUp.
	bridgeProcessor := OTEventToSpanEventLogRecordProcessor new.
	exporter := OTRecordingLogRecordExporter new.
	loggerProvider := OTLoggerProvider new.
	loggerProvider
		addLogRecordProcessor: bridgeProcessor;
		addLogRecordProcessor: (OTSimpleLogRecordProcessor new
				 exporter: exporter;
				 yourself).
	tracerProvider := OTTracerProvider new.
	tracerProvider spanProcessor: (OTSimpleSpanProcessor new
			 exporter: OTNoopSpanExporter new;
			 yourself).
	tracer := tracerProvider tracerNamed: 'spec.logs.bridge'.
	OpenTelemetry resetCurrentContext
]

{ #category : 'running' }
OTEventToSpanEventLogRecordProcessorTest >> tearDown [

	[
		OpenTelemetry resetCurrentContext.
		loggerProvider ifNotNil: [ loggerProvider shutdown ].
		tracerProvider ifNotNil: [ tracerProvider shutdown ] ] ensure: [ super tearDown ]
]

{ #category : 'tests' }
OTEventToSpanEventLogRecordProcessorTest >> testBridgeAddsSpanEventAndKeepsLogRecordInPipeline [

	| event logger span timestamp |
	logger := loggerProvider loggerNamed: 'spec.logs'.
	span := tracer startSpanNamed: 'operation'.
	timestamp := DateAndTime unixEpoch + (Duration milliSeconds: 7).
	OpenTelemetry useSpan: span during: [
			self assert: (logger
					 emitTimestamp: timestamp
					 observedTimestamp: nil
					 in: nil
					 severityNumber: OTSeverity info
					 severityText: 'INFO'
					 body: 'hello'
					 attributes: { ('count' -> 3) }
					 eventName: 'cache.miss'
					 exception: nil) ].
	self assert: exporter exportedRecords size equals: 1.
	self assert: span events size equals: 1.
	event := span events first.
	self assert: event name equals: 'cache.miss'.
	self assert: event timestamp equals: timestamp.
	self assert: (event attributeAt: 'count') equals: 3
]

{ #category : 'tests' }
OTEventToSpanEventLogRecordProcessorTest >> testBridgeDoesNothingWhenContextSpanDoesNotMatchLogRecord [

	| explicitContext logRecord processorSpan recordedSpan recordedSpanContext |
	recordedSpan := tracer startSpanNamed: 'recorded'.
	processorSpan := tracer startSpanNamed: 'processor'.
	recordedSpanContext := OTContext new withSpan: recordedSpan.
	logRecord := OTLogRecord new.
	logRecord
		eventName: 'mismatch';
		context: recordedSpanContext;
		observedTimestamp: DateAndTime unixEpoch + (Duration milliSeconds: 3);
		attributes: { ('key' -> 'value') }.
	explicitContext := OTContext new withSpan: processorSpan.
	bridgeProcessor onEmit: logRecord context: explicitContext.
	self assert: processorSpan events isEmpty.
	self assert: recordedSpan events isEmpty.
	self assert: exporter exportedRecords isEmpty
]

{ #category : 'tests' }
OTEventToSpanEventLogRecordProcessorTest >> testBridgeDoesNothingWithInvalidTraceContext [

	| explicitContext logRecord span |
	span := tracer startSpanNamed: 'processor'.
	logRecord := OTLogRecord new.
	logRecord
		eventName: 'mismatch';
		traceId: OTSpanContext invalidTraceId;
		spanId: OTSpanContext invalidSpanId;
		observedTimestamp: DateAndTime unixEpoch + (Duration milliSeconds: 3);
		attributes: { ('key' -> 'value') }.
	explicitContext := OTContext new withSpan: span.
	bridgeProcessor onEmit: logRecord context: explicitContext.
	self assert: span events isEmpty.
	self assert: exporter exportedRecords isEmpty
]

{ #category : 'tests' }
OTEventToSpanEventLogRecordProcessorTest >> testBridgeDoesNothingWithoutEventName [

	| logger span |
	logger := loggerProvider loggerNamed: 'spec.logs'.
	span := tracer startSpanNamed: 'operation'.
	OpenTelemetry useSpan: span during: [
			self assert: (logger
					 emitTimestamp: nil
					 observedTimestamp: nil
					 in: nil
					 severityNumber: OTSeverity info
					 severityText: 'INFO'
					 body: 'hello'
					 attributes: #(  )
					 eventName: nil
					 exception: nil) ].
	self assert: span events isEmpty
]

{ #category : 'tests' }
OTEventToSpanEventLogRecordProcessorTest >> testBridgeSkipsNonRecordingCurrentSpan [

	| explicitContext logRecord span |
	span := (tracer startSpanNamed: 'processor') spanContext asNonRecordingSpan.
	logRecord := OTLogRecord new.
	logRecord
		eventName: 'mismatch';
		context: (OTContext new withSpan: span);
		observedTimestamp: DateAndTime unixEpoch + (Duration milliSeconds: 3);
		attributes: { ('key' -> 'value') }.
	explicitContext := OTContext new withSpan: span.
	bridgeProcessor onEmit: logRecord context: explicitContext.
	self assert: span events isEmpty.
	self assert: exporter exportedRecords isEmpty
]

{ #category : 'tests' }
OTEventToSpanEventLogRecordProcessorTest >> testBridgeUsesObservedTimestampWhenTimestampIsMissing [

	| event logger observedTimestamp span |
	logger := loggerProvider loggerNamed: 'spec.logs'.
	span := tracer startSpanNamed: 'operation'.
	observedTimestamp := DateAndTime unixEpoch + (Duration milliSeconds: 9).
	OpenTelemetry useSpan: span during: [
			self assert: (logger
					 emitTimestamp: nil
					 observedTimestamp: observedTimestamp
					 in: nil
					 severityNumber: OTSeverity info
					 severityText: 'INFO'
					 body: 'hello'
					 attributes: #(  )
					 eventName: 'tick'
					 exception: nil) ].
	event := span events first.
	self assert: event timestamp equals: observedTimestamp
]
