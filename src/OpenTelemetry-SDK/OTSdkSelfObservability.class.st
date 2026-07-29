"
A shared facade for SDK self-observability.

I let traces, logs, and metrics report internal pipeline activity through one stable SDK surface. My default instances are no-op so signals can call me without taking a hard dependency on the metrics implementation, while concrete subclasses can opt in to record the actual self-observability telemetry.
"
Class {
	#name : 'OTSdkSelfObservability',
	#superclass : 'Object',
	#classVars : [
		'ComponentCounters',
		'Current',
		'Enabled',
		'Factory',
		'StateLock'
	],
	#category : 'OpenTelemetry-SDK',
	#package : 'OpenTelemetry-SDK'
}

{ #category : 'accessing' }
OTSdkSelfObservability class >> current [

	^ self stateLock critical: [
			  Current ifNil: [ Current := self newCurrentWithinLock ].
			  Current ]
]

{ #category : 'accessing' }
OTSdkSelfObservability class >> current: anOTSdkSelfObservability [

	self stateLock critical: [ Current := anOTSdkSelfObservability ifNil: [ self new ] ]
]

{ #category : 'private' }
OTSdkSelfObservability class >> defaultEnabled [

	| rawValue |
	rawValue := self environmentValueAt: self experimentalEnvironmentVariableName.
	^ rawValue notNil and: [ rawValue asString trimBoth asLowercase = 'true' ]
]

{ #category : 'accessing' }
OTSdkSelfObservability class >> disable [

	^ self enabled: false
]

{ #category : 'private' }
OTSdkSelfObservability class >> elapsedSecondsSinceMillisecondClockValue: aMillisecondClockValue [

	| delta |
	delta := Time millisecondClockValue - aMillisecondClockValue.
	delta < 0 ifTrue: [ delta := 0 ].
	^ delta asFloat / 1000.0
]

{ #category : 'accessing' }
OTSdkSelfObservability class >> enable [

	^ self enabled: true
]

{ #category : 'accessing' }
OTSdkSelfObservability class >> enabled [

	^ self stateLock critical: [
			  Enabled ifNil: [ Enabled := self defaultEnabled ].
			  Enabled ]
]

{ #category : 'accessing' }
OTSdkSelfObservability class >> enabled: aBoolean [

	self stateLock critical: [ Enabled := aBoolean = true ].
	self refreshCurrent
]

{ #category : 'private' }
OTSdkSelfObservability class >> environmentValueAt: aString [

	^ OSEnvironment current at: aString ifAbsent: [ nil ]
]

{ #category : 'private' }
OTSdkSelfObservability class >> experimentalEnvironmentVariableName [

	^ 'OTEL_PHARO_X_SELF_OBSERVABILITY'
]

{ #category : 'class initialization' }
OTSdkSelfObservability class >> initialize [

	self reset
]

{ #category : 'private' }
OTSdkSelfObservability class >> lifecycleErrorTypeFor: anOTLifecycleResult [

	anOTLifecycleResult ifNil: [ ^ 'failed' ].
	anOTLifecycleResult isSuccess ifTrue: [ ^ nil ].
	^ anOTLifecycleResult isTimeout
		  ifTrue: [ 'timeout' ]
		  ifFalse: [ 'failed' ]
]

{ #category : 'private' }
OTSdkSelfObservability class >> newCurrentWithinLock [

	(self enabled and: [ Factory notNil ]) ifFalse: [ ^ self new ].
	^ Factory value ifNil: [ self new ]
]

{ #category : 'private' }
OTSdkSelfObservability class >> nextComponentNameForType: aString [

	| nextIndex |
	^ self stateLock critical: [
			  ComponentCounters ifNil: [ ComponentCounters := Dictionary new ].
			  nextIndex := ComponentCounters at: aString ifAbsent: [ 0 ].
			  ComponentCounters at: aString put: nextIndex + 1.
			  String streamContents: [ :stream |
					  stream
						  nextPutAll: aString;
						  nextPut: $/;
						  print: nextIndex ] ]
]

{ #category : 'private' }
OTSdkSelfObservability class >> refreshCurrent [

	^ self stateLock critical: [ Current := self newCurrentWithinLock ]
]

{ #category : 'private' }
OTSdkSelfObservability class >> registerFactory: aBlock [

	self stateLock critical: [ Factory := aBlock ].
	self refreshCurrent
]

{ #category : 'class initialization' }
OTSdkSelfObservability class >> reset [

	self stateLock critical: [
			Enabled := nil.
			Current := nil.
			ComponentCounters := Dictionary new ]
]

{ #category : 'private' }
OTSdkSelfObservability class >> stateLock [

	^ StateLock ifNil: [ StateLock := Semaphore forMutualExclusion ]
]

{ #category : 'recording' }
OTSdkSelfObservability >> adjustQueueSizeBy: anInteger forProcessor: anObject signal: aSymbol capacity: aCapacityInteger [

	self
]

{ #category : 'recording' }
OTSdkSelfObservability >> recordCollectionResult: anOTMetricBatchResult forMetricReader: anObject durationSeconds: aNumber [

	self
]

{ #category : 'recording' }
OTSdkSelfObservability >> recordCreatedLog [

	self
]

{ #category : 'recording' }
OTSdkSelfObservability >> recordEndedSpan: anOTSpan [

	self
]

{ #category : 'recording' }
OTSdkSelfObservability >> recordExportFinishedFor: anExporter signal: aSymbol itemCount: anInteger result: anOTLifecycleResult durationSeconds: aNumber [

	self
]

{ #category : 'recording' }
OTSdkSelfObservability >> recordExportStartedFor: anExporter signal: aSymbol itemCount: anInteger [

	self
]

{ #category : 'recording' }
OTSdkSelfObservability >> recordProcessedCount: anInteger forProcessor: anObject signal: aSymbol errorType: aStringOrNil [

	self
]

{ #category : 'recording' }
OTSdkSelfObservability >> recordStartedSpanWithParentSpanContext: anOTSpanContext samplingResult: anOTSamplingResult [

	self
]
