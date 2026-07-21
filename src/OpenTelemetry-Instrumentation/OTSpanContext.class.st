"
An immutable tracing identity value suitable for propagation and backend-neutral span parenting.
"
Class {
	#name : 'OTSpanContext',
	#superclass : 'Object',
	#instVars : [
		'traceId',
		'spanId',
		'traceFlags',
		'traceState',
		'remote'
	],
	#category : 'OpenTelemetry-Instrumentation',
	#package : 'OpenTelemetry-Instrumentation'
}

{ #category : 'private' }
OTSpanContext class >> byteArrayFromHex: aString size: anInteger [

	| bytes |
	bytes := ByteArray new: anInteger.
	1 to: anInteger do: [ :index |
		| start |
		start := ((index - 1) * 2) + 1.
		bytes
			at: index
			put: (Integer
				readFrom: ((aString copyFrom: start to: start + 1) readStream)
				base: 16) ].
	^ bytes
]

{ #category : 'instance creation' }
OTSpanContext class >> fromSpan: aSpan [

	^ aSpan spanContext
]

{ #category : 'ston persistence' }
OTSpanContext class >> fromSton: stonReader [

	| representation |
	representation := stonReader parseMap.
	^ self
		  traceId: (representation at: #traceId)
		  spanId: (representation at: #spanId)
		  traceFlags: (representation at: #traceFlags ifAbsent: [ '00' ])
		  traceState: (representation at: #traceState ifAbsent: [ nil ])
		  remote: (representation at: #remote ifAbsent: [ false ])
]

{ #category : 'private' }
OTSpanContext class >> hexFromByteArray: aByteArray size: anInteger label: aLabelString [

	(aByteArray isKindOf: ByteArray) ifFalse: [
			OTSpan noteIgnoredInvalidArgument: aByteArray forOperation: 'OTSpanContext class>>hexFromByteArray:size:label:'.
			^ self invalidHexIdentifierOfSize: anInteger * 2 ].
	aByteArray size = anInteger ifFalse: [
			OTSpan noteIgnoredInvalidArgument: aByteArray forOperation: 'OTSpanContext class>>hexFromByteArray:size:label:'.
			^ self invalidHexIdentifierOfSize: anInteger * 2 ].
	^ String streamContents: [ :stream |
			  aByteArray do: [ :each |
					  stream
						  nextPut: ('0123456789abcdef' at: ((each bitShift: -4) bitAnd: 16rF) + 1);
						  nextPut: ('0123456789abcdef' at: (each bitAnd: 16rF) + 1) ] ]
]

{ #category : 'instance creation' }
OTSpanContext class >> invalid [

	^ self
		traceId: self invalidTraceId
		spanId: self invalidSpanId
		traceFlags: '00'
		traceState: nil
		remote: false
]

{ #category : 'private' }
OTSpanContext class >> invalidHexIdentifierOfSize: anInteger [

	anInteger = 32 ifTrue: [ ^ self invalidTraceId ].
	anInteger = 16 ifTrue: [ ^ self invalidSpanId ].
	^ String new: anInteger withAll: $0
]

{ #category : 'private' }
OTSpanContext class >> invalidSpanId [

	^ String new: 16 withAll: $0
]

{ #category : 'private' }
OTSpanContext class >> invalidTraceId [

	^ String new: 32 withAll: $0
]

{ #category : 'private' }
OTSpanContext class >> isLowercaseHexString: aString size: anInteger [

	aString ifNil: [ ^ false ].
	aString size = anInteger ifFalse: [ ^ false ].
	^ aString allSatisfy: [ :each |
		each isDigit or: [ 'abcdef' includes: each ] ]
]

{ #category : 'private - id generation' }
OTSpanContext class >> isZeroHexIdentifier: aString [

	^ aString allSatisfy: [ :each | each = $0 ]
]

{ #category : 'instance creation' }
OTSpanContext class >> new [

	Error signal: 'Span contexts are immutable. Use OTSpanContext class-side constructors.'
]

{ #category : 'private - id generation' }
OTSpanContext class >> newHexIdentifierOfSize: anInteger [

	| identifier |
	[
		identifier := String streamContents: [ :stream |
			anInteger timesRepeat: [
				stream nextPut: self randomHexDigit ] ].
		self isZeroHexIdentifier: identifier ] whileTrue.
	^ identifier
]

{ #category : 'private' }
OTSpanContext class >> newInternal [

	^ super new
]

{ #category : 'private - id generation' }
OTSpanContext class >> newSpanId [

	^ self newHexIdentifierOfSize: 16
]

{ #category : 'private - id generation' }
OTSpanContext class >> newTraceId [

	^ self newHexIdentifierOfSize: 32
]

{ #category : 'private' }
OTSpanContext class >> normalizedHexIdentifier: anIdentifier size: anInteger label: aLabelString [

	| normalized |
	anIdentifier ifNil: [ ^ self invalidHexIdentifierOfSize: anInteger ].
	normalized := anIdentifier asString asLowercase.
	(self isLowercaseHexString: normalized size: anInteger) ifTrue: [ ^ normalized ].
	OTSpan noteIgnoredInvalidArgument: anIdentifier forOperation: 'OTSpanContext class>>normalizedHexIdentifier:size:label:'.
	^ self invalidHexIdentifierOfSize: anInteger
]

{ #category : 'private' }
OTSpanContext class >> normalizedTraceFlags: someTraceFlags [

	| normalized |
	someTraceFlags ifNil: [ ^ '00' ].
	normalized := someTraceFlags asString asLowercase.
	(self isLowercaseHexString: normalized size: 2) ifTrue: [ ^ normalized ].
	OTSpan noteIgnoredInvalidArgument: someTraceFlags forOperation: 'OTSpanContext class>>normalizedTraceFlags:'.
	^ '00'
]

{ #category : 'private - id generation' }
OTSpanContext class >> randomHexDigit [

	^ '0123456789abcdef' at: (SharedRandom globalGenerator nextInteger: 16)
]

{ #category : 'instance creation' }
OTSpanContext class >> traceId: aTraceId spanId: aSpanId [

	^ self
		traceId: aTraceId
		spanId: aSpanId
		traceFlags: '00'
		traceState: nil
		remote: false
]

{ #category : 'instance creation' }
OTSpanContext class >> traceId: aTraceId spanId: aSpanId traceFlags: someTraceFlags traceState: aTraceState remote: aBoolean [

	^ self newInternal
		  restoreTraceId: aTraceId;
		  restoreSpanId: aSpanId;
		  restoreTraceFlags: someTraceFlags;
		  restoreTraceState: aTraceState;
		  restoreRemote: aBoolean;
		  yourself
]

{ #category : 'instance creation' }
OTSpanContext class >> traceIdBytes: aTraceIdByteArray spanIdBytes: aSpanIdByteArray traceFlags: someTraceFlags traceState: aTraceState remote: aBoolean [

	^ self
		traceId: (self hexFromByteArray: aTraceIdByteArray size: 16 label: 'TraceId')
		spanId: (self hexFromByteArray: aSpanIdByteArray size: 8 label: 'SpanId')
		traceFlags: someTraceFlags
		traceState: aTraceState
		remote: aBoolean
]

{ #category : 'comparing' }
OTSpanContext >> = anObject [

	self == anObject ifTrue: [ ^ true ].
	anObject class == self class ifFalse: [ ^ false ].
	^ self traceId = anObject traceId
		and: [ self spanId = anObject spanId
		and: [ self traceFlags = anObject traceFlags
		and: [ self traceState = anObject traceState
		and: [ self isRemote = anObject isRemote ] ] ] ]
]

{ #category : 'converting' }
OTSpanContext >> asLocal [

	^ self withRemote: false
]

{ #category : 'converting' }
OTSpanContext >> asNonRecordingSpan [

	^ OTSpan wrapping: self
]

{ #category : 'converting' }
OTSpanContext >> asRemote [

	^ self withRemote: true
]

{ #category : 'converting' }
OTSpanContext >> asSpanContext [

	^ self
]

{ #category : 'comparing' }
OTSpanContext >> hash [

	^ { self traceId. self spanId. self traceFlags. self traceState. self isRemote } hash
]

{ #category : 'testing' }
OTSpanContext >> isRandom [

	^ ((Integer readFrom: self traceFlags readStream base: 16) bitAnd: 2) = 2
]

{ #category : 'testing' }
OTSpanContext >> isRemote [

	^ remote = true
]

{ #category : 'testing' }
OTSpanContext >> isSampled [

	^ ((Integer readFrom: self traceFlags readStream base: 16) bitAnd: 1) = 1
]

{ #category : 'testing' }
OTSpanContext >> isValid [

	^ (self traceId anySatisfy: [ :each | each ~= $0 ])
		and: [ self spanId anySatisfy: [ :each | each ~= $0 ] ]
]

{ #category : 'private' }
OTSpanContext >> restoreRemote: aBoolean [

	remote := aBoolean = true
]

{ #category : 'private' }
OTSpanContext >> restoreSpanId: aSpanId [

	spanId := self class normalizedHexIdentifier: aSpanId size: 16 label: 'SpanId'
]

{ #category : 'private' }
OTSpanContext >> restoreTraceFlags: someTraceFlags [

	traceFlags := self class normalizedTraceFlags: someTraceFlags
]

{ #category : 'private' }
OTSpanContext >> restoreTraceId: aTraceId [

	traceId := self class normalizedHexIdentifier: aTraceId size: 32 label: 'TraceId'
]

{ #category : 'private' }
OTSpanContext >> restoreTraceState: aTraceState [

	traceState := OTTraceState from: aTraceState
]

{ #category : 'accessing' }
OTSpanContext >> spanId [

	^ spanId ifNil: [ self class invalidSpanId ]
]

{ #category : 'accessing' }
OTSpanContext >> spanIdBytes [

	^ self class byteArrayFromHex: self spanId size: 8
]

{ #category : 'accessing' }
OTSpanContext >> spanIdHex [

	^ self spanId
]

{ #category : 'ston persistence' }
OTSpanContext >> stonOn: stonWriter [

	stonWriter writeObject: self streamMap: [ :map |
			map
				at: #traceId put: self traceId;
				at: #spanId put: self spanId;
				at: #traceFlags put: self traceFlags;
				at: #remote put: self isRemote.
			self traceState ifNotNil: [ :aTraceState | map at: #traceState put: aTraceState asHeaderValue ] ]
]

{ #category : 'accessing' }
OTSpanContext >> traceFlags [

	^ traceFlags ifNil: [ '00' ]
]

{ #category : 'accessing' }
OTSpanContext >> traceId [

	^ traceId ifNil: [ self class invalidTraceId ]
]

{ #category : 'accessing' }
OTSpanContext >> traceIdBytes [

	^ self class byteArrayFromHex: self traceId size: 16
]

{ #category : 'accessing' }
OTSpanContext >> traceIdHex [

	^ self traceId
]

{ #category : 'accessing' }
OTSpanContext >> traceState [

	^ traceState
]

{ #category : 'copying' }
OTSpanContext >> withRemote: aBoolean [

	^ self class
		traceId: self traceId
		spanId: self spanId
		traceFlags: self traceFlags
		traceState: self traceState
		remote: aBoolean
]

{ #category : 'copying' }
OTSpanContext >> withTraceFlags: someTraceFlags [

	^ self class
		traceId: self traceId
		spanId: self spanId
		traceFlags: someTraceFlags
		traceState: self traceState
		remote: self isRemote
]

{ #category : 'copying' }
OTSpanContext >> withTraceState: aTraceState [

	^ self class
		traceId: self traceId
		spanId: self spanId
		traceFlags: self traceFlags
		traceState: aTraceState
		remote: self isRemote
]
