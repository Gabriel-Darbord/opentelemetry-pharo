"
A backend-agnostic tracer responsible for creating spans for one instrumentation scope.
"
Class {
	#name : 'OTTracer',
	#superclass : 'Object',
	#instVars : [
		'provider',
		'instrumentationName',
		'instrumentationScope',
		'tracerConfig'
	],
	#category : 'OpenTelemetry-Instrumentation',
	#package : 'OpenTelemetry-Instrumentation'
}

{ #category : 'instance creation' }
OTTracer class >> forProvider: aTracerProvider instrumentationName: aString [

	^ self forProvider: aTracerProvider instrumentationScope: (OTInstrumentationScope named: aString)
]

{ #category : 'instance creation' }
OTTracer class >> forProvider: aTracerProvider instrumentationScope: anInstrumentationScope [

	| tracer |
	tracer := self new.
	tracer
		provider: aTracerProvider;
		instrumentationScope: anInstrumentationScope.
	^ tracer
]

{ #category : 'tracing' }
OTTracer >> enabled [

	^ provider ifNil: [ false ] ifNotNil: [ provider tracerEnabled: self ]
]

{ #category : 'tracing' }
OTTracer >> enabledForSpanNamed: aString kind: aSpanKind in: aContext attributes: someAttributes links: someLinks [

	^ self enabled
]

{ #category : 'accessing' }
OTTracer >> instrumentationName [

	^ self instrumentationScope name
]

{ #category : 'accessing' }
OTTracer >> instrumentationName: aString [

	^ self instrumentationScope: (OTInstrumentationScope named: aString)
]

{ #category : 'accessing' }
OTTracer >> instrumentationScope [

	instrumentationScope ifNil: [ instrumentationScope := OTInstrumentationScope named: (instrumentationName ifNil: [ '' ]) ].
	^ instrumentationScope
]

{ #category : 'accessing' }
OTTracer >> instrumentationScope: anInstrumentationScope [

	| scope |
	scope := anInstrumentationScope ifNil: [ OTInstrumentationScope named: '' ] ifNotNil: [
			         (anInstrumentationScope isKindOf: OTInstrumentationScope)
				         ifTrue: [ anInstrumentationScope ]
				         ifFalse: [
						         OTSpan noteIgnoredInvalidArgument: anInstrumentationScope forOperation: 'OTTracer>>instrumentationScope:'.
						         OTInstrumentationScope named: '' ] ].
	instrumentationScope := scope.
	instrumentationName := scope name.
	^ scope
]

{ #category : 'accessing' }
OTTracer >> instrumentationVersion [

	^ self instrumentationScope version
]

{ #category : 'private' }
OTTracer >> parentSpanFrom: aContext [

	| parentSpan |
	aContext ifNil: [ ^ nil ].
	(aContext isKindOf: OTContext) ifFalse: [
			OTSpan noteIgnoredInvalidArgument: aContext forOperation: 'OTTracer>>parentSpanFrom:'.
			^ nil ].
	parentSpan := aContext span.
	parentSpan ifNil: [ ^ nil ].
	^ parentSpan spanContext isValid
		  ifTrue: [ parentSpan ]
		  ifFalse: [ nil ]
]

{ #category : 'accessing' }
OTTracer >> provider [

	^ provider
]

{ #category : 'accessing' }
OTTracer >> provider: aTracerProvider [

	provider := aTracerProvider
]

{ #category : 'accessing' }
OTTracer >> schemaUrl [

	^ self instrumentationScope schemaUrl
]

{ #category : 'accessing' }
OTTracer >> scopeAttributes [

	^ self instrumentationScope allAttributes
]

{ #category : 'tracing' }
OTTracer >> spanBuilderNamed: aString [

	(provider isNil or: [ provider isStopping ]) ifTrue: [ ^ OTNoopSpanBuilder forTracer: self name: aString ].
	^ OTSpanBuilder forTracer: self name: aString
]

{ #category : 'tracing' }
OTTracer >> startSpanNamed: aString [

	^ self startSpanNamed: aString kind: OTSpan internal
]

{ #category : 'tracing' }
OTTracer >> startSpanNamed: aString in: aContext [

	^ self startSpanNamed: aString kind: OTSpan internal in: aContext
]

{ #category : 'tracing' }
OTTracer >> startSpanNamed: aString kind: aSpanKind [

	| builder |
	builder := self spanBuilderNamed: aString.
	builder kind: aSpanKind.
	^ builder startSpan
]

{ #category : 'tracing' }
OTTracer >> startSpanNamed: aString kind: aSpanKind in: aContext [

	| builder |
	builder := self spanBuilderNamed: aString.
	builder
		kind: aSpanKind;
		inContext: aContext.
	^ builder startSpan
]

{ #category : 'accessing' }
OTTracer >> tracerConfig [

	tracerConfig ifNil: [ tracerConfig := OTTracerConfig default ].
	^ tracerConfig
]

{ #category : 'accessing' }
OTTracer >> tracerConfig: anOTTracerConfig [

	tracerConfig := anOTTracerConfig ifNil: [ OTTracerConfig default ] ifNotNil: [ anOTTracerConfig ].
	^ tracerConfig
]
