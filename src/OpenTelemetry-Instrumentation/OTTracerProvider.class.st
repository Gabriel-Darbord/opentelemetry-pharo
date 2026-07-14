"
A backend-agnostic entry point to the tracing API. It owns Tracer instances and their shared configuration surface.
"
Class {
	#name : 'OTTracerProvider',
	#superclass : 'Object',
	#instVars : [
		'tracers'
	],
	#classVars : [
		'Current'
	],
	#category : 'OpenTelemetry-Instrumentation',
	#package : 'OpenTelemetry-Instrumentation'
}

{ #category : 'instance creation' }
OTTracerProvider class >> configuredResource [

	| attributes serviceName |
	attributes := self configuredResourceAttributes.
	serviceName := self environmentValueAt: 'OTEL_SERVICE_NAME'.
	serviceName ifNotNil: [ attributes at: 'service.name' put: serviceName ].
	^ attributes isEmpty
		ifTrue: [ OTResource empty ]
		ifFalse: [ OTResource attributes: attributes ]
]

{ #category : 'private' }
OTTracerProvider class >> configuredResourceAttributes [

	| rawValue |
	rawValue := self environmentValueAt: 'OTEL_RESOURCE_ATTRIBUTES'.
	rawValue ifNil: [ ^ OrderedDictionary new ].
	^ self resourceAttributesFromEnvironment: rawValue
]

{ #category : 'instance creation' }
OTTracerProvider class >> configuredSampler [

	| samplerName samplerArgument |
	samplerName := self environmentValueAt: 'OTEL_TRACES_SAMPLER'.
	samplerName ifNil: [ ^ self defaultSampler ].
	samplerArgument := self environmentValueAt: 'OTEL_TRACES_SAMPLER_ARG'.
	^ self samplerFromEnvironmentName: samplerName argument: samplerArgument
]

{ #category : 'private' }
OTTracerProvider class >> configuredServiceName [

	^ self environmentValueAt: 'OTEL_SERVICE_NAME'
]

{ #category : 'instance creation' }
OTTracerProvider class >> configuredSpanLimits [

	| defaultLimits generalAttributeCountLimit generalValueLengthLimit limits |
	defaultLimits := OTSpanLimits default.
	generalAttributeCountLimit := self integerEnvironmentValueAt: 'OTEL_ATTRIBUTE_COUNT_LIMIT' default: defaultLimits attributeCountLimit.
	generalValueLengthLimit := self integerEnvironmentValueAt: 'OTEL_ATTRIBUTE_VALUE_LENGTH_LIMIT' default: defaultLimits attributeValueLengthLimit.
	limits := OTSpanLimits default.
	limits
		attributeCountLimit: (self integerEnvironmentValueAt: 'OTEL_SPAN_ATTRIBUTE_COUNT_LIMIT' default: generalAttributeCountLimit);
		attributeValueLengthLimit: (self integerEnvironmentValueAt: 'OTEL_SPAN_ATTRIBUTE_VALUE_LENGTH_LIMIT' default: generalValueLengthLimit);
		eventCountLimit: (self integerEnvironmentValueAt: 'OTEL_SPAN_EVENT_COUNT_LIMIT' default: defaultLimits eventCountLimit);
		linkCountLimit: (self integerEnvironmentValueAt: 'OTEL_SPAN_LINK_COUNT_LIMIT' default: defaultLimits linkCountLimit);
		attributePerEventCountLimit: (self integerEnvironmentValueAt: 'OTEL_EVENT_ATTRIBUTE_COUNT_LIMIT' default: defaultLimits attributePerEventCountLimit);
		attributePerLinkCountLimit: (self integerEnvironmentValueAt: 'OTEL_LINK_ATTRIBUTE_COUNT_LIMIT' default: defaultLimits attributePerLinkCountLimit).
	^ limits
]

{ #category : 'accessing' }
OTTracerProvider class >> current [

	^ Current ifNil: [ Current := self readConfiguration ]
]

{ #category : 'accessing' }
OTTracerProvider class >> current: aTracerProvider [

	Current := aTracerProvider
]

{ #category : 'class initialization' }
OTTracerProvider class >> reset [

	Current ifNotNil: [ Current shutdown ].
	Current := nil
]

{ #category : 'tracing' }
OTTracerProvider >> nonRecordingSpanIn: aContext [

	| baseContext span |
	baseContext := aContext ifNil: [ OTContext new ] ifNotNil: [ aContext ].
	span := OTSpan wrapping: OTSpanContext invalid.
	span
		context: (baseContext withSpan: span);
		instrumentationScope: (OTInstrumentationScope named: '');
		resource: self resource.
	^ span
]

{ #category : 'accessing' }
OTTracerProvider >> spanLimits [

	^ ((self ensureLifecycleState) at: #spanLimits) copy
]

{ #category : 'accessing' }
OTTracerProvider >> spanProcessor: aSpanProcessor [

	(self ensureLifecycleState)
		at: #spanProcessors
		put: (OrderedCollection with: aSpanProcessor).
	^ aSpanProcessor
]

{ #category : 'tracing' }
OTTracerProvider >> tracerNamed: aString [

	^ self tracerNamed: aString version: '' schemaUrl: '' attributes: #()
]
