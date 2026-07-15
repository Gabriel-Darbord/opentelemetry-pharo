"
A B3 text-map propagator that extracts both single and multi-header encodings and injects either single or multi-header format depending on configuration.
"
Class {
	#name : 'OTB3TextMapPropagator',
	#superclass : 'OTTextMapPropagator',
	#instVars : [
		'injectMultiHeaders'
	],
	#category : 'OpenTelemetry-Instrumentation',
	#package : 'OpenTelemetry-Instrumentation'
}

{ #category : 'accessing' }
OTB3TextMapPropagator class >> b3HeaderName [

	^ 'b3'
]

{ #category : 'accessing' }
OTB3TextMapPropagator class >> debugHeaderName [

	^ 'x-b3-flags'
]

{ #category : 'accessing' }
OTB3TextMapPropagator class >> debugPropertyKey [

	^ #b3DebugFlag
]

{ #category : 'accessing' }
OTB3TextMapPropagator class >> multiHeader [

	^ self new
		injectMultiHeaders;
		yourself
]

{ #category : 'accessing' }
OTB3TextMapPropagator class >> multiHeaderSampledHeaderName [

	^ 'x-b3-sampled'
]

{ #category : 'accessing' }
OTB3TextMapPropagator class >> multiHeaderSpanIdHeaderName [

	^ 'x-b3-spanid'
]

{ #category : 'accessing' }
OTB3TextMapPropagator class >> multiHeaderTraceIdHeaderName [

	^ 'x-b3-traceid'
]

{ #category : 'class initialization' }
OTB3TextMapPropagator class >> reset [

	^ self
]

{ #category : 'accessing' }
OTB3TextMapPropagator class >> singleHeader [

	^ self new
		injectSingleHeader;
		yourself
]

{ #category : 'extracting' }
OTB3TextMapPropagator >> extract: aContext from: aCarrier [

	^ self extract: aContext from: aCarrier getter: OTDictionaryTextMapGetter current
]

{ #category : 'extracting' }
OTB3TextMapPropagator >> extract: aContext from: aCarrier getter: aGetter [

	| baseContext singleHeaderValue |
	baseContext := aContext ifNil: [ OTContext new ] ifNotNil: [ aContext ].
	aGetter ifNil: [ ^ baseContext ].
	singleHeaderValue := self
		headerValueIn: self class b3HeaderName
		from: aCarrier
		getter: aGetter.
	singleHeaderValue ifNotNil: [ ^ self extractSingleHeader: singleHeaderValue into: baseContext ].
	^ self extractMultiHeaderFrom: baseContext carrier: aCarrier getter: aGetter
]

{ #category : 'private' }
OTB3TextMapPropagator >> extractMultiHeaderFrom: aContext carrier: aCarrier getter: aGetter [

	| traceId spanId debugValue sampledValue traceFlags context |
	traceId := self
		headerValueIn: self class multiHeaderTraceIdHeaderName
		from: aCarrier
		getter: aGetter.
	spanId := self
		headerValueIn: self class multiHeaderSpanIdHeaderName
		from: aCarrier
		getter: aGetter.
	(self isValidTraceId: traceId) ifFalse: [ ^ aContext ].
	(self isValidSpanId: spanId) ifFalse: [ ^ aContext ].
	debugValue := self
		headerValueIn: self class debugHeaderName
		from: aCarrier
		getter: aGetter.
	sampledValue := self
		headerValueIn: self class multiHeaderSampledHeaderName
		from: aCarrier
		getter: aGetter.
	traceFlags := self
		traceFlagsForMultiHeaderSampledValue: sampledValue
		debugValue: debugValue.
	traceFlags ifNil: [ ^ aContext ].
	context := aContext withSpan: ((self
		spanContextForTraceId: traceId
		spanId: spanId
		traceFlags: traceFlags) asNonRecordingSpan).
	(self isDebugHeaderValue: debugValue)
		ifTrue: [ ^ context withPropertyAt: self class debugPropertyKey put: true ].
	^ context withoutPropertyAt: self class debugPropertyKey
]

{ #category : 'private' }
OTB3TextMapPropagator >> extractSingleHeader: aString into: aContext [

	| parts traceId spanId samplingState traceFlags context |
	parts := aString substrings: '-'.
	((parts size between: 2 and: 4)) ifFalse: [ ^ aContext ].
	traceId := parts first trimBoth.
	spanId := parts second trimBoth.
	(self isValidTraceId: traceId) ifFalse: [ ^ aContext ].
	(self isValidSpanId: spanId) ifFalse: [ ^ aContext ].
	samplingState := parts size >= 3 ifTrue: [ parts third ] ifFalse: [ nil ].
	traceFlags := self traceFlagsForSingleHeaderSamplingState: samplingState.
	traceFlags ifNil: [ ^ aContext ].
	context := aContext withSpan: ((self
		spanContextForTraceId: traceId
		spanId: spanId
		traceFlags: traceFlags) asNonRecordingSpan).
	((samplingState ifNil: [ '' ] ifNotNil: [ samplingState ]) trimBoth asLowercase = 'd')
		ifTrue: [ ^ context withPropertyAt: self class debugPropertyKey put: true ].
	^ context withoutPropertyAt: self class debugPropertyKey
]

{ #category : 'accessing' }
OTB3TextMapPropagator >> fields [

	^ injectMultiHeaders
		ifTrue: [ {
			self class multiHeaderTraceIdHeaderName.
			self class multiHeaderSpanIdHeaderName.
			self class multiHeaderSampledHeaderName.
			self class debugHeaderName } ]
		ifFalse: [ { self class b3HeaderName } ]
]

{ #category : 'private' }
OTB3TextMapPropagator >> headerStringFrom: anObject [

	| firstValue normalized |
	anObject ifNil: [ ^ nil ].
	(anObject isString or: [ anObject isSymbol ]) ifTrue: [
		normalized := anObject asString trimBoth.
		^ normalized isEmpty ifTrue: [ nil ] ifFalse: [ normalized ] ].
	anObject isCollection ifTrue: [
		firstValue := anObject
			detect: [ :each | each isNotNil ]
			ifNone: [ nil ].
		^ self headerStringFrom: firstValue ].
	normalized := anObject asString trimBoth.
	^ normalized isEmpty ifTrue: [ nil ] ifFalse: [ normalized ]
]

{ #category : 'private' }
OTB3TextMapPropagator >> headerValueIn: aHeaderName from: aCarrier getter: aGetter [

	^ self headerStringFrom: (aGetter getFrom: aCarrier key: aHeaderName)
]

{ #category : 'initialization' }
OTB3TextMapPropagator >> initialize [

	super initialize.
	injectMultiHeaders := false
]

{ #category : 'injecting' }
OTB3TextMapPropagator >> inject: aContext into: aCarrier [

	^ self inject: aContext into: aCarrier setter: OTDictionaryTextMapSetter current
]

{ #category : 'injecting' }
OTB3TextMapPropagator >> inject: aContext into: aCarrier setter: aSetter [

	| context span spanContext |
	context := aContext ifNil: [ OTContext new ] ifNotNil: [ aContext ].
	aSetter ifNil: [ ^ self ].
	span := context span.
	span ifNil: [ ^ self ].
	spanContext := span spanContext.
	spanContext isValid ifFalse: [ ^ self ].
	injectMultiHeaders
		ifTrue: [ self injectMultiHeadersFrom: context spanContext: spanContext into: aCarrier setter: aSetter ]
		ifFalse: [ self injectSingleHeaderFrom: context spanContext: spanContext into: aCarrier setter: aSetter ].
	^ self
]

{ #category : 'initialization' }
OTB3TextMapPropagator >> injectMultiHeaders [

	injectMultiHeaders := true.
	^ self
]

{ #category : 'private' }
OTB3TextMapPropagator >> injectMultiHeadersFrom: aContext spanContext: aSpanContext into: aCarrier setter: aSetter [

	aSetter
		setIn: aCarrier
		key: self class multiHeaderTraceIdHeaderName
		value: aSpanContext traceId.
	aSetter
		setIn: aCarrier
		key: self class multiHeaderSpanIdHeaderName
		value: aSpanContext spanId.
	(aContext propertyAt: self class debugPropertyKey ifAbsent: [ false ])
		ifTrue: [
			aSetter
				setIn: aCarrier
				key: self class debugHeaderName
				value: '1'.
			^ self ].
	aSetter
		setIn: aCarrier
		key: self class multiHeaderSampledHeaderName
		value: (aSpanContext isSampled ifTrue: [ '1' ] ifFalse: [ '0' ]).
	^ self
]

{ #category : 'initialization' }
OTB3TextMapPropagator >> injectSingleHeader [

	injectMultiHeaders := false.
	^ self
]

{ #category : 'private' }
OTB3TextMapPropagator >> injectSingleHeaderFrom: aContext spanContext: aSpanContext into: aCarrier setter: aSetter [

	| value |
	value := String streamContents: [ :stream |
		stream
			nextPutAll: aSpanContext traceId;
			nextPut: $-;
			nextPutAll: aSpanContext spanId;
			nextPut: $-;
			nextPutAll: (self samplingStateFor: aSpanContext in: aContext) ].
	aSetter
		setIn: aCarrier
		key: self class b3HeaderName
		value: value.
	^ self
]

{ #category : 'private' }
OTB3TextMapPropagator >> isDebugHeaderValue: aString [

	^ aString isNotNil and: [ aString trimBoth = '1' ]
]

{ #category : 'private' }
OTB3TextMapPropagator >> isHexString: aString size: anInteger [

	aString ifNil: [ ^ false ].
	aString size = anInteger ifFalse: [ ^ false ].
	^ aString allSatisfy: [ :each |
		each isDigit or: [ 'abcdefABCDEF' includes: each ] ]
]

{ #category : 'private' }
OTB3TextMapPropagator >> isValidSpanId: aString [

	| normalized |
	normalized := aString ifNil: [ ^ false ] ifNotNil: [ aString trimBoth asLowercase ].
	^ (self isHexString: normalized size: 16)
		and: [ (OTSpan isZeroHexIdentifier: normalized) not ]
]

{ #category : 'private' }
OTB3TextMapPropagator >> isValidTraceId: aString [

	| normalized |
	normalized := self normalizedTraceIdFromB3: aString.
	^ (self isHexString: normalized size: 32)
		and: [ (OTSpan isZeroHexIdentifier: normalized) not ]
]

{ #category : 'private' }
OTB3TextMapPropagator >> normalizedTraceIdFromB3: aString [

	| normalized |
	normalized := aString ifNil: [ '' ] ifNotNil: [ aString trimBoth asLowercase ].
	normalized size = 16 ifTrue: [ ^ '0000000000000000', normalized ].
	^ normalized
]

{ #category : 'private' }
OTB3TextMapPropagator >> samplingStateFor: aSpanContext in: aContext [

	(aContext propertyAt: self class debugPropertyKey ifAbsent: [ false ]) ifTrue: [ ^ 'd' ].
	^ aSpanContext isSampled ifTrue: [ '1' ] ifFalse: [ '0' ]
]

{ #category : 'private' }
OTB3TextMapPropagator >> spanContextForTraceId: aTraceId spanId: aSpanId traceFlags: someTraceFlags [

	^ OTSpanContext
		traceId: (self normalizedTraceIdFromB3: aTraceId)
		spanId: aSpanId trimBoth asLowercase
		traceFlags: someTraceFlags
		traceState: nil
		remote: true
]

{ #category : 'private' }
OTB3TextMapPropagator >> traceFlagsForMultiHeaderSampledValue: aSampledValue debugValue: aDebugValue [

	| normalized |
	(self isDebugHeaderValue: aDebugValue) ifTrue: [ ^ '01' ].
	aSampledValue ifNil: [ ^ '00' ].
	normalized := aSampledValue trimBoth asLowercase.
	(normalized = '1' or: [ normalized = 'true' ]) ifTrue: [ ^ '01' ].
	(normalized = '0' or: [ normalized = 'false' ]) ifTrue: [ ^ '00' ].
	^ nil
]

{ #category : 'private' }
OTB3TextMapPropagator >> traceFlagsForSingleHeaderSamplingState: aString [

	| normalized |
	aString ifNil: [ ^ '00' ].
	normalized := aString trimBoth asLowercase.
	normalized isEmpty ifTrue: [ ^ '00' ].
	(normalized = '1' or: [ normalized = 'd' ]) ifTrue: [ ^ '01' ].
	normalized = '0' ifTrue: [ ^ '00' ].
	^ nil
]
