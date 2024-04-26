"
I am used for exporting spans to local files.
By default, spans are exported to the `pharo-local/OpenTelemetry/traces` folder of the image.
"
Class {
	#name : 'OTFileSpanExporter',
	#superclass : 'OTSpanExporter',
	#instVars : [
		'directory'
	],
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'testing' }
OTFileSpanExporter class >> isAbstract [

	^ self == OTFileSpanExporter
]

{ #category : 'accessing' }
OTFileSpanExporter >> directory [

	^ directory ifNil: [ directory := OpenTelemetry tracesDirectory ]
]

{ #category : 'accessing' }
OTFileSpanExporter >> directory: aFileReference [

	directory := aFileReference
]
