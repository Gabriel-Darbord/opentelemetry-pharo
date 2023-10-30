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
	#instVars : [
		'metalink',
		'arguments'
	],
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
		module isActive ifTrue: [ self installModule: module ] ]
]

{ #category : 'actions' }
OTAgentInstaller class >> installInstrumentation: anInstrumentation [

	| configuration |
	configuration := self new configureWith: anInstrumentation.
	anInstrumentation
		defineInstrumenter;
		matchingMethodsDo: [ :method |
			(method ast links noneSatisfy: [ :link |
					 link metaObject == anInstrumentation ]) ifTrue: [
					configuration instrument: method ] ]
]

{ #category : 'actions' }
OTAgentInstaller class >> installModule: anInstrumentationModule [

	anInstrumentationModule typeInstrumentations do: [
		:typeInstrumentation |
		self installInstrumentation: typeInstrumentation ]
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

	MetaLink allInstances do: [ :metalink |
		metalink metaObject == anInstrumentation ifTrue: [
			metalink uninstall ] ]
]

{ #category : 'actions' }
OTAgentInstaller class >> uninstallModule: anInstrumentationModule [

	anInstrumentationModule typeInstrumentations do: [
		:typeInstrumentation |
		self uninstallInstrumentation: typeInstrumentation ]
]

{ #category : 'API - configuration' }
OTAgentInstaller >> beOneShot [
	"Only execute the instrumentation once."

	metalink optionOneShot: true
]

{ #category : 'private' }
OTAgentInstaller >> configureWith: anInstrumentation [
	"This is a private method, do not use this!
	Configure the MetaLink to make it run the method instrumentation defined in an OTInstrumentation subclass."

	anInstrumentation configure: self.
	metalink control: #instead.
	metalink selector: #run:.
	metalink arguments: arguments keys.
	metalink metaObject: anInstrumentation
]

{ #category : 'initialization' }
OTAgentInstaller >> initialize [

	metalink := MetaLink new.
	"number of args depends on the configuration, so dump all in array as single arg"
	metalink optionArgsAsArray: true.
	"the configurable arguments that will be given to the instrumentation"
	arguments := OrderedDictionary new.
	"always with RFMethodOperation containing method, arguments and receiver."
	arguments add: #operation -> nil
]

{ #category : 'private' }
OTAgentInstaller >> instrument: aMethod [
	"This is a private method, do not use this!
	Install the metalink on the instrumented method."

	aMethod ast link: metalink
]

{ #category : 'API - configuration' }
OTAgentInstaller >> withContext [
	"The executing context, note that it is slow to reify."

	arguments add: #context -> nil
]

{ #category : 'API - configuration' }
OTAgentInstaller >> withObject [
	"Object executing the instrumented method."

	arguments add: #object -> nil
]

{ #category : 'API - configuration' }
OTAgentInstaller >> withSender [
	"Sender of the instrumented method."

	arguments add: #sender -> nil
]
