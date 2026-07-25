"
An OT Trace text-map propagator that extracts and injects the legacy OpenTracing basic-tracer header format together with ot-baggage-* entries.
"
Class {
	#name : 'OTOtTraceTextMapPropagator',
	#superclass : 'OTTextMapPropagator',
	#category : 'OpenTelemetry-Traces',
	#package : 'OpenTelemetry-Traces'
}

{ #category : 'accessing' }
OTOtTraceTextMapPropagator class >> baggagePrefix [

	^ 'ot-baggage-'
]

{ #category : 'accessing' }
OTOtTraceTextMapPropagator class >> maxBaggageBytes [

	^ 8192
]

{ #category : 'accessing' }
OTOtTraceTextMapPropagator class >> maxBaggageEntries [

	^ 64
]

{ #category : 'class initialization' }
OTOtTraceTextMapPropagator class >> reset [

	^ self
]

{ #category : 'accessing' }
OTOtTraceTextMapPropagator class >> sampledHeaderName [

	^ 'ot-tracer-sampled'
]

{ #category : 'accessing' }
OTOtTraceTextMapPropagator class >> spanIdHeaderName [

	^ 'ot-tracer-spanid'
]

{ #category : 'accessing' }
OTOtTraceTextMapPropagator class >> traceIdHeaderName [

	^ 'ot-tracer-traceid'
]

{ #category : 'private' }
OTOtTraceTextMapPropagator >> baggageBytesOf: aBaggage [

	^ aBaggage entries inject: 0 into: [ :total :each | total + each key size + each value value size ]
]

{ #category : 'private' }
OTOtTraceTextMapPropagator >> baggageFromCarrier: aCarrier getter: aGetter [

	| baggage |
	baggage := OTBaggage empty.
	(aGetter keysIn: aCarrier) do: [ :eachKey |
			| baggageKey value updatedBaggage |
			baggage size >= self class maxBaggageEntries ifTrue: [ ^ baggage ].
			baggageKey := self baggageKeyFromHeaderName: eachKey.
			baggageKey ifNotNil: [
					value := self headerValueIn: eachKey from: aCarrier getter: aGetter.
					(value isNotNil and: [ value isNotEmpty ]) ifTrue: [
							updatedBaggage := baggage withEntryNamed: baggageKey value: value metadata: nil.
							(self baggageBytesOf: updatedBaggage) > self class maxBaggageBytes
								ifTrue: [ ^ baggage ]
								ifFalse: [ baggage := updatedBaggage ] ] ] ].
	^ baggage
]

{ #category : 'private' }
OTOtTraceTextMapPropagator >> baggageKeyFromHeaderName: aString [

	| headerName prefix |
	aString ifNil: [ ^ nil ].
	headerName := aString asString asLowercase.
	prefix := self class baggagePrefix.
	((headerName beginsWith: prefix) and: [ headerName size > prefix size ]) ifFalse: [ ^ nil ].
	^ headerName copyFrom: prefix size + 1 to: headerName size
]

{ #category : 'extracting' }
OTOtTraceTextMapPropagator >> extract: aContext from: aCarrier [

	^ self extract: aContext from: aCarrier getter: OTDictionaryTextMapGetter current
]

{ #category : 'extracting' }
OTOtTraceTextMapPropagator >> extract: aContext from: aCarrier getter: aGetter [

	| baseContext traceId spanId sampled spanContext context baggage |
	baseContext := aContext ifNil: [ OTContext new ] ifNotNil: [ aContext ].
	aGetter ifNil: [ ^ baseContext ].
	traceId := self headerValueIn: self class traceIdHeaderName from: aCarrier getter: aGetter.
	spanId := self headerValueIn: self class spanIdHeaderName from: aCarrier getter: aGetter.
	sampled := self headerValueIn: self class sampledHeaderName from: aCarrier getter: aGetter.
	spanContext := self spanContextFromTraceId: traceId spanId: spanId sampled: sampled.
	spanContext ifNil: [ ^ baseContext ].
	context := baseContext withSpan: spanContext asNonRecordingSpan.
	baggage := self baggageFromCarrier: aCarrier getter: aGetter.
	baggage isEmpty ifTrue: [ ^ context ].
	^ context withBaggage: baggage
]

{ #category : 'accessing' }
OTOtTraceTextMapPropagator >> fields [

	^ {
		  self class traceIdHeaderName.
		  self class spanIdHeaderName.
		  self class sampledHeaderName }
]

{ #category : 'private' }
OTOtTraceTextMapPropagator >> headerStringFrom: anObject [

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
OTOtTraceTextMapPropagator >> headerValueIn: aHeaderName from: aCarrier getter: aGetter [

	^ self headerStringFrom: (aGetter getFrom: aCarrier key: aHeaderName)
]

{ #category : 'injecting' }
OTOtTraceTextMapPropagator >> inject: aContext into: aCarrier [

	^ self inject: aContext into: aCarrier setter: OTDictionaryTextMapSetter current
]

{ #category : 'injecting' }
OTOtTraceTextMapPropagator >> inject: aContext into: aCarrier setter: aSetter [

	| spanContext |
	(aContext isNil or: [ aSetter isNil ]) ifTrue: [ ^ self ].
	spanContext := aContext span ifNotNil: [ :span | span spanContext ].
	(spanContext isNil or: [ spanContext isValid not ]) ifTrue: [ ^ self ].
	aSetter setIn: aCarrier key: self class traceIdHeaderName value: (spanContext traceId copyFrom: 17 to: 32).
	aSetter setIn: aCarrier key: self class spanIdHeaderName value: spanContext spanId.
	aSetter setIn: aCarrier key: self class sampledHeaderName value: (spanContext isSampled
			 ifTrue: [ 'true' ]
			 ifFalse: [ 'false' ]).
	self injectBaggage: aContext baggage into: aCarrier setter: aSetter.
	^ self
]

{ #category : 'private' }
OTOtTraceTextMapPropagator >> injectBaggage: aBaggage into: aCarrier setter: aSetter [

	| baggage entriesEmitted bytesEmitted |
	baggage := aBaggage ifNil: [ OTBaggage empty ] ifNotNil: [ aBaggage ].
	entriesEmitted := 0.
	bytesEmitted := 0.
	baggage entries do: [ :each |
			| key value projectedBytes |
			entriesEmitted < self class maxBaggageEntries ifTrue: [
					key := each key.
					value := each value value.
					((OTW3CBaggagePropagator current isValidBaggageKey: key) and: [ value isNotNil and: [ value isNotEmpty ] ]) ifTrue: [
							projectedBytes := bytesEmitted + key size + value size.
							projectedBytes <= self class maxBaggageBytes ifTrue: [
									aSetter setIn: aCarrier key: self class baggagePrefix , key value: value.
									entriesEmitted := entriesEmitted + 1.
									bytesEmitted := projectedBytes ] ] ] ].
	^ self
]

{ #category : 'private' }
OTOtTraceTextMapPropagator >> isHexString: aString maxSize: anInteger [

	aString ifNil: [ ^ false ].
	(aString isEmpty or: [ aString size > anInteger ]) ifTrue: [ ^ false ].
	^ aString allSatisfy: [ :each | each isDigit or: [ 'abcdef' includes: each asLowercase ] ]
]

{ #category : 'private' }
OTOtTraceTextMapPropagator >> normalizedSpanId: aString [

	| spanId padded |
	aString ifNil: [ ^ nil ].
	spanId := aString asLowercase.
	(self isHexString: spanId maxSize: 16) ifFalse: [ ^ nil ].
	padded := spanId padLeftTo: 16 with: $0.
	^ (OTSpanContext isZeroHexIdentifier: padded)
		  ifTrue: [ nil ]
		  ifFalse: [ padded ]
]

{ #category : 'private' }
OTOtTraceTextMapPropagator >> normalizedTraceId: aString [

	| traceId padded |
	aString ifNil: [ ^ nil ].
	traceId := aString asLowercase.
	((traceId size = 16 or: [ traceId size = 32 ]) and: [ self isHexString: traceId maxSize: 32 ]) ifFalse: [ ^ nil ].
	padded := traceId padLeftTo: 32 with: $0.
	^ (OTSpanContext isZeroHexIdentifier: padded)
		  ifTrue: [ nil ]
		  ifFalse: [ padded ]
]

{ #category : 'private' }
OTOtTraceTextMapPropagator >> spanContextFromTraceId: aTraceId spanId: aSpanId sampled: aSampledValue [

	| traceId spanId |
	traceId := self normalizedTraceId: aTraceId.
	traceId ifNil: [ ^ nil ].
	spanId := self normalizedSpanId: aSpanId.
	spanId ifNil: [ ^ nil ].
	^ OTSpanContext
		  traceId: traceId
		  spanId: spanId
		  traceFlags: (self traceFlagsFromSampled: aSampledValue)
		  traceState: nil
		  remote: true
]

{ #category : 'private' }
OTOtTraceTextMapPropagator >> traceFlagsFromSampled: aString [

	aString ifNil: [ ^ '00' ].
	(aString = '1' or: [ aString asLowercase = 'true' ]) ifTrue: [ ^ '01' ].
	^ '00'
]
