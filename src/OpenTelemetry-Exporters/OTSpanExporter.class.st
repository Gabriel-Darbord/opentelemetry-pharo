"
I am a fundamental component within the OpenTelemetry framework that facilitates the export of recorded spans to external systems or backends.
Developers can implement custom subclasses to integrate OpenTelemetry with specific telemetry data consumers, enabling compatibility with various third-party systems.
"
Class {
	#name : 'OTSpanExporter',
	#superclass : 'Object',
	#classVars : [
		'Current'
	],
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'instance creation' }
OTSpanExporter class >> beCurrent [

	<script>
	self isAbstract
		ifTrue: [ Error signal: self name , ' is abstract' ]
		ifFalse: [
			^ self == Current class
				  ifTrue: [ Current ]
				  ifFalse: [ Current := self new ] ]
]

{ #category : 'accessing' }
OTSpanExporter class >> current [

	^ Current ifNil: [ Current := self readConfiguration ]
]

{ #category : 'accessing' }
OTSpanExporter class >> current: aSpanExporter [

	Current := aSpanExporter
]

{ #category : 'instance creation' }
OTSpanExporter class >> defaultFileExporter [

	^ OTJSONFileSpanExporter new
]

{ #category : 'instance creation' }
OTSpanExporter class >> defaultZipkinExporter [

	| exporter |
	exporter := OTZipkinSpanExporter new.
	exporter httpClient request url
		host: 'localhost';
		port: 9411.
	^ exporter
]

{ #category : 'exporting' }
OTSpanExporter class >> forceFlush [

	<script>
	^ Current ifNil: [ false ] ifNotNil: [ Current forceFlush ]
]

{ #category : 'testing' }
OTSpanExporter class >> isAbstract [

	^ self == OTSpanExporter
]

{ #category : 'private - lifecycle' }
OTSpanExporter class >> isShutdown: anExporter [

	^ (self lifecycleStateByExporter at: anExporter ifAbsent: [ false ]) = true
]

{ #category : 'private - lifecycle' }
OTSpanExporter class >> lifecycleStateByExporter [

	^ OTSpanExporter
		propertyAt: #otLifecycleStateByExporter
		ifAbsent: [
			| states |
			states := WeakIdentityKeyDictionary new.
			OTSpanExporter propertyAt: #otLifecycleStateByExporter put: states.
			states ]
]

{ #category : 'private - lifecycle' }
OTSpanExporter class >> markShutdown: anExporter [

	self lifecycleStateByExporter at: anExporter put: true.
	^ anExporter
]

{ #category : 'instance creation' }
OTSpanExporter class >> readConfiguration [
	"Use defaults for now, later should use properties or env vars as explained in https://opentelemetry.io/docs/instrumentation/java/automatic/agent-config/#configuring-the-agent"

	^ self defaultFileExporter
]

{ #category : 'class initialization' }
OTSpanExporter class >> reset [

	<script>
	self shutdown.
	self resetLifecycleState.
	Current := nil
]

{ #category : 'private - lifecycle' }
OTSpanExporter class >> resetLifecycleState [

	self removeProperty: #otLifecycleStateByExporter ifAbsent: [  ]
]

{ #category : 'exporting' }
OTSpanExporter class >> shutdown [

	<script>
	^ Current ifNil: [ false ] ifNotNil: [ Current shutdown ]
]

{ #category : 'accessing' }
OTSpanExporter >> beCurrent [

	^ Current := self
]

{ #category : 'exporting' }
OTSpanExporter >> export: spans [

	self subclassResponsibility
]

{ #category : 'exporting' }
OTSpanExporter >> forceFlush [

	^ self isShutdown not
]

{ #category : 'testing' }
OTSpanExporter >> isShutdown [

	^ self class isShutdown: self
]

{ #category : 'private - lifecycle' }
OTSpanExporter >> markShutdown [

	self class markShutdown: self.
	^ self
]

{ #category : 'exporting' }
OTSpanExporter >> shutdown [

	self isShutdown ifTrue: [ ^ false ].
	self markShutdown.
	^ true
]
