"
A global singleton for the entrypoint to telemetry functionality for tracing.
"
Class {
	#name : 'OpenTelemetry',
	#superclass : 'Object',
	#classInstVars : [
		'localDirectoryName'
	],
	#category : 'OpenTelemetry-Instrumentation',
	#package : 'OpenTelemetry-Instrumentation'
}

{ #category : 'accessing' }
OpenTelemetry class >> b3MultiTextMapPropagator [

	^ OTB3TextMapPropagator multiHeader
]

{ #category : 'accessing' }
OpenTelemetry class >> b3TextMapPropagator [

	^ OTB3TextMapPropagator singleHeader
]

{ #category : 'accessing' }
OpenTelemetry class >> baggagePropagator [

	^ OTW3CBaggagePropagator current
]

{ #category : 'private' }
OpenTelemetry class >> configuredTextMapPropagator [

	| rawValue |
	rawValue := self environmentValueAt: 'OTEL_PROPAGATORS'.
	rawValue ifNil: [ ^ self defaultTextMapPropagator ].
	^ (self textMapPropagatorFromEnvironment: rawValue)
		ifNil: [ self defaultTextMapPropagator ]
		ifNotNil: [ :aPropagator | aPropagator ]
]

{ #category : 'accessing' }
OpenTelemetry class >> currentBaggage [

	^ self currentContext baggage
]

{ #category : 'accessing' }
OpenTelemetry class >> currentBaggage: aBaggage [

	^ self currentContext: ((self currentContext)
		withBaggage: (aBaggage ifNil: [ OTBaggage empty ] ifNotNil: [ aBaggage ]))
]

{ #category : 'accessing' }
OpenTelemetry class >> currentContext [

	^ OTSpan currentContext
]

{ #category : 'accessing' }
OpenTelemetry class >> currentContext: aContext [

	^ OTSpan currentContext: aContext
]

{ #category : 'accessing' }
OpenTelemetry class >> currentSpan [

	^ self currentContext span
]

{ #category : 'accessing' }
OpenTelemetry class >> currentSpan: aSpan [

	^ self currentContext: ((self currentContext)
		withSpan: aSpan)
]

{ #category : 'private' }
OpenTelemetry class >> defaultTextMapPropagator [

	^ self w3cTextMapPropagator
]

{ #category : 'private' }
OpenTelemetry class >> environmentValueAt: aString [

	| value |
	value := Smalltalk os environment at: aString ifAbsent: [ ^ nil ].
	value := value asString trimBoth.
	^ value isEmpty ifTrue: [ nil ] ifFalse: [ value ]
]

{ #category : 'accessing' }
OpenTelemetry class >> jaegerTextMapPropagator [

	^ OTJaegerTextMapPropagator new
]

{ #category : 'accessing' }
OpenTelemetry class >> otTraceTextMapPropagator [

	^ OTOtTraceTextMapPropagator new
]

{ #category : 'actions' }
OpenTelemetry class >> resetCurrentContext [

	OTSpan reset
]

{ #category : 'accessing' }
OpenTelemetry class >> textMapPropagator [

	^ OTTextMapPropagator currentOrNil ifNil: [
		OTTextMapPropagator current: self configuredTextMapPropagator ]
]

{ #category : 'accessing' }
OpenTelemetry class >> textMapPropagator: aPropagator [

	OTTextMapPropagator current: aPropagator
]

{ #category : 'private' }
OpenTelemetry class >> textMapPropagatorFromEnvironment: aString [

	| propagators seen |
	propagators := OrderedCollection new.
	seen := Set new.
	(aString substrings: ',') do: [ :each |
		| propagatorName propagator |
		propagatorName := each trimBoth.
		propagatorName isEmpty ifFalse: [
			propagatorName := propagatorName asLowercase.
			(seen includes: propagatorName) ifFalse: [
				propagator := self textMapPropagatorNamed: propagatorName.
				propagator ifNil: [ ^ nil ].
				seen add: propagatorName.
				propagators add: propagator ] ] ].
	^ OTTextMapPropagator compositeAll: propagators
]

{ #category : 'private' }
OpenTelemetry class >> textMapPropagatorNamed: aString [

	(aString sameAs: 'tracecontext') ifTrue: [ ^ self traceContextPropagator ].
	(aString sameAs: 'baggage') ifTrue: [ ^ self baggagePropagator ].
	(aString sameAs: 'b3') ifTrue: [ ^ self b3TextMapPropagator ].
	(aString sameAs: 'b3multi') ifTrue: [ ^ self b3MultiTextMapPropagator ].
	(aString sameAs: 'jaeger') ifTrue: [ ^ self jaegerTextMapPropagator ].
	(aString sameAs: 'xray') ifTrue: [ ^ self xrayTextMapPropagator ].
	(aString sameAs: 'ottrace') ifTrue: [ ^ self otTraceTextMapPropagator ].
	(aString sameAs: 'none') ifTrue: [ ^ OTTextMapPropagator noop ].
	^ nil
]

{ #category : 'accessing' }
OpenTelemetry class >> traceContextPropagator [

	^ OTW3CTraceContextPropagator current
]

{ #category : 'actions' }
OpenTelemetry class >> useBaggage: aBaggage during: aBlock [

	^ self
		useContext: ((self currentContext)
			withBaggage: (aBaggage ifNil: [ OTBaggage empty ] ifNotNil: [ aBaggage ]))
		during: aBlock
]

{ #category : 'actions' }
OpenTelemetry class >> useContext: aContext during: aBlock [

	| previousContext |
	previousContext := self currentContext.
	[ self currentContext: aContext.
	^ aBlock value ] ensure: [ self currentContext: previousContext ]
]

{ #category : 'actions' }
OpenTelemetry class >> useSpan: aSpan during: aBlock [

	^ self useContext: ((self currentContext) withSpan: aSpan) during: aBlock
]

{ #category : 'accessing' }
OpenTelemetry class >> w3cTextMapPropagator [

	^ OTTextMapPropagator compositeAll: {
		self traceContextPropagator.
		self baggagePropagator }
]

{ #category : 'accessing' }
OpenTelemetry class >> xrayTextMapPropagator [

	^ OTXRayTextMapPropagator new
]
