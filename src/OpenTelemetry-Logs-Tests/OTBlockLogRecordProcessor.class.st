Class {
	#name : 'OTBlockLogRecordProcessor',
	#superclass : 'OTLogRecordProcessor',
	#instVars : [
		'onEmitBlock',
		'enabledBlock',
		'forceFlushBlock',
		'shutdownBlock'
	],
	#category : 'OpenTelemetry-Logs-Tests',
	#package : 'OpenTelemetry-Logs-Tests'
}

{ #category : 'accessing' }
OTBlockLogRecordProcessor >> enabledBlock: aBlock [

	enabledBlock := aBlock
]

{ #category : 'testing' }
OTBlockLogRecordProcessor >> enabledIn: anOTContext instrumentationScope: anInstrumentationScope severityNumber: aSeverityNumber eventName: aString [

	^ enabledBlock ifNil: [ true ] ifNotNil: [
			  enabledBlock
				  value: anOTContext
				  value: anInstrumentationScope
				  value: aSeverityNumber
				  value: aString ]
]

{ #category : 'processing' }
OTBlockLogRecordProcessor >> forceFlush [

	^ forceFlushBlock ifNil: [ true ] ifNotNil: [ forceFlushBlock value ]
]

{ #category : 'accessing' }
OTBlockLogRecordProcessor >> forceFlushBlock: aBlock [

	forceFlushBlock := aBlock
]

{ #category : 'processing' }
OTBlockLogRecordProcessor >> onEmit: anOTLogRecord context: anOTContext [

	onEmitBlock ifNotNil: [ onEmitBlock value: anOTLogRecord value: anOTContext ].
	self
]

{ #category : 'accessing' }
OTBlockLogRecordProcessor >> onEmitBlock: aBlock [

	onEmitBlock := aBlock
]

{ #category : 'processing' }
OTBlockLogRecordProcessor >> shutdown [

	^ shutdownBlock ifNil: [ true ] ifNotNil: [ shutdownBlock value ]
]

{ #category : 'accessing' }
OTBlockLogRecordProcessor >> shutdownBlock: aBlock [

	shutdownBlock := aBlock
]
