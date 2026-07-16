Class {
	#name : 'OTLifecycleTrackingSampler',
	#superclass : 'OTSampler',
	#instVars : [
		'shutdownCount',
		'startCount'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'testing' }
OTLifecycleTrackingSampler >> shutdown [

	self shutdownCount > 0 ifTrue: [ ^ false ].
	shutdownCount := self shutdownCount + 1.
	^ true
]

{ #category : 'accessing' }
OTLifecycleTrackingSampler >> shutdownCount [

	^ shutdownCount ifNil: [ 0 ]
]

{ #category : 'asserting' }
OTLifecycleTrackingSampler >> shouldSample [

	^ false
]

{ #category : 'lifecycle' }
OTLifecycleTrackingSampler >> start [

	startCount := self startCount + 1
]

{ #category : 'accessing' }
OTLifecycleTrackingSampler >> startCount [

	^ startCount ifNil: [ 0 ]
]
