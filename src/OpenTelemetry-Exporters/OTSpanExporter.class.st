"
I am a fundamental component within the OpenTelemetry framework that facilitates the export of recorded spans to external systems or backends.
Developers can implement custom subclasses to integrate OpenTelemetry with specific telemetry data consumers, enabling compatibility with various third-party systems.
"
Class {
	#name : #OTSpanExporter,
	#superclass : #Object,
	#classInstVars : [
		'instance'
	],
	#category : #'OpenTelemetry-Exporters'
}

{ #category : #accessing }
OTSpanExporter class >> instance [
instance := nil.
	^ instance ifNil: [ instance := self readConfiguration ]
]

{ #category : #accessing }
OTSpanExporter class >> readConfiguration [
	"Use defaults for now, later should use properties or env vars as explained in https://opentelemetry.io/docs/instrumentation/java/automatic/agent-config/#configuring-the-agent"

	| exporter |
	exporter := OTZipkinSpanExporter new.
	exporter httpClient request url
		host: 'localhost';
		port: 9411.
	^ exporter
]

{ #category : #exporting }
OTSpanExporter >> export: span [

	self subclassResponsibility
]
