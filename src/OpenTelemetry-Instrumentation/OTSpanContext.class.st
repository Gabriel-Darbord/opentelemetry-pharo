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

	^ self
		traceId: aSpan traceId
		spanId: aSpan spanId
		traceFlags: aSpan traceFlags
		traceState: aSpan traceState
		remote: false
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

{ #category : 'private' }
OTSpanContext class >> normalizedHexIdentifier: anIdentifier size: anInteger label: aLabelString [

	| normalized |
	anIdentifier ifNil: [ ^ nil ].
	normalized := anIdentifier asString asLowercase.
	(self isLowercaseHexString: normalized size: anInteger) ifFalse: [
		Error signal: aLabelString , ' must be a ' , anInteger asString , '-character lowercase hex string' ].
	^ normalized
]

{ #category : 'private' }
OTSpanContext class >> normalizedTraceFlags: someTraceFlags [

	| normalized |
	someTraceFlags ifNil: [ ^ nil ].
	normalized := someTraceFlags asString asLowercase.
	(self isLowercaseHexString: normalized size: 2) ifFalse: [
		Error signal: 'TraceFlags must be a 2-character lowercase hex string' ].
	^ normalized
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

	^ self new
		traceId: aTraceId;
		spanId: aSpanId;
		traceFlags: someTraceFlags;
		traceState: aTraceState;
		remote: aBoolean;
		yourself
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
OTSpanContext >> asNonRecordingSpan [

	^ OTSpan wrapping: self
]

{ #category : 'comparing' }
OTSpanContext >> hash [

	^ { self traceId. self spanId. self traceFlags. self traceState. self isRemote } hash
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
OTSpanContext >> remote: aBoolean [

	remote := aBoolean = true
]

{ #category : 'accessing' }
OTSpanContext >> spanId [

	^ spanId ifNil: [ self class invalidSpanId ]
]

{ #category : 'private' }
OTSpanContext >> spanId: aSpanId [

	spanId := self class normalizedHexIdentifier: aSpanId size: 16 label: 'SpanId'
]

{ #category : 'accessing' }
OTSpanContext >> spanIdBytes [

	^ self class byteArrayFromHex: self spanId size: 8
]

{ #category : 'accessing' }
OTSpanContext >> spanIdHex [

	^ self spanId
]

{ #category : 'accessing' }
OTSpanContext >> traceFlags [

	^ traceFlags ifNil: [ '00' ]
]

{ #category : 'private' }
OTSpanContext >> traceFlags: someTraceFlags [

	traceFlags := self class normalizedTraceFlags: someTraceFlags
]

{ #category : 'accessing' }
OTSpanContext >> traceId [

	^ traceId ifNil: [ self class invalidTraceId ]
]

{ #category : 'private' }
OTSpanContext >> traceId: aTraceId [

	traceId := self class normalizedHexIdentifier: aTraceId size: 32 label: 'TraceId'
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

{ #category : 'private' }
OTSpanContext >> traceState: aTraceState [

	traceState := aTraceState
]
