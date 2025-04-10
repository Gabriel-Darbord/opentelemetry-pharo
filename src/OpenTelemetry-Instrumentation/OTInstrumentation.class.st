"
Interface representing a single type instrumentation.
Part of an `OTInstrumentationModule`.
"
Class {
	#name : 'OTInstrumentation',
	#superclass : 'Object',
	#classInstVars : [
		'enabled',
		'instrumenter',
		'sampler'
	],
	#category : 'OpenTelemetry-Instrumentation',
	#package : 'OpenTelemetry-Instrumentation'
}

{ #category : 'matching' }
OTInstrumentation class >> classMatcher [
	"Matches all classes by default.
	Subclasses should redefine this method to focus the search on interesting classes."

	^ OTMatcher any
]

{ #category : 'configuring' }
OTInstrumentation class >> configure: installer [
	"Redefine this method to configure the arguments given to the instrumentation method.
	Use the instance-side API of a subclass of OTAgentInstaller."
]

{ #category : 'configuring' }
OTInstrumentation class >> defineInstrumenter [
	"Redefine this method to define an OTInstrumenter to be used in the instrumentation methods.
	It should be stored in the `instrumenter` class variable.
	This is optional, but highly recommended if you want to generate spans.
	Using an instrumenter has the advantage of handling boilerplate code for you, in particular the lifecycle and export of spans."

	"instrumenter := OTInstrumenter new
		instrumentationName: ...;
		spanNameExtractor: [ :request | ... ];
		spanKindExtractor: [ :request | ... ];
		spanSuppressionStrategy: [ :span :kind | ... ];
		contextProducer: [ ... ]"
]

{ #category : 'configuring' }
OTInstrumentation class >> defineSampler [
	"Redefine this method to define an OTSampler to be used in the instrumentation methods.
	It should be stored in the `sampler` class variable.
	This is useful to limit the number of traces generated."

	"sampler := OTSampler with..."
]

{ #category : 'accessing' }
OTInstrumentation class >> enabled [
	"Instrumentations are enabled by default."

	^ enabled ifNil: [ enabled := true ]
]

{ #category : 'accessing' }
OTInstrumentation class >> enabled: aBoolean [

	enabled := aBoolean
]

{ #category : 'actions' }
OTInstrumentation class >> install [
	"Install a specific subclass of Instrumentation."

	<script>
	self installer installInstrumentation: self
]

{ #category : 'configuring' }
OTInstrumentation class >> installer [

	self subclassResponsibility
]

{ #category : 'testing' }
OTInstrumentation class >> isAbstract [

	^ self == OTInstrumentation
]

{ #category : 'private' }
OTInstrumentation class >> matchingMethodsDo: aBlock [

	| classMatcher methodMatcher |
	classMatcher := self classMatcher.
	methodMatcher := self methodMatcher.
	self packageMatcher matchingPackagesDo: [ :package |
		classMatcher matching: package classes do: [ :class |
			methodMatcher matching: class methods do: aBlock.
			methodMatcher matching: class class methods do: aBlock ] ]
]

{ #category : 'matching' }
OTInstrumentation class >> methodMatcher [
	"My subclasses must define a matcher for the methods to instrument."

	self subclassResponsibility
]

{ #category : 'matching' }
OTInstrumentation class >> packageMatcher [
	"Matches all packages by default.
	Subclasses should redefine this method to focus the search on interesting packages."

	^ OTMatcher any
]

{ #category : 'actions' }
OTInstrumentation class >> reinstall [

	<script>
	self uninstall.
	self install
]

{ #category : 'class initialization' }
OTInstrumentation class >> reset [

	instrumenter := sampler := nil
]

{ #category : 'actions' }
OTInstrumentation class >> uninstall [
	"Uninstall a specific subclass of Instrumentation."

	<script>
	self installer resetEnvironment uninstallInstrumentation: self
]
