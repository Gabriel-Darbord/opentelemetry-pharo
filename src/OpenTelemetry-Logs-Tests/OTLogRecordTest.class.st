Class {
	#name : 'OTLogRecordTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Logs-Tests',
	#package : 'OpenTelemetry-Logs-Tests'
}

{ #category : 'tests' }
OTLogRecordTest >> testAttributeLimitsDropAndWarnOnce [

	| limits logRecord warnings |
	limits := OTLogRecordLimits default.
	limits attributeCountLimit: 1.
	warnings := OrderedCollection new.
	logRecord := OTLogRecord new
		             limits: limits;
		             warningSink: [ :message | warnings add: message ];
		             yourself.
	logRecord
		attributeNamed: 'first' put: 1;
		attributeNamed: 'second' put: 2;
		attributeNamed: 'third' put: 3.
	self assert: logRecord attributes size equals: 1.
	self assert: logRecord droppedAttributesCount equals: 2.
	self assert: warnings size equals: 1
]

{ #category : 'tests' }
OTLogRecordTest >> testBodyIsNotTruncatedByAttributeValueLengthLimit [

	| limits logRecord |
	limits := OTLogRecordLimits default.
	limits attributeValueLengthLimit: 3.
	logRecord := OTLogRecord new
		             limits: limits;
		             yourself.
	logRecord
		body: 'abcdef';
		attributeNamed: 'shortened' put: 'abcdef'.
	self assert: logRecord body equals: 'abcdef'.
	self assert: (logRecord attributeNamed: 'shortened') equals: 'abc'
]

{ #category : 'tests' }
OTLogRecordTest >> testSeverityShortNameMapping [

	self assert: (OTSeverity shortNameFor: OTSeverity trace) equals: 'TRACE'.
	self assert: (OTSeverity shortNameFor: (OTSeverity info: 3)) equals: 'INFO3'.
	self assert: (OTSeverity shortNameFor: OTSeverity fatal) equals: 'FATAL'
]
