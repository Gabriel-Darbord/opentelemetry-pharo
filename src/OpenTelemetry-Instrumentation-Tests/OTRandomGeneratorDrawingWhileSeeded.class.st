"
I draw bits while I read the entropy I am seeded from, as instrumented code that reads it would by starting a span.
"
Class {
	#name : 'OTRandomGeneratorDrawingWhileSeeded',
	#superclass : 'OTRandomGenerator',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'private' }
OTRandomGeneratorDrawingWhileSeeded class >> entropy [

	^ (self nextBits: 64) asByteArray , super entropy
]
