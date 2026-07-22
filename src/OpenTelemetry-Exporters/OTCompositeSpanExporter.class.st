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

	^ self withExportLockDo: [
			  self isShutdown ifTrue: [ ^ false ].
			  exporters inject: true into: [ :allExported :each |
					  (self
						   withExporter: each
						   operationNamed: 'export'
						   default: false
						   do: [ each export: spans ]) & allExported ] ]
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
	^ self withExportLockDo: [
			  self isShutdown
				  ifTrue: [ false ]
				  ifFalse: [
						  exporters inject: true into: [ :allFlushed :each |
								  (self
									   withExporter: each
									   operationNamed: 'forceFlush'
									   default: false
									   do: [ each forceFlush ]) & allFlushed ] ] ]
]

{ #category : 'initialization' }
OTCompositeSpanExporter >> initialize [

	super initialize.
	exporters := OrderedCollection new
]

{ #category : 'exporting' }
OTCompositeSpanExporter >> shutdown [

	self beginShutdown ifFalse: [ ^ false ].
	^ self withExportLockDo: [
			  | allShutdown exportersSnapshot flushed |
			  exportersSnapshot := self componentExporters.
			  flushed := exportersSnapshot inject: true into: [ :allFlushed :each |
					             (self
						              withExporter: each
						              operationNamed: 'forceFlush'
						              default: false
						              do: [ each forceFlush ]) & allFlushed ].
			  allShutdown := exportersSnapshot inject: true into: [ :allClosed :each |
					                 (self
						                  withExporter: each
						                  operationNamed: 'shutdown'
						                  default: false
						                  do: [ each shutdown ]) & allClosed ].
			  self markShutdown.
			  flushed & allShutdown ]
]

{ #category : 'private - error handling' }
OTCompositeSpanExporter >> withExporter: anExporter operationNamed: anOperationName default: aDefaultValue do: aBlock [

	^ [ aBlock value ]
		  on: Error
		  do: [ :error |
				  OTSpanExporter noteSpanExporter: anExporter failedDuring: anOperationName error: error.
				  aDefaultValue ]
]
