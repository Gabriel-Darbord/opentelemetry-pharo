Class {
	#name : 'OTTestTarget',
	#superclass : 'Object',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'test methods' }
OTTestTarget >> answer [

	^ 42
]

{ #category : 'test methods' }
OTTestTarget >> fail [

	Error signal
]

{ #category : 'test methods' }
OTTestTarget >> indirectAnswer [

	^ self answer
]

{ #category : 'test methods' }
OTTestTarget >> suppressedAnswer [

	^ self answer
]
