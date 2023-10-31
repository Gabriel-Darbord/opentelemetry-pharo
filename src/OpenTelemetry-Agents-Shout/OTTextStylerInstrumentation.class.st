Class {
	#name : 'OTTextStylerInstrumentation',
	#superclass : 'OTInstrumentation',
	#category : 'OpenTelemetry-Agents-Shout',
	#package : 'OpenTelemetry-Agents-Shout'
}

{ #category : 'matching' }
OTTextStylerInstrumentation class >> classMatcher [
	"My subclasses must define a matcher for the methods to instrument."

	^ OTMatcher name: #SHRBTextStyler
]

{ #category : 'configuring' }
OTTextStylerInstrumentation class >> defineInstrumenter [

	instrumenter := OTInstrumenter forInstrumentationNamed: 'shout'
]

{ #category : 'configuring' }
OTTextStylerInstrumentation class >> defineSampler [
	"Totally arbitrary sampling rate, will adjust with time (10/23)"

	sampler := OTSampler withRate: 100
]

{ #category : 'matching' }
OTTextStylerInstrumentation class >> methodMatcher [
	"My subclasses must define a matcher for the methods to instrument."

	^ OTMatcher name: #privateStyle:
]

{ #category : 'instrumenting' }
OTTextStylerInstrumentation class >> onMethodEnter: arguments [
	"The request is the first line of the argument of `privateStyle: aText`"

	instrumenter startRequest:
		(arguments first arguments first asString copyUpTo: Character cr)
]

{ #category : 'instrumenting' }
OTTextStylerInstrumentation class >> onMethodExit: arguments withValue: returnValue [

	| operation span |
	operation := arguments first.
	(span := OTSpan current)
		attributeAt: 'class' put: operation receiver className;
		attributeAt: 'method' put: operation method selector;
		attributeAt: 'arguments' put: (STON toString: operation arguments);
		attributeAt: 'result' put: (STON toString: returnValue).
	instrumenter end: span
]

{ #category : 'matching' }
OTTextStylerInstrumentation class >> packageMatcher [
	"My subclasses must define a matcher for the methods to instrument."

	^ OTMatcher name: #Shout
]
