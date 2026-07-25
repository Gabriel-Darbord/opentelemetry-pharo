Class {
	#name : 'OTTestTarget',
	#superclass : 'Object',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'as yet unclassified' }
OTTestTarget >> answer [

	^ 42
]

{ #category : 'as yet unclassified' }
OTTestTarget >> fail [

	Error signal
]

{ #category : 'as yet unclassified' }
OTTestTarget >> handledFail [

	[ self error ]
		on: Error
		do: [ :e |  ]
]

{ #category : 'as yet unclassified' }
OTTestTarget >> indirectAnswer [

	^ self answer
]

{ #category : 'as yet unclassified' }
OTTestTarget >> suppressedAnswer [

	^ self answer
]
