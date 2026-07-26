Class {
	#name : 'OTRecordingMetricReader',
	#superclass : 'OTMetricReader',
	#instVars : [
		'forceFlushCount',
		'shutdownCount',
		'stateLock'
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

	^ stateLock critical: [
			  self isShutdown ifTrue: [ ^ false ].
			  forceFlushCount := self forceFlushCount + 1.
			  true ]
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
	stateLock := Semaphore forMutualExclusion
]

{ #category : 'lifecycle' }
OTRecordingMetricReader >> shutdown [

	^ stateLock critical: [
			  self isShutdown ifTrue: [ ^ false ].
			  shutdownCount := self shutdownCount + 1.
			  super shutdown ]
]

{ #category : 'accessing' }
OTRecordingMetricReader >> shutdownCount [

	^ shutdownCount ifNil: [ 0 ]
]
