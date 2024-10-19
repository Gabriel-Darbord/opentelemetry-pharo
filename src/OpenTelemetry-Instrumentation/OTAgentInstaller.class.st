"
I am a utility class in the OpenTelemetry framework designed to install and uninstall instrumentations using my class-side API.
I streamline the process of integrating instrumentation into existing codebases by providing an abstraction layer for managing instrumented methods.
I also handle permission management, allowing or denying the installation of instrumentations.

My instance-side API is used to configure the installation of instrumentations, allowing developers to fine-tune the behavior of instrumentations.
These methods allow them to specify contextual information, method parameters, receivers, and more that will be passed as arguments to the instrumentations.
This ensures that the instrumentation is tailored to the specific needs of the application.
"
Class {
	#name : 'OTAgentInstaller',
	#superclass : 'Object',
	#classInstVars : [
		'permission'
	],
	#category : 'OpenTelemetry-Instrumentation',
	#package : 'OpenTelemetry-Instrumentation'
}

{ #category : 'class initialization' }
OTAgentInstaller class >> askPermission [
	"command line and GUI"

	self flag: #todo.
	^ true
]

{ #category : 'class initialization' }
OTAgentInstaller class >> denyPermission [

	<script>
	permission := false.
	self uninstall
]

{ #category : 'class initialization' }
OTAgentInstaller class >> givePermission [

	<script>
	permission := true.
	self install
]

{ #category : 'class initialization' }
OTAgentInstaller class >> hasPermission [

	^ permission ifNil: [ permission := self askPermission ]
]

{ #category : 'class initialization' }
OTAgentInstaller class >> initialize [
	"Install the instrumentations when OpenTelemetry is loaded."

	self hasPermission ifTrue: [ self install ]
]

{ #category : 'actions' }
OTAgentInstaller class >> install [
	"Install all the active instrumentation modules present in this image."

	<script>
	OTInstrumentationModule subclasses do: [ :module |
		module enabled ifTrue: [ self installModule: module ] ]
]

{ #category : 'actions' }
OTAgentInstaller class >> installInstrumentation: anInstrumentation [
	"Install the instrumentation on all matching methods using the configured installer.
	It is the receiver of this message, and should be one of my subclasses."

	| installer |
	installer := self new configureWith: anInstrumentation.
	anInstrumentation
		defineInstrumenter;
		defineSampler;
		matchingMethodsDo: [ :method |
			(installer shouldInstrument: method with: anInstrumentation)
				ifTrue: [ installer instrument: method ] ]
]

{ #category : 'actions' }
OTAgentInstaller class >> installModule: anInstrumentationModule [
	"Install all enabled instrumentations from the module."

	anInstrumentationModule initialize instrumentations do: [
		:instrumentation |
		instrumentation enabled ifTrue: [ instrumentation install ] ]
]

{ #category : 'testing' }
OTAgentInstaller class >> isAbstract [

	^ self == OTAgentInstaller
]

{ #category : 'actions' }
OTAgentInstaller class >> reinstall [

	<script>
	self uninstall.
	self install
]

{ #category : 'initialization' }
OTAgentInstaller class >> resetEnvironment [

	<script>
	OTSpan reset.
	OTSpanProcessor reset.
	OTSpanExporter reset
]

{ #category : 'actions' }
OTAgentInstaller class >> uninstall [
	"Uninstall all of the instrumentation present in this image."

	<script>
	self resetEnvironment.
	OTInstrumentationModule subclasses do: [ :module |
		self uninstallModule: module ]
]

{ #category : 'actions' }
OTAgentInstaller class >> uninstallInstrumentation: anInstrumentation [

	self subclassResponsibility
]

{ #category : 'actions' }
OTAgentInstaller class >> uninstallModule: anInstrumentationModule [

	anInstrumentationModule instrumentations do: [ :instrumentation |
		instrumentation uninstall ]
]

{ #category : 'private' }
OTAgentInstaller >> configureWith: anInstrumentation [

	anInstrumentation configure: self
]

{ #category : 'private' }
OTAgentInstaller >> instrument: aMethod [
	"This is a private method, do not use this!
	Install the instrumentation on the method."

	self subclassResponsibility
]

{ #category : 'private' }
OTAgentInstaller >> shouldInstrument: aMethod with: anInstrumentation [

	self subclassResponsibility
]
