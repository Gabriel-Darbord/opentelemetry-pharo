"
A Jaeger text-map propagator that extracts and injects the legacy uber-trace-id format together with Jaeger baggage headers.
"
Class {
	#name : 'OTJaegerTextMapPropagator',
	#superclass : 'OTTextMapPropagator',
	#category : 'OpenTelemetry-Instrumentation',
	#package : 'OpenTelemetry-Instrumentation'
}

{ #category : 'accessing' }
OTJaegerTextMapPropagator class >> baggageHeaderName [

	^ 'jaeger-baggage'
]

{ #category : 'accessing' }
OTJaegerTextMapPropagator class >> baggagePrefix [

	^ 'uberctx-'
]

{ #category : 'accessing' }
OTJaegerTextMapPropagator class >> deprecatedParentSpanId [

	^ '0'
]

{ #category : 'accessing' }
OTJaegerTextMapPropagator class >> maxBaggageBytes [

	^ 8192
]

{ #category : 'accessing' }
OTJaegerTextMapPropagator class >> maxBaggageEntries [

	^ 64
]

{ #category : 'accessing' }
OTJaegerTextMapPropagator class >> propagationHeaderName [

	^ 'uber-trace-id'
]

{ #category : 'class initialization' }
OTJaegerTextMapPropagator class >> reset [

	^ self
]

{ #category : 'private' }
OTJaegerTextMapPropagator >> baggageBytesOf: aBaggage [

	^ aBaggage entries
		inject: 0
		into: [ :total :each |
			total + each key size + each value value size ]
]

{ #category : 'private' }
OTJaegerTextMapPropagator >> baggageFromCarrier: aCarrier getter: aGetter [

	| baggage |
	baggage := OTBaggage empty.
	(aGetter keysIn: aCarrier) do: [ :eachKey |
		| baggageKey value updatedBaggage |
		baggage size >= self class maxBaggageEntries ifTrue: [ ^ baggage ].
		(eachKey sameAs: self class baggageHeaderName)
			ifTrue: [ baggage := self baggageFromJaegerHeader: (self headerValueIn: eachKey from: aCarrier getter: aGetter) startingWith: baggage ]
			ifFalse: [
				baggageKey := self baggageKeyFromPrefixedHeaderName: eachKey.
				baggageKey ifNotNil: [
					value := self headerValueIn: eachKey from: aCarrier getter: aGetter.
					((OTW3CBaggagePropagator current isValidBaggageKey: baggageKey) and: [ value isNotNil and: [ value isNotEmpty ] ]) ifTrue: [
						updatedBaggage := baggage withEntryNamed: baggageKey value: value metadata: nil.
						(self baggageBytesOf: updatedBaggage) > self class maxBaggageBytes
							ifTrue: [ ^ baggage ]
							ifFalse: [ baggage := updatedBaggage ] ] ] ] ].
	^ baggage
]

{ #category : 'private' }
OTJaegerTextMapPropagator >> baggageFromJaegerHeader: aString startingWith: aBaggage [

	| baggage |
	aString ifNil: [ ^ aBaggage ].
	baggage := aBaggage.
	(aString substrings: ',') do: [ :eachMember |
		| member separator key value updatedBaggage |
		baggage size >= self class maxBaggageEntries ifTrue: [ ^ baggage ].
		member := eachMember trimBoth.
		member isEmpty ifFalse: [
			separator := member indexOf: $= ifAbsent: [ 0 ].
			(separator > 1 and: [ separator < member size ]) ifTrue: [
				key := (member copyFrom: 1 to: separator - 1) trimBoth.
				value := (member copyFrom: separator + 1 to: member size) trimBoth.
				((OTW3CBaggagePropagator current isValidBaggageKey: key) and: [ value isNotEmpty ]) ifTrue: [
					updatedBaggage := baggage withEntryNamed: key value: value metadata: nil.
					(self baggageBytesOf: updatedBaggage) > self class maxBaggageBytes
						ifTrue: [ ^ baggage ]
						ifFalse: [ baggage := updatedBaggage ] ] ] ] ].
	^ baggage
]

{ #category : 'private' }
OTJaegerTextMapPropagator >> baggageKeyFromPrefixedHeaderName: aString [

	| headerName prefix |
	aString ifNil: [ ^ nil ].
	headerName := aString asString.
	prefix := self class baggagePrefix.
	((headerName asLowercase beginsWith: prefix) and: [ headerName size > prefix size ])
		ifFalse: [ ^ nil ].
	^ headerName copyFrom: prefix size + 1 to: headerName size
]

{ #category : 'extracting' }
OTJaegerTextMapPropagator >> extract: aContext from: aCarrier [

	^ self extract: aContext from: aCarrier getter: OTDictionaryTextMapGetter current
]

{ #category : 'extracting' }
OTJaegerTextMapPropagator >> extract: aContext from: aCarrier getter: aGetter [

	| baseContext spanContext baggage context |
	baseContext := aContext ifNil: [ OTContext new ] ifNotNil: [ aContext ].
	aGetter ifNil: [ ^ baseContext ].
	spanContext := self
		extractSpanContextFrom: (self
			headerValueIn: self class propagationHeaderName
			from: aCarrier
			getter: aGetter).
	context := spanContext
		ifNil: [ baseContext ]
		ifNotNil: [ baseContext withSpan: spanContext asNonRecordingSpan ].
	baggage := self baggageFromCarrier: aCarrier getter: aGetter.
	baggage isEmpty ifTrue: [ ^ context ].
	^ context withBaggage: baggage
]

{ #category : 'private' }
OTJaegerTextMapPropagator >> extractSpanContextFrom: aString [

	| parts traceId spanId traceFlags |
	parts := self parseJaegerHeaderPartsFrom: aString.
	parts ifNil: [ ^ nil ].
	traceId := self normalizedTraceIdFromJaeger: parts first.
	traceId ifNil: [ ^ nil ].
	spanId := self normalizedSpanIdFromJaeger: parts second.
	spanId ifNil: [ ^ nil ].
	traceFlags := self traceFlagsFromJaegerFlags: parts fourth.
	traceFlags ifNil: [ ^ nil ].
	^ self
		spanContextForTraceId: traceId
		spanId: spanId
		traceFlags: traceFlags
]

{ #category : 'accessing' }
OTJaegerTextMapPropagator >> fields [

	^ { self class propagationHeaderName }
]

{ #category : 'private' }
OTJaegerTextMapPropagator >> headerStringFrom: anObject [

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
OTJaegerTextMapPropagator >> headerValueIn: aHeaderName from: aCarrier getter: aGetter [

	^ self headerStringFrom: (aGetter getFrom: aCarrier key: aHeaderName)
]

{ #category : 'injecting' }
OTJaegerTextMapPropagator >> inject: aContext into: aCarrier [

	^ self inject: aContext into: aCarrier setter: OTDictionaryTextMapSetter current
]

{ #category : 'injecting' }
OTJaegerTextMapPropagator >> inject: aContext into: aCarrier setter: aSetter [

	| span spanContext |
	(aContext isNil or: [ aSetter isNil ]) ifTrue: [ ^ self ].
	span := aContext span.
	spanContext := span ifNil: [ nil ] ifNotNil: [ span spanContext ].
	(spanContext notNil and: [ spanContext isValid ]) ifTrue: [
		aSetter
			setIn: aCarrier
			key: self class propagationHeaderName
			value: (String streamContents: [ :stream |
				stream
					nextPutAll: spanContext traceId;
					nextPut: $:;
					nextPutAll: spanContext spanId;
					nextPut: $:;
					nextPutAll: self class deprecatedParentSpanId;
					nextPut: $:;
					nextPutAll: (spanContext isSampled ifTrue: [ '1' ] ifFalse: [ '0' ]) ]) ].
	self injectBaggage: aContext baggage into: aCarrier setter: aSetter.
	^ self
]

{ #category : 'private' }
OTJaegerTextMapPropagator >> injectBaggage: aBaggage into: aCarrier setter: aSetter [

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
					aSetter
						setIn: aCarrier
						key: self class baggagePrefix, key
						value: value.
					entriesEmitted := entriesEmitted + 1.
					bytesEmitted := projectedBytes ] ] ] ].
	^ self
]

{ #category : 'private' }
OTJaegerTextMapPropagator >> isHexString: aString maxSize: anInteger [

	aString ifNil: [ ^ false ].
	(aString isEmpty or: [ aString size > anInteger ]) ifTrue: [ ^ false ].
	^ aString allSatisfy: [ :each |
		each isDigit or: [ 'abcdef' includes: each asLowercase ] ]
]

{ #category : 'private' }
OTJaegerTextMapPropagator >> normalizedPropagationHeaderFrom: aString [

	| header |
	aString ifNil: [ ^ nil ].
	header := aString asString trimBoth.
	header ifEmpty: [ ^ nil ].
	header := header copyReplaceAll: '%3A' with: ':'.
	header := header copyReplaceAll: '%3a' with: ':'.
	^ header asLowercase
]

{ #category : 'private' }
OTJaegerTextMapPropagator >> normalizedSpanIdFromJaeger: aString [

	| spanId padded |
	spanId := aString ifNil: [ ^ nil ] ifNotNil: [ aString asLowercase ].
	(self isHexString: spanId maxSize: 16) ifFalse: [ ^ nil ].
	padded := spanId padLeftTo: 16 with: $0.
	^ (OTSpan isZeroHexIdentifier: padded)
		ifTrue: [ nil ]
		ifFalse: [ padded ]
]

{ #category : 'private' }
OTJaegerTextMapPropagator >> normalizedTraceIdFromJaeger: aString [

	| traceId padded |
	traceId := aString ifNil: [ ^ nil ] ifNotNil: [ aString asLowercase ].
	(self isHexString: traceId maxSize: 32) ifFalse: [ ^ nil ].
	padded := traceId padLeftTo: 32 with: $0.
	^ (OTSpan isZeroHexIdentifier: padded)
		ifTrue: [ nil ]
		ifFalse: [ padded ]
]

{ #category : 'private' }
OTJaegerTextMapPropagator >> parseJaegerHeaderPartsFrom: aString [

	| header firstDelimiter secondDelimiter thirdDelimiter start |
	header := self normalizedPropagationHeaderFrom: aString.
	header ifNil: [ ^ nil ].
	firstDelimiter := header indexOf: $: ifAbsent: [ ^ nil ].
	secondDelimiter := header indexOf: $: startingAt: firstDelimiter + 1 ifAbsent: [ ^ nil ].
	thirdDelimiter := header indexOf: $: startingAt: secondDelimiter + 1 ifAbsent: [ ^ nil ].
	(header indexOf: $: startingAt: thirdDelimiter + 1 ifAbsent: [ 0 ]) > 0 ifTrue: [ ^ nil ].
	(firstDelimiter <= 1 or: [ secondDelimiter <= (firstDelimiter + 1) ]) ifTrue: [ ^ nil ].
	thirdDelimiter <= (secondDelimiter + 1) ifTrue: [ ^ nil ].
	start := thirdDelimiter + 1.
	start > header size ifTrue: [ ^ nil ].
	^ {
		header copyFrom: 1 to: firstDelimiter - 1.
		header copyFrom: firstDelimiter + 1 to: secondDelimiter - 1.
		header copyFrom: secondDelimiter + 1 to: thirdDelimiter - 1.
		header copyFrom: start to: header size }
]

{ #category : 'private' }
OTJaegerTextMapPropagator >> spanContextForTraceId: aTraceId spanId: aSpanId traceFlags: someTraceFlags [

	^ OTSpanContext
		traceId: aTraceId
		spanId: aSpanId
		traceFlags: someTraceFlags
		traceState: nil
		remote: true
]

{ #category : 'private' }
OTJaegerTextMapPropagator >> traceFlagsFromJaegerFlags: aString [

	| flagsValue |
	aString ifNil: [ ^ nil ].
	(aString isEmpty or: [ aString size > 2 ]) ifTrue: [ ^ nil ].
	(aString allSatisfy: [ :each | each isDigit ]) ifFalse: [ ^ nil ].
	flagsValue := Integer readFrom: aString readStream base: 10.
	^ ((flagsValue bitAnd: 1) = 1)
		ifTrue: [ '01' ]
		ifFalse: [ '00' ]
]
