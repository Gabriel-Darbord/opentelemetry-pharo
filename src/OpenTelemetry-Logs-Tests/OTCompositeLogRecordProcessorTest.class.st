Class {
	#name : 'OTCompositeLogRecordProcessorTest',
	#superclass : 'TestCase',
	#instVars : [
		'composite',
		'firstProcessor',
		'secondProcessor'
	],
	#category : 'OpenTelemetry-Logs-Tests',
	#package : 'OpenTelemetry-Logs-Tests'
}

{ #category : 'private' }
OTCompositeLogRecordProcessorTest >> sampleLogRecord [

	^ OTLogRecord new
		  body: 'hello';
		  yourself
]

{ #category : 'running' }
OTCompositeLogRecordProcessorTest >> setUp [

	super setUp.
	firstProcessor := OTBlockLogRecordProcessor new.
	secondProcessor := OTBlockLogRecordProcessor new.
	composite := OTCompositeLogRecordProcessor withAll: {
			             firstProcessor.
			             secondProcessor }
]

{ #category : 'tests' }
OTCompositeLogRecordProcessorTest >> testAddProcessorAfterShutdownDoesNotChangeProcessorSet [

	| lateProcessor |
	self assert: composite shutdown.
	lateProcessor := OTBlockLogRecordProcessor new.
	composite addProcessor: lateProcessor.
	self assert: composite componentProcessors size equals: 2
]

{ #category : 'tests' }
OTCompositeLogRecordProcessorTest >> testOnEmitForwardsToProcessorsInOrderBeforeShutdown [

	| events |
	events := OrderedCollection new.
	firstProcessor onEmitBlock: [ :logRecord :context | events add: #first ].
	secondProcessor onEmitBlock: [ :logRecord :context | events add: #second ].
	composite onEmit: self sampleLogRecord context: OTContext new.
	self assert: events asArray equals: #( first second )
]

{ #category : 'tests' }
OTCompositeLogRecordProcessorTest >> testShutdownFlushesAndShutsDownEachProcessorOnce [

	| firstFlushes firstShutdowns secondFlushes secondShutdowns |
	firstFlushes := 0.
	firstShutdowns := 0.
	secondFlushes := 0.
	secondShutdowns := 0.
	firstProcessor
		forceFlushBlock: [
				firstFlushes := firstFlushes + 1.
				true ];
		shutdownBlock: [
				firstShutdowns := firstShutdowns + 1.
				true ].
	secondProcessor
		forceFlushBlock: [
				secondFlushes := secondFlushes + 1.
				true ];
		shutdownBlock: [
				secondShutdowns := secondShutdowns + 1.
				true ].
	self assert: composite shutdown.
	self assert: firstFlushes equals: 1.
	self assert: secondFlushes equals: 1.
	self assert: firstShutdowns equals: 1.
	self assert: secondShutdowns equals: 1.
	self deny: composite shutdown
]

{ #category : 'tests' }
OTCompositeLogRecordProcessorTest >> testShutdownMakesEnabledReturnFalseAndIgnoresFurtherOnEmit [

	| events |
	events := OrderedCollection new.
	firstProcessor onEmitBlock: [ :logRecord :context | events add: #first ].
	self assert: composite shutdown.
	self deny: (composite
			 enabledIn: OTContext new
			 instrumentationScope: (OTInstrumentationScope named: 'spec.logs')
			 severityNumber: OTSeverity info
			 eventName: nil).
	composite onEmit: self sampleLogRecord context: OTContext new.
	self assert: events isEmpty.
	self deny: composite forceFlush.
	self deny: composite shutdown
]
