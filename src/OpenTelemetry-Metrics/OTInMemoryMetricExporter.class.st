"
I am a metric exporter used for tests and local inspection.
I keep exported snapshots in memory and count forceFlush requests.
"
Class {
	#name : 'OTInMemoryMetricExporter',
	#superclass : 'OTMetricExporter',
	#instVars : [
		'exports',
		'forceFlushCount'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'exporting' }
OTInMemoryMetricExporter >> export: anOTMetricSnapshot [

	^ self withActiveStateDo: [
			  self exports add: anOTMetricSnapshot.
			  true ]
]

{ #category : 'accessing' }
OTInMemoryMetricExporter >> exports [

	^ exports ifNil: [ exports := OrderedCollection new ]
]

{ #category : 'exporting' }
OTInMemoryMetricExporter >> forceFlush [

	^ self withActiveStateDo: [
			  forceFlushCount := self forceFlushCount + 1.
			  true ]
]

{ #category : 'accessing' }
OTInMemoryMetricExporter >> forceFlushCount [

	^ forceFlushCount ifNil: [ 0 ]
]

{ #category : 'initialization' }
OTInMemoryMetricExporter >> initialize [

	super initialize.
	exports := OrderedCollection new.
	forceFlushCount := 0
]
