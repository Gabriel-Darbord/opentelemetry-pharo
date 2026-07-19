Class {
	#name : 'OTBeaconSignalLoggerTest',
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
OTBeaconSignalLoggerTest >> setUp [

	super setUp.
	provider := OTLoggerProvider new.
	exporter := OTRecordingLogRecordExporter new.
	processor := OTSimpleLogRecordProcessor new
		             exporter: exporter;
		             yourself.
	provider addLogRecordProcessor: processor.
	OpenTelemetry loggerProvider: provider
]

{ #category : 'running' }
OTBeaconSignalLoggerTest >> tearDown [

	[
		OpenTelemetry loggerProvider: nil.
		provider ifNotNil: [ provider shutdown ] ] ensure: [ super tearDown ]
]

{ #category : 'tests' }
OTBeaconSignalLoggerTest >> testAsBeaconSignalLoggerIntegratesWithBeacon [

	| bridge logger record |
	logger := provider loggerNamed: 'spec.logs'.
	bridge := logger asBeaconSignalLogger.
	bridge runFor: StringSignal during: [ StringSignal emit: 'hello from beacon' ].
	self assert: exporter exportedRecords size equals: 1.
	record := exporter exportedRecords first.
	self assert: record body equals: 'hello from beacon'.
	self assert: record severityNumber equals: OTSeverity info.
	self assert: record severityText equals: 'INFO'.
	self assert: record eventName equals: 'StringSignal'.
	self assert: (record attributeNamed: 'beacon.signal.name') equals: 'StringSignal'.
	self assert: (record attributeNamed: 'beacon.signal.class') equals: 'StringSignal'.
	self assert: (record attributeNamed: 'beacon.signal.process_id') notNil
]

{ #category : 'tests' }
OTBeaconSignalLoggerTest >> testBridgeCanCustomizeSeverityBodyAttributesAndEventName [

	| bridge logger record |
	logger := provider loggerNamed: 'spec.logs'.
	bridge := logger asBeaconSignalLogger.
	bridge
		severityNumber: OTSeverity warn;
		bodyBlock: [ :aSignal | aSignal target asUppercase ];
		attributesBlock: [ :aSignal |
				{
					('beacon.signal.message' -> aSignal target).
					('beacon.signal.source' -> 'beacon') } ];
		eventNameBlock: [ :aSignal | 'beacon.record' ].
	bridge runFor: StringSignal during: [ StringSignal emit: 'warn me' ].
	self assert: exporter exportedRecords size equals: 1.
	record := exporter exportedRecords first.
	self assert: record body equals: 'WARN ME'.
	self assert: record severityNumber equals: OTSeverity warn.
	self assert: record severityText equals: 'WARN'.
	self assert: record eventName equals: 'beacon.record'.
	self assert: (record attributeNamed: 'beacon.signal.message') equals: 'warn me'.
	self assert: (record attributeNamed: 'beacon.signal.source') equals: 'beacon'
]

{ #category : 'tests' }
OTBeaconSignalLoggerTest >> testBridgeFlattensAndStringifiesSignalProperties [

	| bridge logger payload record signal |
	logger := provider loggerNamed: 'spec.logs'.
	bridge := logger asBeaconSignalLogger.
	payload := Object new.
	signal := StringSignal new.
	signal
		message: 'with properties';
		yourself.
	signal properties
		at: #tenant put: 'acme';
		at: #attempt put: 3;
		at: #payload put: payload.
	bridge runFor: StringSignal during: [ Beacon announce: signal ].
	self assert: exporter exportedRecords size equals: 1.
	record := exporter exportedRecords first.
	self assert: (record attributeNamed: 'beacon.signal.properties.tenant') equals: 'acme'.
	self assert: (record attributeNamed: 'beacon.signal.properties.attempt') equals: 3.
	self assert: (record attributeNamed: 'beacon.signal.properties.payload') equals: payload printString
]
