Class {
	#name : 'OTBatchSpanProcessor',
	#superclass : 'OTSpanProcessor',
	#instVars : [
		'batch',
		'batchSize'
	],
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'class initialization' }
OTBatchSpanProcessor class >> initialize [

	SessionManager default registerToolClassNamed: self name
]

{ #category : 'system startup' }
OTBatchSpanProcessor class >> shutDown [

	self allInstancesDo: [ :processor | processor flush ]
]

{ #category : 'processing' }
OTBatchSpanProcessor >> batchSize [

	^ batchSize
]

{ #category : 'processing' }
OTBatchSpanProcessor >> batchSize: anInteger [

	batchSize := anInteger
]

{ #category : 'processing' }
OTBatchSpanProcessor >> flush [

	^ batch ifEmpty: [ false ] ifNotEmpty: [
		  [ OTSpanExporter instance export: batch ] ensure: [
			  batch := OrderedCollection new: batchSize ] ]
]

{ #category : 'initialization' }
OTBatchSpanProcessor >> initialize [
	"Totally arbitrary default batch size, will adjust value with time (10/23)"

	batchSize := 128.
	batch := OrderedCollection new: batchSize
]

{ #category : 'processing' }
OTBatchSpanProcessor >> process: span [
	"Wait until the batch has been filled to export"

	batch add: span.
	batch size < batchSize ifTrue: [ ^ true ].
	^ self flush
]
