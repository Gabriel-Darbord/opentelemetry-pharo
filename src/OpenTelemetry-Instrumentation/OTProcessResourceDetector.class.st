"
Supplies process and runtime attributes that can be derived from the running Pharo VM and image.
"
Class {
	#name : 'OTProcessResourceDetector',
	#superclass : 'OTResourceDetector',
	#category : 'OpenTelemetry-Instrumentation',
	#package : 'OpenTelemetry-Instrumentation'
}

{ #category : 'accessing' }
OTProcessResourceDetector class >> detectorName [

	^ 'process'
]

{ #category : 'detecting' }
OTProcessResourceDetector >> detectResource [

	| attributes commandArguments executableName executablePath imagePath |
	attributes := OrderedDictionary new.
	executablePath := OTTracerProvider defaultProcessExecutablePath.
	executableName := OTTracerProvider defaultProcessExecutableName.
	imagePath := OTTracerProvider currentImagePath.
	commandArguments := OTTracerProvider processCommandArguments.
	executablePath ifNotNil: [ attributes at: 'process.executable.path' put: executablePath ].
	executableName ifNotNil: [ attributes at: 'process.executable.name' put: executableName ].
	imagePath ifNotNil: [ attributes at: 'process.command' put: imagePath ].
	commandArguments ifNotEmpty: [ attributes at: 'process.command_args' put: commandArguments ].
	attributes
		at: 'process.runtime.name' put: OTTracerProvider runtimeName;
		at: 'process.runtime.version' put: OTTracerProvider runtimeVersion;
		at: 'process.runtime.description' put: OTTracerProvider runtimeDescription.
	^ OTResource
		attributes: attributes
		schemaUrl: OTTracerProvider semanticConventionsSchemaUrl
]
