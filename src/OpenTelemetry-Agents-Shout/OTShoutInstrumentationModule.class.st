Class {
	#name : 'OTShoutInstrumentationModule',
	#superclass : 'OTInstrumentationModule',
	#category : 'OpenTelemetry-Agents-Shout',
	#package : 'OpenTelemetry-Agents-Shout'
}

{ #category : 'accessing' }
OTShoutInstrumentationModule class >> instrumentationName [
	"My subclasses must return a string with the name of the instrumentation module.
	Ideally, the name should be the same as the library being instrumented.
	It must be in lowercase, with words separated by hyphens."

	^ 'shout'
]

{ #category : 'accessing' }
OTShoutInstrumentationModule class >> instrumentations [

	^ { OTTextStylerInstrumentation }
]
