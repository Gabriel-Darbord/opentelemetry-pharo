Class {
	#name : #OTTestSpanInstrumentation,
	#superclass : #OTTestInstrumentation,
	#category : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : #configuring }
OTTestSpanInstrumentation class >> defineInstrumenter [

	instrumenter := OTInstrumenter forInstrumentationNamed: 'test'
]

{ #category : #configuring }
OTTestSpanInstrumentation class >> defineSampler [

	sampler := OTSampler withRate: 2
]
