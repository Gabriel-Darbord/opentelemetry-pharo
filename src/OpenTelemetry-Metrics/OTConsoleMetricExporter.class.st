"
A debugging-oriented metric exporter that writes exported metrics to the console.
The output format is intentionally unspecified.
"
Class {
	#name : 'OTConsoleMetricExporter',
	#superclass : 'OTMetricExporter',
	#instVars : [
		'outputStreamBlock'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'exporting' }
OTConsoleMetricExporter >> export: anOTMetricSnapshot [

	| stream |
	self isStopping ifTrue: [ ^ false ].
	stream := self outputStream.
	stream
		nextPutAll: anOTMetricSnapshot metrics printString;
		lf.
	^ true
]

{ #category : 'accessing' }
OTConsoleMetricExporter >> outputStream [

	^ outputStreamBlock ifNil: [ Stdio stdout ] ifNotNil: [ outputStreamBlock value ]
]

{ #category : 'accessing' }
OTConsoleMetricExporter >> outputStream: anObject [

	outputStreamBlock := anObject isBlock
		                     ifTrue: [ anObject ]
		                     ifFalse: [ [ anObject ] ].
	^ anObject
]
