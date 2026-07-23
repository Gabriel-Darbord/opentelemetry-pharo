"
A W3C Trace Context text-map propagator for traceparent and tracestate headers.
"
Class {
	#name : 'OTW3CTraceContextPropagator',
	#superclass : 'OTTextMapPropagator',
	#classInstVars : [
		'current'
	],
	#category : 'OpenTelemetry-Instrumentation',
	#package : 'OpenTelemetry-Instrumentation'
}

{ #category : 'accessing' }
OTW3CTraceContextPropagator class >> current [

	^ current ifNil: [ current := self new ]
]

{ #category : 'class initialization' }
OTW3CTraceContextPropagator class >> reset [

	current := nil
]

{ #category : 'accessing' }
OTW3CTraceContextPropagator class >> traceParentHeaderName [

	^ 'traceparent'
]

{ #category : 'accessing' }
OTW3CTraceContextPropagator class >> traceStateHeaderName [

	^ 'tracestate'
]

{ #category : 'private' }
OTW3CTraceContextPropagator >> combinedHeaderValueIn: aHeaderName from: aCarrier getter: aGetter [

	| normalizedValues |
	normalizedValues := (aGetter getAllFrom: aCarrier key: aHeaderName)
		                    collect: [ :each | self headerStringFrom: each ]
		                    thenSelect: [ :each | each isNotNil ].
	normalizedValues ifEmpty: [ ^ nil ].
	^ String streamContents: [ :stream |
		  normalizedValues do: [ :each | stream nextPutAll: each ] separatedBy: [ stream nextPut: $, ] ]
]

{ #category : 'extracting' }
OTW3CTraceContextPropagator >> extract: aContext from: aCarrier [

	^ self extract: aContext from: aCarrier getter: OTDictionaryTextMapGetter current
]

{ #category : 'extracting' }
OTW3CTraceContextPropagator >> extract: aContext from: aCarrier getter: aGetter [

	| baseContext spanContext traceParent traceState |
	baseContext := aContext ifNil: [ OTContext new ] ifNotNil: [ aContext ].
	aGetter ifNil: [ ^ baseContext ].
	traceParent := self headerValueIn: self class traceParentHeaderName from: aCarrier getter: aGetter.
	spanContext := self extractSpanContextFromTraceParent: traceParent.
	spanContext ifNil: [ ^ baseContext ].
	traceState := self combinedHeaderValueIn: self class traceStateHeaderName from: aCarrier getter: aGetter.
	^ baseContext withSpan: (self spanContext: spanContext withTraceStateHeader: traceState) asNonRecordingSpan
]

{ #category : 'private' }
OTW3CTraceContextPropagator >> extractSpanContextFromTraceParent: aString [

	| traceParent version traceId spanId traceFlags |
	aString ifNil: [ ^ nil ].
	traceParent := aString trimBoth.
	traceParent ifEmpty: [ ^ nil ].
	(self hasValidTraceParentLayout: traceParent) ifFalse: [ ^ nil ].
	version := traceParent copyFrom: 1 to: 2.
	(self isValidVersion: version forTraceParent: traceParent) ifFalse: [ ^ nil ].
	traceId := traceParent copyFrom: 4 to: 35.
	spanId := traceParent copyFrom: 37 to: 52.
	traceFlags := traceParent copyFrom: 54 to: 55.
	((self isValidIdentifier: traceId size: 32) and: [
		 (self isValidIdentifier: spanId size: 16) and: [ self isLowercaseHexString: traceFlags size: 2 ] ]) ifFalse: [ ^ nil ].
	^ OTSpanContext
		  traceId: traceId
		  spanId: spanId
		  traceFlags: traceFlags
		  traceState: nil
		  remote: true
]

{ #category : 'accessing' }
OTW3CTraceContextPropagator >> fields [

	^ {
		  self class traceParentHeaderName.
		  self class traceStateHeaderName }
]

{ #category : 'private' }
OTW3CTraceContextPropagator >> hasValidTraceParentLayout: aString [

	aString size < 55 ifTrue: [ ^ false ].
	^ (aString at: 3) = $- and: [
		  (aString at: 36) = $- and: [ (aString at: 53) = $- and: [ aString size = 55 or: [ (aString at: 56) = $- ] ] ] ]
]

{ #category : 'private' }
OTW3CTraceContextPropagator >> headerStringFrom: anObject [

	| firstValue normalized |
	anObject ifNil: [ ^ nil ].
	(anObject isString or: [ anObject isSymbol ]) ifTrue: [
			normalized := anObject asString trimBoth.
			^ normalized isEmpty
				  ifTrue: [ nil ]
				  ifFalse: [ normalized ] ].
	anObject isCollection ifTrue: [
			firstValue := anObject detect: [ :each | each isNotNil ] ifNone: [ nil ].
			^ self headerStringFrom: firstValue ].
	normalized := anObject asString trimBoth.
	^ normalized isEmpty
		  ifTrue: [ nil ]
		  ifFalse: [ normalized ]
]

{ #category : 'private' }
OTW3CTraceContextPropagator >> headerValueIn: aHeaderName from: aCarrier getter: aGetter [

	^ self headerStringFrom: (aGetter getFrom: aCarrier key: aHeaderName)
]

{ #category : 'injecting' }
OTW3CTraceContextPropagator >> inject: aContext into: aCarrier [

	^ self inject: aContext into: aCarrier setter: OTDictionaryTextMapSetter current
]

{ #category : 'injecting' }
OTW3CTraceContextPropagator >> inject: aContext into: aCarrier setter: aSetter [

	| span spanContext traceState |
	aSetter ifNil: [ ^ self ].
	span := aContext ifNotNil: [ aContext span ].
	span ifNil: [ ^ self ].
	spanContext := span spanContext.
	spanContext isValid ifFalse: [ ^ self ].
	aSetter setIn: aCarrier key: self class traceParentHeaderName value: (self traceParentFor: spanContext).
	traceState := self normalizedTraceStateFrom: spanContext.
	traceState ifNotNil: [ aSetter setIn: aCarrier key: self class traceStateHeaderName value: traceState ].
	^ self
]

{ #category : 'private' }
OTW3CTraceContextPropagator >> isLowercaseHexString: aString size: anInteger [

	aString ifNil: [ ^ false ].
	aString size = anInteger ifFalse: [ ^ false ].
	^ aString allSatisfy: [ :each | each isDigit or: [ 'abcdef' includes: each ] ]
]

{ #category : 'private' }
OTW3CTraceContextPropagator >> isValidIdentifier: aString size: anInteger [

	^ (self isLowercaseHexString: aString size: anInteger) and: [ (OTSpanContext isZeroHexIdentifier: aString) not ]
]

{ #category : 'private' }
OTW3CTraceContextPropagator >> isValidTraceState: aString [

	^ (OTTraceState fromHeader: aString) isNotNil
]

{ #category : 'private' }
OTW3CTraceContextPropagator >> isValidTraceStateEntry: aString [

	^ (OTTraceState fromHeader: aString) isNotNil
]

{ #category : 'private' }
OTW3CTraceContextPropagator >> isValidVersion: aVersion forTraceParent: aTraceParent [

	(self isLowercaseHexString: aVersion size: 2) ifFalse: [ ^ false ].
	aVersion = 'ff' ifTrue: [ ^ false ].
	aVersion = '00' ifTrue: [ ^ aTraceParent size = 55 ].
	^ true
]

{ #category : 'private' }
OTW3CTraceContextPropagator >> normalizedTraceFlagsFrom: aSpanContext [

	| traceFlags |
	traceFlags := aSpanContext traceFlags.
	(self isLowercaseHexString: traceFlags size: 2) ifTrue: [ ^ traceFlags ].
	^ '00'
]

{ #category : 'private' }
OTW3CTraceContextPropagator >> normalizedTraceStateFrom: aSpanContext [

	| traceState |
	traceState := aSpanContext traceState.
	traceState ifNil: [ ^ nil ].
	traceState isEmpty ifTrue: [ ^ nil ].
	^ traceState asHeaderValue
]

{ #category : 'private' }
OTW3CTraceContextPropagator >> spanContext: aSpanContext withTraceStateHeader: aString [

	| traceState |
	traceState := OTTraceState fromHeader: aString.
	(traceState isNil or: [ traceState isEmpty ]) ifTrue: [ ^ aSpanContext ].
	^ (aSpanContext withTraceState: traceState) asRemote
]

{ #category : 'private' }
OTW3CTraceContextPropagator >> traceParentFor: aSpanContext [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: '00-';
				  nextPutAll: aSpanContext traceId;
				  nextPut: $-;
				  nextPutAll: aSpanContext spanId;
				  nextPut: $-;
				  nextPutAll: (self normalizedTraceFlagsFrom: aSpanContext) ]
]
