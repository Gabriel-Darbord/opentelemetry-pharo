"
I am a fundamental component within the OpenTelemetry framework that facilitates the export of recorded spans to external systems or backends.
Developers can implement custom subclasses to integrate OpenTelemetry with specific telemetry data consumers, enabling compatibility with various third-party systems.
"
Class {
	#name : 'OTSpanExporter',
	#superclass : 'Object',
	#classVars : [
		'Instance'
	],
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'accessing' }
OTSpanExporter class >> defaultFileExporter [

	^ OTFileSpanExporter new
]

{ #category : 'accessing' }
OTSpanExporter class >> defaultZipkinExporter [

	| exporter |
	exporter := OTZipkinSpanExporter new.
	exporter httpClient request url
		host: 'localhost';
		port: 9411.
	^ exporter
]

{ #category : 'accessing' }
OTSpanExporter class >> instance [

	^ Instance ifNil: [ Instance := self readConfiguration ]
]

{ #category : 'accessing' }
OTSpanExporter class >> instance: aSpanExporter [

	Instance := aSpanExporter
]

{ #category : 'accessing' }
OTSpanExporter class >> readConfiguration [
	"Use defaults for now, later should use properties or env vars as explained in https://opentelemetry.io/docs/instrumentation/java/automatic/agent-config/#configuring-the-agent"

	^ self defaultFileExporter
]

{ #category : 'class initialization' }
OTSpanExporter class >> reset [

	Instance := nil
]

{ #category : 'exporting' }
OTSpanExporter >> export: spans [

	self subclassResponsibility
]
