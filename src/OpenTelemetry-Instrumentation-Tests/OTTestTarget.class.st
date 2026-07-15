Class {
	#name : 'OTTestTarget',
	#superclass : 'Object',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'evaluating' }
OTTestTarget >> answer [

	^ 42
]

{ #category : 'evaluating' }
OTTestTarget >> fail [

	Error signal
]

{ #category : 'evaluating' }
OTTestTarget >> handledFail [

	[ self error ]
		on: Error
		do: [ :e |  ]
]

{ #category : 'evaluating' }
OTTestTarget >> indirectAnswer [

	^ self answer
]

{ #category : 'evaluating' }
OTTestTarget >> suppressedAnswer [

	^ self answer
]
