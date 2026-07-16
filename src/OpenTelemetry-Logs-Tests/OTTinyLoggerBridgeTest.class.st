Class {
	#name : 'OTTinyLoggerBridgeTest',
	#superclass : 'TestCase',
	#instVars : [
		'provider',
		'exporter',
		'processor'
	],
	#category : 'OpenTelemetry-Logs-Tests',
	#package : 'OpenTelemetry-Logs-Tests'
}

{ #category : 'running' }
OTTinyLoggerBridgeTest >> setUp [

	super setUp.
	provider := OTLoggerProvider new.
	exporter := OTRecordingLogRecordExporter new.
	processor := OTSimpleLogRecordProcessor new exporter: exporter; yourself.
	provider addLogRecordProcessor: processor.
	OpenTelemetry loggerProvider: provider
]

{ #category : 'running' }
OTTinyLoggerBridgeTest >> tearDown [

	[ OpenTelemetry loggerProvider: nil.
		provider ifNotNil: [ provider shutdown ] ]
		ensure: [ super tearDown ]
]

{ #category : 'tests' }
OTTinyLoggerBridgeTest >> testAsTinyLoggerBridgeIntegratesWithTinyLogger [

	| logger tinyLogger |
	logger := provider loggerNamed: 'spec.logs'.
	tinyLogger := TinyLogger new.
	tinyLogger addLogger: logger asTinyLoggerBridge.
	tinyLogger record: 'hello from tiny logger'.
	self assert: exporter exportedRecords size equals: 1.
	self assert: exporter exportedRecords first body equals: 'hello from tiny logger'.
	self assert: exporter exportedRecords first severityNumber equals: OTSeverity info.
	self assert: exporter exportedRecords first severityText equals: 'INFO'
]

{ #category : 'tests' }
OTTinyLoggerBridgeTest >> testBridgeCanCustomizeSeverityBodyAttributesAndEventName [

	| bridge logger |
	logger := provider loggerNamed: 'spec.logs'.
	bridge := OTTinyLoggerBridge forLogger: logger.
	bridge
		severityNumber: OTSeverity warn;
		bodyBlock: [ :message | 'tiny:' , message ];
		attributesBlock: [ :message | { 'tiny.logger' -> true. 'tiny.message' -> message } ];
		eventNameBlock: [ :message | 'tiny.record' ].
	self assert: (bridge record: 'warn me').
	self assert: exporter exportedRecords size equals: 1.
	self assert: exporter exportedRecords first body equals: 'tiny:warn me'.
	self assert: exporter exportedRecords first severityNumber equals: OTSeverity warn.
	self assert: exporter exportedRecords first severityText equals: 'WARN'.
	self assert: exporter exportedRecords first eventName equals: 'tiny.record'.
	self assert: (exporter exportedRecords first attributeNamed: 'tiny.logger') equals: true.
	self assert: (exporter exportedRecords first attributeNamed: 'tiny.message') equals: 'warn me'
]
