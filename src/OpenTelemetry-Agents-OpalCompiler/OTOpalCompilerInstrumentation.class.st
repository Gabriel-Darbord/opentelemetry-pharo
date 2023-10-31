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

	^ OTMatcher name: #install
]

{ #category : 'instrumenting' }
OTOpalCompilerInstrumentation class >> onMethodEnter: arguments [

	| compiler class header |
	compiler := arguments first receiver.
	class := compiler semanticScope targetClass.
	class isMeta ifTrue: [ class := class soleInstance ].
	"get the #source slot, using index for speed"
	header := (compiler instVarAt: 2) copyUpTo: Character cr.

	instrumenter startRequest: class name asString , '>>' , header
]

{ #category : 'instrumenting' }
OTOpalCompilerInstrumentation class >> onMethodExit: arguments withValue: returnValue [

	instrumenter end
]

{ #category : 'matching' }
OTOpalCompilerInstrumentation class >> packageMatcher [

	^ OTMatcher name: #'OpalCompiler-Core'
]
