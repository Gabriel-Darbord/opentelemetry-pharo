"
A span exporter that forwards export and lifecycle operations to an ordered
collection of child exporters.
"
Class {
	#name : 'OTCompositeSpanExporter',
	#superclass : 'OTSpanExporter',
	#instVars : [
		'exporters'
	],
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'instance creation' }
OTCompositeSpanExporter class >> withAll: aCollection [

	^ self new
		exporters: aCollection;
		yourself
]

{ #category : 'accessing' }
OTCompositeSpanExporter >> componentExporters [

	^ exporters copy
]

{ #category : 'exporting' }
OTCompositeSpanExporter >> export: spans [

	self isShutdown ifTrue: [ ^ false ].
	^ exporters
		inject: true
		into: [ :allExported :each | (each export: spans) & allExported ]
]

{ #category : 'accessing' }
OTCompositeSpanExporter >> exporters [

	^ exporters
]

{ #category : 'accessing' }
OTCompositeSpanExporter >> exporters: aCollection [

	exporters := aCollection
		ifNil: [ OrderedCollection new ]
		ifNotNil: [ aCollection asOrderedCollection ]
]

{ #category : 'exporting' }
OTCompositeSpanExporter >> forceFlush [

	self isShutdown ifTrue: [ ^ false ].
	^ exporters
		inject: true
		into: [ :allFlushed :each | (each forceFlush) & allFlushed ]
]

{ #category : 'initialization' }
OTCompositeSpanExporter >> initialize [

	super initialize.
	exporters := OrderedCollection new
]

{ #category : 'exporting' }
OTCompositeSpanExporter >> shutdown [

	| allShutdown exportersSnapshot flushed |
	self beginShutdown ifFalse: [ ^ false ].
	exportersSnapshot := self componentExporters.
	flushed := exportersSnapshot inject: true into: [ :allFlushed :each | each forceFlush & allFlushed ].
	allShutdown := exportersSnapshot inject: true into: [ :allClosed :each | each shutdown & allClosed ].
	self markShutdown.
	^ flushed & allShutdown
]
