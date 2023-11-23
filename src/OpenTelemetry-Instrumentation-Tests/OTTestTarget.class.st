Class {
	#name : #OTTestTarget,
	#superclass : #Object,
	#category : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : #accessing }
OTTestTarget >> answer [

	^ 42
]

{ #category : #asserting }
OTTestTarget >> fail [

	Error signal
]
