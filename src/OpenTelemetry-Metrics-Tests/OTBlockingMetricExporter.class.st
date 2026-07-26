Class {
	#name : 'OTBlockingMetricExporter',
	#superclass : 'OTMetricExporter',
	#instVars : [
		'exportEntered',
		'exportRelease',
		'forceFlushCount'
	],
	#category : 'OpenTelemetry-Metrics-Tests',
	#package : 'OpenTelemetry-Metrics-Tests'
}

{ #category : 'private - signaling' }
OTBlockingMetricExporter >> allowExportToContinue [

	exportRelease signal
]

{ #category : 'exporting' }
OTBlockingMetricExporter >> export: anOTMetricSnapshot [

	^ self withActiveStateDo: [
			  exportEntered signal.
			  exportRelease wait.
			  true ]
]

{ #category : 'exporting' }
OTBlockingMetricExporter >> forceFlush [

	^ self withActiveStateDo: [
			  forceFlushCount := self forceFlushCount + 1.
			  true ]
]

{ #category : 'accessing' }
OTBlockingMetricExporter >> forceFlushCount [

	^ forceFlushCount ifNil: [ 0 ]
]

{ #category : 'initialization' }
OTBlockingMetricExporter >> initialize [

	super initialize.
	exportEntered := Semaphore new.
	exportRelease := Semaphore new.
	forceFlushCount := 0
]

{ #category : 'private - signaling' }
OTBlockingMetricExporter >> waitForExportEntryWithin: anInteger [

	^ (exportEntered waitTimeoutMilliseconds: anInteger) not
]
