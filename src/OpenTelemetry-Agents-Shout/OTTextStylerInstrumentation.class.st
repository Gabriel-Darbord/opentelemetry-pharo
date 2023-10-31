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

	| span operation |
	operation := arguments first.
	span := instrumenter startRequest:
		        (operation arguments first asString copyUpTo: Character cr).
	span
		attributeAt: 'class' put: 'SHRBTextStyler';
		attributeAt: 'method' put: #privateStyle:;
		attributeAt: 'arguments' put: (String streamContents: [ :stream |
					 (SCExporter on: stream) nextPut: operation arguments ])
]

{ #category : 'instrumenting' }
OTTextStylerInstrumentation class >> onMethodExit: arguments withValue: returnValue [

	| span |
	(span := OTSpan current)
		attributeAt: 'result'
		put: (String streamContents: [ :stream |
				 (SCExporter on: stream) nextPut: returnValue ]).
	instrumenter end: span
]

{ #category : 'matching' }
OTTextStylerInstrumentation class >> packageMatcher [
	"My subclasses must define a matcher for the methods to instrument."

	^ OTMatcher name: #Shout
]
