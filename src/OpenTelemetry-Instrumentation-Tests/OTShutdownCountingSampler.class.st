Class {
	#name : 'OTShutdownCountingSampler',
	#superclass : 'OTSampler',
	#instVars : [
		'shutdownCount',
		'samplingCount'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'accessing' }
OTShutdownCountingSampler >> samplingCount [

	^ samplingCount ifNil: [ 0 ]
]

{ #category : 'sampling' }
OTShutdownCountingSampler >> samplingIntentIn: aContext name: aString kind: aKind attributes: attributes links: links [

	samplingCount := self samplingCount + 1.
	^ OTSamplingIntent drop
]

{ #category : 'sampling' }
OTShutdownCountingSampler >> shouldSampleIn: aContext traceId: aTraceId name: aString kind: aKind attributes: attributes links: links [

	samplingCount := self samplingCount + 1.
	^ OTSamplingResult recordAndSample
]

{ #category : 'lifecycle' }
OTShutdownCountingSampler >> shutdown [

	shutdownCount := self shutdownCount + 1.
	^ true
]

{ #category : 'accessing' }
OTShutdownCountingSampler >> shutdownCount [

	^ shutdownCount ifNil: [ 0 ]
]
