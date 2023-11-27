"
I am a fundamental component within the OpenTelemetry framework that facilitates the export of recorded spans to external systems or backends.
Developers can implement custom subclasses to integrate OpenTelemetry with specific telemetry data consumers, enabling compatibility with various third-party systems.
"
Class {
	#name : #OTSpanExporter,
	#superclass : #Object,
	#classVars : [
		'Current'
	],
	#category : #'OpenTelemetry-Exporters'
}

{ #category : #'instance creation' }
OTSpanExporter class >> asCurrent [

	<script>
	^ Current := self new
]

{ #category : #accessing }
OTSpanExporter class >> current [

	^ Current ifNil: [ Current := self readConfiguration ]
]

{ #category : #accessing }
OTSpanExporter class >> current: aSpanExporter [

	Current := aSpanExporter
]

{ #category : #'instance creation' }
OTSpanExporter class >> defaultFileExporter [

	^ OTFileSpanExporter new
]

{ #category : #'instance creation' }
OTSpanExporter class >> defaultZipkinExporter [

	| exporter |
	exporter := OTZipkinSpanExporter new.
	exporter httpClient request url
		host: 'localhost';
		port: 9411.
	^ exporter
]

{ #category : #testing }
OTSpanExporter class >> isAbstract [

	^ self == OTSpanExporter
]

{ #category : #'instance creation' }
OTSpanExporter class >> readConfiguration [
	"Use defaults for now, later should use properties or env vars as explained in https://opentelemetry.io/docs/instrumentation/java/automatic/agent-config/#configuring-the-agent"

	^ self defaultFileExporter
]

{ #category : #'class initialization' }
OTSpanExporter class >> reset [

	<script>
	Current := nil
]

{ #category : #accessing }
OTSpanExporter >> beCurrent [

	^ Current := self
]

{ #category : #exporting }
OTSpanExporter >> export: spans [

	self subclassResponsibility
]
