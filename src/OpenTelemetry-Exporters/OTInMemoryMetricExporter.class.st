Class {
	#name : 'OTInMemoryMetricExporter',
	#superclass : 'OTMetricExporter',
	#instVars : [
		'exports',
		'forceFlushCount'
	],
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'exporting' }
OTInMemoryMetricExporter >> export: anOTMetricSnapshot [

	self isShutdown ifTrue: [ ^ false ].
	self exports add: anOTMetricSnapshot.
	^ true
]

{ #category : 'accessing' }
OTInMemoryMetricExporter >> exports [

	^ exports ifNil: [ exports := OrderedCollection new ]
]

{ #category : 'exporting' }
OTInMemoryMetricExporter >> forceFlush [

	self isShutdown ifTrue: [ ^ false ].
	forceFlushCount := self forceFlushCount + 1.
	^ true
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
