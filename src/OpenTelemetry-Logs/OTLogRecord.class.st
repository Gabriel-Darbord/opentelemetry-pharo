"
A mutable readable/writeable OpenTelemetry log record.
"
Class {
	#name : 'OTLogRecord',
	#superclass : 'Object',
	#instVars : [
		'timestamp',
		'observedTimestamp',
		'severityText',
		'severityNumber',
		'body',
		'attributes',
		'droppedAttributesCount',
		'eventName',
		'traceId',
		'spanId',
		'traceFlags',
		'resource',
		'instrumentationScope',
		'limits',
		'warningSink',
		'warnedAboutDiscardedData'
	],
	#category : 'OpenTelemetry-Logs',
	#package : 'OpenTelemetry-Logs'
}

{ #category : 'private' }
OTLogRecord >> attributeCountWithinLimit: aLimit currentSize: aCurrentSize [

	aLimit ifNil: [ ^ true ].
	^ aCurrentSize < aLimit
]

{ #category : 'accessing' }
OTLogRecord >> attributeCountLimit [

	^ self limits attributeCountLimit
]

{ #category : 'accessing' }
OTLogRecord >> attributeNamed: aKey [

	^ self attributeNamed: aKey ifAbsent: [ nil ]
]

{ #category : 'accessing' }
OTLogRecord >> attributeNamed: aKey ifAbsent: aBlock [

	^ self attributes at: aKey ifAbsent: aBlock
]

{ #category : 'accessing' }
OTLogRecord >> attributeNamed: aKey put: aValue [

	| normalizedKey normalizedValue |
	normalizedKey := OTAttributeNormalizer normalizeAttributeKey: aKey.
	normalizedValue := OTAttributeNormalizer
		normalizeAttributeValue: aValue
		lengthLimit: self limits attributeValueLengthLimit.
	((attributes includesKey: normalizedKey)
		or: [ self attributeCountWithinLimit: self attributeCountLimit currentSize: attributes size ])
		ifTrue: [
			attributes at: normalizedKey put: normalizedValue.
			^ normalizedValue ].
	droppedAttributesCount := droppedAttributesCount + 1.
	self warnOnceAboutDiscardedData.
	^ normalizedValue
]

{ #category : 'accessing' }
OTLogRecord >> attributes [

	^ attributes ifNil: [ OrderedDictionary new ]
]

{ #category : 'accessing' }
OTLogRecord >> attributes: aCollection [

	| normalized |
	normalized := OTAttributeNormalizer
		normalizeAttributes: aCollection
		countLimit: self attributeCountLimit
		valueLengthLimit: self limits attributeValueLengthLimit.
	attributes := normalized first.
	droppedAttributesCount := normalized second.
	droppedAttributesCount > 0 ifTrue: [ self warnOnceAboutDiscardedData ].
	self
]

{ #category : 'accessing' }
OTLogRecord >> body [

	^ body
]

{ #category : 'accessing' }
OTLogRecord >> body: anObject [

	body := OTAttributeNormalizer
		normalizeAttributeValue: anObject
		lengthLimit: self limits attributeValueLengthLimit.
	^ body
]

{ #category : 'accessing' }
OTLogRecord >> context: anOTContext [

	| context span spanContext |
	context := anOTContext ifNil: [ OpenTelemetry currentContext ].
	span := context ifNotNil: [ context span ].
	span ifNil: [
		traceId := nil.
		spanId := nil.
		traceFlags := nil.
		^ self ].
	spanContext := span spanContext.
	spanContext isValid
		ifTrue: [
			traceId := spanContext traceId.
			spanId := spanContext spanId.
			traceFlags := spanContext traceFlags ]
		ifFalse: [
			traceId := nil.
			spanId := nil.
			traceFlags := nil ].
	self
]

{ #category : 'accessing' }
OTLogRecord >> droppedAttributesCount [

	^ droppedAttributesCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
OTLogRecord >> eventName [

	^ eventName
]

{ #category : 'accessing' }
OTLogRecord >> eventName: aString [

	eventName := aString ifNotNil: [ aString asString ].
	eventName ifNotNil: [ eventName isEmpty ifTrue: [ eventName := nil ] ].
	^ eventName
]

{ #category : 'accessing' }
OTLogRecord >> instrumentationScope [

	^ instrumentationScope ifNil: [ OTInstrumentationScope named: '' ]
]

{ #category : 'accessing' }
OTLogRecord >> instrumentationScope: anInstrumentationScope [

	instrumentationScope := anInstrumentationScope
		ifNil: [ OTInstrumentationScope named: '' ]
		ifNotNil: [ anInstrumentationScope ].
	^ instrumentationScope
]

{ #category : 'accessing' }
OTLogRecord >> instrumentationScopeAttributes [

	^ self instrumentationScope allAttributes
]

{ #category : 'accessing' }
OTLogRecord >> instrumentationVersion [

	^ self instrumentationScope version
]

{ #category : 'initialization' }
OTLogRecord >> initialize [

	super initialize.
	attributes := OrderedDictionary new.
	droppedAttributesCount := 0.
	severityNumber := OTSeverity undefined.
	resource := OTResource empty.
	instrumentationScope := OTInstrumentationScope named: ''.
	limits := OTLogRecordLimits default.
	warningSink := OTDiagnosticLogger defaultWarningSink.
	warnedAboutDiscardedData := false
]

{ #category : 'private - logging' }
OTLogRecord >> limitDiscardWarningMessage [

	^ String streamContents: [ :stream |
		stream
			nextPutAll: 'OpenTelemetry discarded log record attributes due to configured log record limits on ';
			nextPutAll: self printString;
			nextPutAll: '. Further warnings for this log record are suppressed.' ]
]

{ #category : 'accessing' }
OTLogRecord >> limits [

	^ limits ifNil: [ OTLogRecordLimits default ]
]

{ #category : 'accessing' }
OTLogRecord >> limits: someLimits [

	limits := (someLimits ifNil: [ OTLogRecordLimits default ] ifNotNil: [ someLimits ]) copy.
	^ limits
]

{ #category : 'accessing' }
OTLogRecord >> observedTimestamp [

	^ observedTimestamp
]

{ #category : 'accessing' }
OTLogRecord >> observedTimestamp: aDateAndTime [

	observedTimestamp := aDateAndTime.
	^ observedTimestamp
]

{ #category : 'private' }
OTLogRecord >> observedTimestampIfAbsentSetToNow [

	observedTimestamp ifNil: [ observedTimestamp := DateAndTime now ].
	^ observedTimestamp
]

{ #category : 'copying' }
OTLogRecord >> postCopy [

	super postCopy.
	timestamp := timestamp ifNotNil: [ timestamp copy ].
	observedTimestamp := observedTimestamp ifNotNil: [ observedTimestamp copy ].
	severityText := severityText ifNotNil: [ severityText copy ].
	severityNumber := severityNumber copy.
	attributes := attributes copy.
	droppedAttributesCount := droppedAttributesCount copy.
	eventName := eventName ifNotNil: [ eventName copy ].
	traceId := traceId ifNotNil: [ traceId copy ].
	spanId := spanId ifNotNil: [ spanId copy ].
	traceFlags := traceFlags ifNotNil: [ traceFlags copy ].
	resource := resource copy.
	instrumentationScope := instrumentationScope copy.
	limits := limits copy.
	warnedAboutDiscardedData := warnedAboutDiscardedData copy
]

{ #category : 'printing' }
OTLogRecord >> printOn: aStream [

	aStream nextPutAll: 'LogRecord['.
	self severityText
		ifNotNil: [ :value | aStream nextPutAll: value ]
		ifNil: [
			self severityNumber = OTSeverity undefined
				ifFalse: [ aStream nextPutAll: (OTSeverity shortNameFor: self severityNumber) ] ].
	self body ifNotNil: [
		(aStream position > 11) ifTrue: [ aStream nextPutAll: ': ' ].
		aStream nextPutAll: self body printString ].
	aStream nextPut: $]
]

{ #category : 'accessing' }
OTLogRecord >> removeAttributeNamed: aKey [

	| normalizedKey |
	normalizedKey := OTAttributeNormalizer normalizeAttributeKey: aKey.
	attributes removeKey: normalizedKey ifAbsent: [ ].
	self
]

{ #category : 'accessing' }
OTLogRecord >> resource [

	^ resource ifNil: [ OTResource empty ]
]

{ #category : 'accessing' }
OTLogRecord >> resource: anOTResource [

	resource := anOTResource ifNil: [ OTResource empty ] ifNotNil: [ anOTResource ].
	^ resource
]

{ #category : 'accessing' }
OTLogRecord >> severityNumber [

	^ OTSeverity normalize: severityNumber
]

{ #category : 'accessing' }
OTLogRecord >> severityNumber: anObject [

	severityNumber := OTSeverity normalize: anObject.
	^ severityNumber
]

{ #category : 'accessing' }
OTLogRecord >> severityText [

	^ severityText
]

{ #category : 'accessing' }
OTLogRecord >> severityText: aString [

	severityText := aString ifNotNil: [ aString asString ].
	severityText ifNotNil: [ severityText isEmpty ifTrue: [ severityText := nil ] ].
	^ severityText
]

{ #category : 'accessing' }
OTLogRecord >> spanId [

	^ spanId
]

{ #category : 'accessing' }
OTLogRecord >> spanId: aString [

	spanId := aString ifNotNil: [ aString asString ].
	^ spanId
]

{ #category : 'accessing' }
OTLogRecord >> timestamp [

	^ timestamp
]

{ #category : 'accessing' }
OTLogRecord >> timestamp: aDateAndTime [

	timestamp := aDateAndTime.
	^ timestamp
]

{ #category : 'accessing' }
OTLogRecord >> traceFlags [

	^ traceFlags
]

{ #category : 'accessing' }
OTLogRecord >> traceFlags: aString [

	traceFlags := aString ifNotNil: [ aString asString ].
	^ traceFlags
]

{ #category : 'accessing' }
OTLogRecord >> traceId [

	^ traceId
]

{ #category : 'accessing' }
OTLogRecord >> traceId: aString [

	traceId := aString ifNotNil: [ aString asString ].
	^ traceId
]

{ #category : 'accessing' }
OTLogRecord >> warningSink [

	^ warningSink
]

{ #category : 'accessing' }
OTLogRecord >> warningSink: aBlock [

	warningSink := aBlock ifNil: [ OTDiagnosticLogger defaultWarningSink ] ifNotNil: [ aBlock ].
	^ warningSink
]

{ #category : 'private - logging' }
OTLogRecord >> warnOnceAboutDiscardedData [

	warnedAboutDiscardedData ifTrue: [ ^ self ].
	warnedAboutDiscardedData := true.
	self warningSink value: self limitDiscardWarningMessage.
	self
]
