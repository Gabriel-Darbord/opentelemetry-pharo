Class {
	#name : #OTTestInstrumentationModule,
	#superclass : #OTInstrumentationModule,
	#category : #'OpenTelemetry-Instrumentation-Tests'
}

{ #category : #accessing }
OTTestInstrumentationModule class >> instrumentationName [

	^ 'opentelemetry-tests'
]

{ #category : #accessing }
OTTestInstrumentationModule class >> typeInstrumentations [

	^ { OTTestSimpleInstrumentation }
]
