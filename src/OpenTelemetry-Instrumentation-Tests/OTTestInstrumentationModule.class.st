Class {
	#name : #OTTestInstrumentationModule,
	#superclass : #OTInstrumentationModule,
	#category : #'OpenTelemetry-Instrumentation-Tests'
}

{ #category : #accessing }
OTTestInstrumentationModule class >> enabled [
	"Do not install test instrumentations outside the scope of tests."

	^ false
]

{ #category : #accessing }
OTTestInstrumentationModule class >> instrumentationName [

	^ 'opentelemetry-tests'
]

{ #category : #accessing }
OTTestInstrumentationModule class >> instrumentations [

	^ { OTTestSimpleInstrumentation. OTTestSpanInstrumentation }
]
