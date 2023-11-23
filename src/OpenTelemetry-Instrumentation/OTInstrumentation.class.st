"
Interface representing a single type instrumentation.
Part of an `OTelInstrumentationModule`.
"
Class {
	#name : #OTInstrumentation,
	#superclass : #Object,
	#classInstVars : [
		'enabled',
		'instrumenter',
		'sampler'
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
OTInstrumentation class >> configure: installer [
	"Redefine this method to configure the method enter instrumentation.
	Use the instance-side API of OTAgentInstaller."
]

{ #category : #configuring }
OTInstrumentation class >> defineInstrumenter [
	"Redefine this method to define an OTInstrumenter to be used in the instrumentation methods.
	It should be stored in the `instrumenter` class variable.
	This is optional, but highly recommended if you wish to generate spans.
	Using an instrumenter has the benefits of handling boilerplate code for you."

	"instrumenter := OTInstrumenter new
		instrumentationName: ...;
		spanNameExtractor: [ :request | ... ];
		spanKindExtractor: [ :request | ... ];
		spanSuppressionStrategy: [ :span :kind | ... ];
		contextProducer: [ ... ]"
]

{ #category : #configuring }
OTInstrumentation class >> defineSampler [
	"Redefine this method to define an OTSampler to be used in the instrumentation methods.
	It should be stored in the `sampler` class variable.
	This is useful to limit the number of traces generated."

	"sampler := OTSampler with..."
]

{ #category : #accessing }
OTInstrumentation class >> enabled [
	"Instrumentations are enabled by default."

	^ enabled ifNil: [ enabled := true ]
]

{ #category : #accessing }
OTInstrumentation class >> enabled: aBoolean [

	enabled := aBoolean
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
	Smalltalk globals organization packages do: [ :package |
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
	"This method is executed BEFORE the instrumented method.
	The arguments contain the RFMethodOperation plus the data requested in #configure:"
]

{ #category : #instrumenting }
OTInstrumentation class >> onMethodExit: arguments withValue: returnValue [
	"This method is executed AFTER the instrumented method.
	The first argument contains the RFMethodOperation plus the data requested in #configure:
	The second contains the return value of the method."
]

{ #category : #matching }
OTInstrumentation class >> packageMatcher [
	"Matches all packages by default.
	Subclasses should redefine this method to focus the search on interesting packages."

	^ OTMatcher any
]

{ #category : #actions }
OTInstrumentation class >> reinstall [

	<script>
	self uninstall.
	self install
]

{ #category : #'class initialization' }
OTInstrumentation class >> reset [

	instrumenter := sampler := nil
]

{ #category : #private }
OTInstrumentation class >> run: arguments [
	"Hook called when executing an instrumented method.
	If the trace should not be sampled, execute the method directly.
	Otherwise, run on enter, execute method, ensure running on exit, and record exceptions."

	| returnValue |
	sampler ifNotNil: [
		sampler shouldSample ifFalse: [ ^ arguments first value ] ].
	self onMethodEnter: arguments.
	^ [
	  [ returnValue := arguments first value ]
		  on: Exception
		  do: [ :exception |
			  OTSpan recordException: exception.
			  exception pass ] ] ensure: [
		  self onMethodExit: arguments withValue: returnValue ]
]

{ #category : #actions }
OTInstrumentation class >> uninstall [
	"Uninstall a specific subclass of Instrumentation."

	<script>
	OTAgentInstaller resetEnvironment uninstallInstrumentation: self
]
