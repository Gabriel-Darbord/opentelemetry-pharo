"
An AWS X-Ray text-map propagator that extracts and injects the X-Amzn-Trace-Id header format.
"
Class {
	#name : 'OTXRayTextMapPropagator',
	#superclass : 'OTTextMapPropagator',
	#category : 'OpenTelemetry-Instrumentation',
	#package : 'OpenTelemetry-Instrumentation'
}

{ #category : 'accessing' }
OTXRayTextMapPropagator class >> parentMemberName [

	^ 'Parent'
]

{ #category : 'accessing' }
OTXRayTextMapPropagator class >> propagationHeaderName [

	^ 'X-Amzn-Trace-Id'
]

{ #category : 'class initialization' }
OTXRayTextMapPropagator class >> reset [

	^ self
]

{ #category : 'accessing' }
OTXRayTextMapPropagator class >> rootMemberName [

	^ 'Root'
]

{ #category : 'accessing' }
OTXRayTextMapPropagator class >> sampledMemberName [

	^ 'Sampled'
]

{ #category : 'accessing' }
OTXRayTextMapPropagator class >> traceIdVersion [

	^ '1'
]

{ #category : 'extracting' }
OTXRayTextMapPropagator >> extract: aContext from: aCarrier [

	^ self extract: aContext from: aCarrier getter: OTDictionaryTextMapGetter current
]

{ #category : 'extracting' }
OTXRayTextMapPropagator >> extract: aContext from: aCarrier getter: aGetter [

	| baseContext spanContext |
	baseContext := aContext ifNil: [ OTContext new ] ifNotNil: [ aContext ].
	aGetter ifNil: [ ^ baseContext ].
	spanContext := self extractSpanContextFromHeader:
		               (self headerValueIn: self class propagationHeaderName from: aCarrier getter: aGetter).
	^ spanContext ifNil: [ baseContext ] ifNotNil: [ baseContext withSpan: spanContext asNonRecordingSpan ]
]

{ #category : 'private' }
OTXRayTextMapPropagator >> extractSpanContextFromHeader: aString [

	| members traceId spanId traceFlags |
	members := self memberDictionaryFromHeader: aString.
	members ifNil: [ ^ nil ].
	traceId := self normalizedTraceIdFromRoot: (members at: self class rootMemberName asLowercase ifAbsent: [ nil ]).
	traceId ifNil: [ ^ nil ].
	spanId := self normalizedParentSpanId: (members at: self class parentMemberName asLowercase ifAbsent: [ nil ]).
	spanId ifNil: [ ^ nil ].
	traceFlags := self traceFlagsFromSampledValue: (members at: self class sampledMemberName asLowercase ifAbsent: [ nil ]).
	traceFlags ifNil: [ ^ nil ].
	^ OTSpanContext
		  traceId: traceId
		  spanId: spanId
		  traceFlags: traceFlags
		  traceState: nil
		  remote: true
]

{ #category : 'accessing' }
OTXRayTextMapPropagator >> fields [

	^ { self class propagationHeaderName }
]

{ #category : 'private' }
OTXRayTextMapPropagator >> headerStringFrom: anObject [

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
OTXRayTextMapPropagator >> headerValueIn: aHeaderName from: aCarrier getter: aGetter [

	^ self headerStringFrom: (aGetter getFrom: aCarrier key: aHeaderName)
]

{ #category : 'injecting' }
OTXRayTextMapPropagator >> inject: aContext into: aCarrier [

	^ self inject: aContext into: aCarrier setter: OTDictionaryTextMapSetter current
]

{ #category : 'injecting' }
OTXRayTextMapPropagator >> inject: aContext into: aCarrier setter: aSetter [

	| spanContext root sampleValue |
	(aContext isNil or: [ aSetter isNil ]) ifTrue: [ ^ self ].
	spanContext := aContext span ifNotNil: [ :span | span spanContext ].
	(spanContext isNil or: [ spanContext isValid not ]) ifTrue: [ ^ self ].
	root := self xrayRootFromTraceId: spanContext traceId.
	root ifNil: [ ^ self ].
	sampleValue := spanContext isSampled
		               ifTrue: [ '1' ]
		               ifFalse: [ '0' ].
	aSetter setIn: aCarrier key: self class propagationHeaderName value: (String streamContents: [ :stream |
				 stream
					 nextPutAll: 'Root=';
					 nextPutAll: root;
					 nextPutAll: ';Parent=';
					 nextPutAll: spanContext spanId;
					 nextPutAll: ';Sampled=';
					 nextPutAll: sampleValue ])
]

{ #category : 'private' }
OTXRayTextMapPropagator >> isLowercaseHexString: aString size: anInteger [

	aString ifNil: [ ^ false ].
	aString size = anInteger ifFalse: [ ^ false ].
	^ aString allSatisfy: [ :each | each isDigit or: [ 'abcdef' includes: each ] ]
]

{ #category : 'private' }
OTXRayTextMapPropagator >> memberDictionaryFromHeader: aString [

	| header members |
	aString ifNil: [ ^ nil ].
	header := aString trimBoth.
	header ifEmpty: [ ^ nil ].
	members := Dictionary new.
	(header substrings: ';') do: [ :each |
			| member separator key value |
			member := each trimBoth.
			member isEmpty ifFalse: [
					separator := member indexOf: $= ifAbsent: [ 0 ].
					(separator > 1 and: [ separator < member size ]) ifTrue: [
							key := (member copyFrom: 1 to: separator - 1) trimBoth asLowercase.
							value := (member copyFrom: separator + 1 to: member size) trimBoth.
							value isEmpty ifFalse: [ members at: key put: value ] ] ] ].
	^ members
]

{ #category : 'private' }
OTXRayTextMapPropagator >> normalizedParentSpanId: aString [

	| spanId |
	aString ifNil: [ ^ nil ].
	spanId := aString asLowercase.
	(self isLowercaseHexString: spanId size: 16) ifFalse: [ ^ nil ].
	^ (OTSpanContext isZeroHexIdentifier: spanId)
		  ifTrue: [ nil ]
		  ifFalse: [ spanId ]
]

{ #category : 'private' }
OTXRayTextMapPropagator >> normalizedTraceIdFromRoot: aString [

	| separatorPositions timestamp random |
	aString ifNil: [ ^ nil ].
	separatorPositions := OrderedCollection new.
	1 to: aString size do: [ :index | (aString at: index) = $- ifTrue: [ separatorPositions add: index ] ].
	separatorPositions asArray = #( 2 11 ) ifFalse: [ ^ nil ].
	timestamp := aString copyFrom: 3 to: 10.
	random := aString copyFrom: 12 to: aString size.
	(self isLowercaseHexString: timestamp size: 8) ifFalse: [ ^ nil ].
	(self isLowercaseHexString: random size: 24) ifFalse: [ ^ nil ].
	^ (OTSpanContext isZeroHexIdentifier: timestamp , random)
		  ifTrue: [ nil ]
		  ifFalse: [ timestamp , random ]
]

{ #category : 'private' }
OTXRayTextMapPropagator >> traceFlagsFromSampledValue: aString [

	aString ifNil: [ ^ nil ].
	aString = '1' ifTrue: [ ^ '01' ].
	aString = '0' ifTrue: [ ^ '00' ].
	^ nil
]

{ #category : 'private' }
OTXRayTextMapPropagator >> xrayRootFromTraceId: aString [

	| traceId timestamp random |
	aString ifNil: [ ^ nil ].
	traceId := aString asLowercase.
	(self isLowercaseHexString: traceId size: 32) ifFalse: [ ^ nil ].
	(OTSpanContext isZeroHexIdentifier: traceId) ifTrue: [ ^ nil ].
	timestamp := traceId copyFrom: 1 to: 8.
	random := traceId copyFrom: 9 to: 32.
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: self class traceIdVersion;
				  nextPut: $-;
				  nextPutAll: timestamp;
				  nextPut: $-;
				  nextPutAll: random ]
]
