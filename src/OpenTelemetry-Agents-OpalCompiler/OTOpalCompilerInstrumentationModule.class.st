Class {
	#name : 'OTOpalCompilerInstrumentationModule',
	#superclass : 'OTInstrumentationModule',
	#category : 'OpenTelemetry-Agents-OpalCompiler',
	#package : 'OpenTelemetry-Agents-OpalCompiler'
}

{ #category : 'accessing' }
OTOpalCompilerInstrumentationModule class >> instrumentationName [
	"My subclasses must return a string with the name of the instrumentation module.
	Ideally, the name should be the same as the library being instrumented.
	It must be in lowercase, with words separated by hyphens."

	^ 'opal-compiler'
]

{ #category : 'accessing' }
OTOpalCompilerInstrumentationModule class >> instrumentations [

	^ { OTOpalCompilerInstrumentation }
]
