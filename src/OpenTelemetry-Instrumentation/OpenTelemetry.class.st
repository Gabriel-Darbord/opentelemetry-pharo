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

{ #category : 'actions' }
OpenTelemetry class >> attachContext: aContext [

	| context previousContext |
	previousContext := self currentContext.
	context := self currentContext: aContext.
	^ OTContextToken previousContext: previousContext attachedContext: context process: Processor activeProcess
]

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

	^ self currentContext: (self currentContext withBaggage: (aBaggage ifNil: [ OTBaggage empty ] ifNotNil: [ aBaggage ]))
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

	^ OTSpan current
]

{ #category : 'accessing' }
OpenTelemetry class >> currentSpan: aSpan [

	^ self currentContext: (self currentContext withSpan: aSpan)
]

{ #category : 'private - logging' }
OpenTelemetry class >> defaultPropagatorConfigurationWarningSink [

	^ OTDiagnosticLogger defaultWarningSink
]

{ #category : 'private' }
OpenTelemetry class >> defaultTextMapPropagator [

	^ self w3cTextMapPropagator
]

{ #category : 'actions' }
OpenTelemetry class >> detachContext: aContextToken [

	aContextToken ifNil: [ ^ false ].
	aContextToken isForActiveProcess ifFalse: [ ^ false ].
	(self currentContext == aContextToken attachedContext or: [
		 aContextToken attachedContext isEmpty and: [ self currentContext isEmpty ] ]) ifFalse: [ ^ false ].
	self currentContext: aContextToken previousContext.
	^ true
]

{ #category : 'private' }
OpenTelemetry class >> environmentValueAt: aString [

	^ OTConfigurationSource environmentValueAt: aString
]

{ #category : 'accessing' }
OpenTelemetry class >> jaegerTextMapPropagator [

	^ OTJaegerTextMapPropagator new
]

{ #category : 'private - logging' }
OpenTelemetry class >> notePropagatorNoneConflictIn: aString [

	self propagatorConfigurationWarningSink value:
		'OpenTelemetry propagator configuration mixes ''none'' with other propagators and has been ignored: ' , aString printString
]

{ #category : 'private - logging' }
OpenTelemetry class >> noteUnknownPropagatorName: aString [

	self propagatorConfigurationWarningSink value:
		'OpenTelemetry propagator name was unrecognized and has been ignored: ' , aString printString
]

{ #category : 'accessing' }
OpenTelemetry class >> otTraceTextMapPropagator [

	^ OTOtTraceTextMapPropagator new
]

{ #category : 'private' }
OpenTelemetry class >> propagatorConfigurationWarningSink [

	^ OTClassStateStore
		  valueAt: #otPropagatorConfigurationWarningSink
		  forClass: self
		  ifAbsent: [ self defaultPropagatorConfigurationWarningSink ]
]

{ #category : 'private - logging' }
OpenTelemetry class >> propagatorConfigurationWarningSink: aBlock [

	aBlock
		ifNil: [ OTClassStateStore removeValueAt: #otPropagatorConfigurationWarningSink forClass: self ifAbsent: [ ] ]
		ifNotNil: [ OTClassStateStore valueAt: #otPropagatorConfigurationWarningSink forClass: self put: aBlock ].
	^ self propagatorConfigurationWarningSink
]

{ #category : 'private' }
OpenTelemetry class >> propagatorNamesFromConfigurationValue: aString [

	| names seen |
	names := OrderedCollection new.
	seen := Set new.
	(aString substrings: ',') do: [ :each |
			| normalizedName propagatorName |
			propagatorName := each trimBoth.
			propagatorName isEmpty ifFalse: [
					normalizedName := propagatorName asLowercase.
					(seen includes: normalizedName) ifFalse: [
							(self textMapPropagatorNamed: normalizedName) ifNil: [
									self noteUnknownPropagatorName: propagatorName.
									^ nil ].
							seen add: normalizedName.
							names add: normalizedName ] ] ].
	names isEmpty ifTrue: [ ^ nil ].
	((names includes: 'none') and: [ names size > 1 ]) ifTrue: [
			self notePropagatorNoneConflictIn: aString.
			^ nil ].
	^ names asArray
]

{ #category : 'actions' }
OpenTelemetry class >> resetCurrentContext [

	OTSpan reset
]

{ #category : 'accessing' }
OpenTelemetry class >> textMapPropagator [

	^ OTTextMapPropagator currentOrNil ifNil: [ OTTextMapPropagator current: self configuredTextMapPropagator ]
]

{ #category : 'accessing' }
OpenTelemetry class >> textMapPropagator: aPropagator [

	OTTextMapPropagator current: aPropagator
]

{ #category : 'private' }
OpenTelemetry class >> textMapPropagatorFromEnvironment: aString [

	| propagatorNames |
	propagatorNames := self propagatorNamesFromConfigurationValue: aString.
	propagatorNames ifNil: [ ^ nil ].
	^ OTTextMapPropagator compositeAll: (propagatorNames collect: [ :each | self textMapPropagatorNamed: each ])
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

	^ self useContext: (self currentContext withBaggage: (aBaggage ifNil: [ OTBaggage empty ] ifNotNil: [ aBaggage ])) during: aBlock
]

{ #category : 'actions' }
OpenTelemetry class >> useContext: aContext during: aBlock [

	| token |
	token := self attachContext: aContext.
	[ ^ aBlock value ] ensure: [ self detachContext: token ]
]

{ #category : 'actions' }
OpenTelemetry class >> useSpan: aSpan during: aBlock [

	^ self useContext: (self currentContext withSpan: aSpan) during: aBlock
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
