"
I group several connected `OTInstrumentation`s together, sharing instrumentation names and control over enabling or disabling the instrumentation.
Ideally all types in a single instrumented library should live in a single module.
"
Class {
	#name : 'OTInstrumentationModule',
	#superclass : 'Object',
	#classInstVars : [
		'enabled'
	],
	#category : 'OpenTelemetry-Instrumentation',
	#package : 'OpenTelemetry-Instrumentation'
}

{ #category : 'accessing' }
OTInstrumentationModule class >> enabled [
	"Instrumentation modules are disabled by default."

	^ enabled ifNil: [ enabled := false ]
]

{ #category : 'accessing' }
OTInstrumentationModule class >> enabled: aBoolean [

	enabled := aBoolean
]

{ #category : 'actions' }
OTInstrumentationModule class >> install [
	"Install a specific subclass of InstrumentationModule."

	<script>
	OTAgentInstaller installModule: self
]

{ #category : 'accessing' }
OTInstrumentationModule class >> instrumentationName [
	"My subclasses must return a string with the name of the instrumentation module.
	Ideally, the name should be the same as the library being instrumented.
	It must be in lowercase, with words separated by hyphens."

	self subclassResponsibility
]

{ #category : 'accessing' }
OTInstrumentationModule class >> instrumentations [
	"My subclasses must return the list of Instrumentations contained in the module."

	self subclassResponsibility
]

{ #category : 'actions' }
OTInstrumentationModule class >> reinstall [

	<script>
	self uninstall.
	self install
]

{ #category : 'actions' }
OTInstrumentationModule class >> uninstall [
	"Uninstall a specific subclass of InstrumentationModule."

	<script>
	OTAgentInstaller resetEnvironment uninstallModule: self
]
