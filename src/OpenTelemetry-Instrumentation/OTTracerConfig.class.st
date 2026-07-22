"
A tracer-level SDK configuration computed from a TracerProvider's TracerConfigurator.
"
Class {
	#name : 'OTTracerConfig',
	#superclass : 'Object',
	#instVars : [
		'enabled'
	],
	#category : 'OpenTelemetry-Instrumentation',
	#package : 'OpenTelemetry-Instrumentation'
}

{ #category : 'instance creation' }
OTTracerConfig class >> default [

	^ self enabled: true
]

{ #category : 'instance creation' }
OTTracerConfig class >> disabled [

	^ self enabled: false
]

{ #category : 'instance creation' }
OTTracerConfig class >> enabled: aBoolean [

	^ self new
		  enabled: aBoolean;
		  yourself
]

{ #category : 'accessing' }
OTTracerConfig >> enabled [

	^ enabled ifNil: [ true ]
]

{ #category : 'accessing' }
OTTracerConfig >> enabled: aBoolean [

	enabled := aBoolean ifNil: [ true ] ifNotNil: [ aBoolean ]
]
