"
I am the abstract base class for metric exporters.
I define lifecycle, shutdown, temporality selection, and aggregation selection for metric export.
"
Class {
	#name : 'OTMetricExporter',
	#superclass : 'Object',
	#instVars : [
		'shutdown',
		'stateLock',
		'shutdownRequested',
		'temporalitySelector',
		'aggregationSelector',
		'exportLock'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'accessing' }
OTMetricExporter >> aggregationSelector [

	^ stateLock critical: [ aggregationSelector ifNil: [ aggregationSelector := [ :instrument | #default ] ] ]
]

{ #category : 'accessing' }
OTMetricExporter >> aggregationSelector: aBlockOrNil [

	stateLock critical: [
			self ensureOpenLocked.
			aggregationSelector := aBlockOrNil ifNil: [ [ :instrument | #default ] ] ifNotNil: [ aBlockOrNil ] ]
]

{ #category : 'private - lifecycle' }
OTMetricExporter >> beginShutdown [

	^ stateLock critical: [
			  (shutdownRequested or: [ shutdown ]) ifTrue: [ ^ false ].
			  shutdownRequested := true.
			  true ]
]

{ #category : 'private - lifecycle' }
OTMetricExporter >> ensureOpenLocked [

	(shutdownRequested or: [ shutdown ]) ifTrue: [ Error signal: 'OpenTelemetry metric exporter is shutdown' ]
]

{ #category : 'exporting' }
OTMetricExporter >> export: anOTMetricSnapshot [

	self subclassResponsibility
]

{ #category : 'private - lifecycle' }
OTMetricExporter >> finishShutdown [

	stateLock critical: [ shutdown := true ]
]

{ #category : 'exporting' }
OTMetricExporter >> forceFlush [

	^ self withActiveStateDo: [ true ]
]

{ #category : 'initialization' }
OTMetricExporter >> initialize [

	super initialize.
	stateLock := Semaphore forMutualExclusion.
	exportLock := Semaphore forMutualExclusion.
	shutdown := false.
	shutdownRequested := false.
	temporalitySelector := [ :instrument | #cumulative ].
	aggregationSelector := [ :instrument | #default ]
]

{ #category : 'testing' }
OTMetricExporter >> isShutdown [

	^ stateLock critical: [ shutdown = true ]
]

{ #category : 'testing' }
OTMetricExporter >> isStopping [

	^ stateLock critical: [ shutdownRequested = true ]
]

{ #category : 'lifecycle' }
OTMetricExporter >> shutdown [

	self beginShutdown ifFalse: [ ^ false ].
	self finishShutdown.
	^ true
]

{ #category : 'accessing' }
OTMetricExporter >> temporalitySelector [

	^ stateLock critical: [ temporalitySelector ifNil: [ temporalitySelector := [ :instrument | #cumulative ] ] ]
]

{ #category : 'accessing' }
OTMetricExporter >> temporalitySelector: aBlockOrNil [

	stateLock critical: [
			self ensureOpenLocked.
			temporalitySelector := aBlockOrNil ifNil: [ [ :instrument | #cumulative ] ] ifNotNil: [ aBlockOrNil ] ]
]

{ #category : 'private - lifecycle' }
OTMetricExporter >> withActiveStateDo: aBlock [

	^ stateLock critical: [
			  (shutdownRequested or: [ shutdown ]) ifTrue: [ ^ false ].
			  aBlock value ]
]

{ #category : 'private - lifecycle' }
OTMetricExporter >> withSynchronizedExportDo: aBlock [

	^ exportLock critical: aBlock
]
