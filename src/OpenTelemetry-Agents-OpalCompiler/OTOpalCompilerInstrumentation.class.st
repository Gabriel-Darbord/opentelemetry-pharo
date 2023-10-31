Class {
	#name : 'OTOpalCompilerInstrumentation',
	#superclass : 'OTInstrumentation',
	#category : 'OpenTelemetry-Agents-OpalCompiler',
	#package : 'OpenTelemetry-Agents-OpalCompiler'
}

{ #category : 'matching' }
OTOpalCompilerInstrumentation class >> classMatcher [

	^ OTMatcher name: #OpalCompiler
]

{ #category : 'configuring' }
OTOpalCompilerInstrumentation class >> defineInstrumenter [

	instrumenter := OTInstrumenter forInstrumentationNamed:
		                'opal-compiler'
]

{ #category : 'matching' }
OTOpalCompilerInstrumentation class >> methodMatcher [

	^ OTMatcher name: #install:
]

{ #category : 'instrumenting' }
OTOpalCompilerInstrumentation class >> onMethodEnter: arguments [

	| operation class header |
	operation := arguments first.
	class := operation receiver semanticScope targetClass.
	header := operation arguments first copyUpTo: Character cr.
	instrumenter startRequest: class , '>>' , header
]

{ #category : 'instrumenting' }
OTOpalCompilerInstrumentation class >> onMethodExit: arguments withValue: returnValue [

	instrumenter end
]

{ #category : 'matching' }
OTOpalCompilerInstrumentation class >> packageMatcher [

	^ OTMatcher name: #'OpalCompiler-Core'
]
