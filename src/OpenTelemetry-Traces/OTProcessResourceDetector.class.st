"
Supplies process and runtime attributes that can be derived from the running Pharo VM and image.
"
Class {
	#name : 'OTProcessResourceDetector',
	#superclass : 'OTResourceDetector',
	#category : 'OpenTelemetry-Traces',
	#package : 'OpenTelemetry-Traces'
}

{ #category : 'accessing' }
OTProcessResourceDetector class >> detectorName [

	^ 'process'
]

{ #category : 'detecting' }
OTProcessResourceDetector >> detectResource [

	| attributes commandArguments commandLine executableName executablePath imagePath processId |
	attributes := OrderedDictionary new.
	processId := OTTracerProvider currentProcessId.
	executablePath := OTTracerProvider defaultProcessExecutablePath.
	executableName := OTTracerProvider defaultProcessExecutableName.
	imagePath := OTTracerProvider currentImagePath.
	commandArguments := OTTracerProvider processCommandArguments.
	commandLine := OTTracerProvider processCommandLine.
	processId ifNotNil: [ attributes at: 'process.pid' put: processId ].
	executablePath ifNotNil: [ attributes at: 'process.executable.path' put: executablePath ].
	executableName ifNotNil: [ attributes at: 'process.executable.name' put: executableName ].
	imagePath ifNotNil: [ attributes at: 'process.command' put: imagePath ].
	commandLine ifNotNil: [ attributes at: 'process.command_line' put: commandLine ].
	commandArguments ifNotEmpty: [ attributes at: 'process.command_args' put: commandArguments ].
	attributes
		at: 'process.runtime.name' put: OTTracerProvider runtimeName;
		at: 'process.runtime.version' put: OTTracerProvider runtimeVersion;
		at: 'process.runtime.description' put: OTTracerProvider runtimeDescription.
	^ OTResource attributes: attributes schemaUrl: OTTracerProvider semanticConventionsSchemaUrl
]
