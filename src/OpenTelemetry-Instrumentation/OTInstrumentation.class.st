"
Interface representing a single type instrumentation.
Part of an `OTelInstrumentationModule`.
"
Class {
	#name : #OTInstrumentation,
	#superclass : #Object,
	#classInstVars : [
		'instrumenter'
	],
	#category : #'OpenTelemetry-Instrumentation'
}

{ #category : #matching }
OTInstrumentation class >> classMatcher [
	"Matches all classes by default.
	Subclasses should redefine this method to focus the search on interesting classes."

	^ OTMatcher any
]

{ #category : #configuring }
OTInstrumentation class >> configureMethodEnter: configuration [
	"Redefine this method to configure the method enter instrumentation.
	Use the instance-side API of OTAgentInstaller."
]

{ #category : #configuring }
OTInstrumentation class >> configureMethodExit: configuration [
	"Redefine this method to configure the method exit instrumentation.
	Use the API of OTInstrumentationConfiguration."
]

{ #category : #configuring }
OTInstrumentation class >> defineInstrumenter [
	"Redefine this method to define an OTInstrumenter to be used in the instrumentation methods.
	It should be stored in the `instrumenter` class variable.
	This is optional, but highly recommended if you wish to generate spans.
	Using an instrumenter has the benefits of handling boilerplate code for you."

	"instrumenter := OTInstrumenter new
		spanNameExtractor: [ :request | ... ];
		spanKindExtractor: [ :request | ... ];
		spanSuppressionStrategy: [ :span :kind | ... ];
		contextProducer: [ ... ]"
]

{ #category : #testing }
OTInstrumentation class >> hasMethodEnter [
	"Redefine this method to control whether the method enter instrumentation should be executed."

	^ false
]

{ #category : #testing }
OTInstrumentation class >> hasMethodExit [
	"Redefine this method to control whether the method exit instrumentation should be executed."

	^ false
]

{ #category : #actions }
OTInstrumentation class >> install [
	"Install a specific subclass of Instrumentation."

	<script>
	OTAgentInstaller installInstrumentation: self
]

{ #category : #private }
OTInstrumentation class >> matchingMethodsDo: aBlock [

	| packageMatcher classMatcher methodMatcher |
	packageMatcher := self packageMatcher.
	classMatcher := self classMatcher.
	methodMatcher := self methodMatcher.
	RPackage organizer packages do: [ :package |
		(packageMatcher matches: package) ifTrue: [
			package classes do: [ :class |
				(classMatcher matches: class) ifTrue: [
					class methods do: [ :method |
						(methodMatcher matches: method) ifTrue: [ aBlock value: method ] ] ] ] ] ]
]

{ #category : #matching }
OTInstrumentation class >> methodMatcher [
	"My subclasses must define a matcher for the methods to instrument."

	self subclassResponsibility
]

{ #category : #instrumenting }
OTInstrumentation class >> onMethodEnter: arguments [
	"This method will be executed BEFORE the instrumented method.
	The arguments contain the data that was requested in #configureMethodEnter."

	self shouldBeImplemented
]

{ #category : #instrumenting }
OTInstrumentation class >> onMethodExit: arguments [
	"This method will be executed AFTER the instrumented method.
	The arguments contain the data that was requested in #configureMethodExit."

	self shouldBeImplemented
]

{ #category : #matching }
OTInstrumentation class >> packageMatcher [
	"Matches all packages by default.
	Subclasses should redefine this method to focus the search on interesting packages."

	^ OTMatcher any
]

{ #category : #actions }
OTInstrumentation class >> uninstall [
	"Uninstall a specific subclass of Instrumentation."

	<script>
	OTAgentInstaller uninstallInstrumentation: self
]
