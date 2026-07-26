Class {
	#name : 'OTRecordingMetricReader',
	#superclass : 'OTMetricReader',
	#instVars : [
		'forceFlushCount',
		'shutdownCount',
		'countLock'
	],
	#category : 'OpenTelemetry-Metrics-Tests',
	#package : 'OpenTelemetry-Metrics-Tests'
}

{ #category : 'collecting' }
OTRecordingMetricReader >> collect [

	^ OTMetricSnapshot empty
]

{ #category : 'lifecycle' }
OTRecordingMetricReader >> forceFlush [

	(super forceFlush) ifFalse: [ ^ false ].
	countLock critical: [ forceFlushCount := self forceFlushCount + 1 ].
	^ true
]

{ #category : 'accessing' }
OTRecordingMetricReader >> forceFlushCount [

	^ forceFlushCount ifNil: [ 0 ]
]

{ #category : 'initialization' }
OTRecordingMetricReader >> initialize [

	super initialize.
	forceFlushCount := 0.
	shutdownCount := 0.
	countLock := Semaphore forMutualExclusion
]

{ #category : 'lifecycle' }
OTRecordingMetricReader >> shutdown [

	(super shutdown) ifFalse: [ ^ false ].
	countLock critical: [ shutdownCount := self shutdownCount + 1 ].
	^ true
]

{ #category : 'accessing' }
OTRecordingMetricReader >> shutdownCount [

	^ shutdownCount ifNil: [ 0 ]
]
