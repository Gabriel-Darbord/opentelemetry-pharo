"
I am used for exporting spans to local files in JSON format.
By default, spans are exported to the `pharo-local/OpenTelemetry/traces` folder of the image.
"
Class {
	#name : #OTFileSpanExporter,
	#superclass : #OTSpanExporter,
	#instVars : [
		'directory'
	],
	#category : #'OpenTelemetry-Exporters'
}

{ #category : #accessing }
OTFileSpanExporter >> directory [

	^ directory ifNil: [ directory := OpenTelemetry tracesDirectory ]
]

{ #category : #accessing }
OTFileSpanExporter >> directory: aFileReference [

	directory := aFileReference
]

{ #category : #exporting }
OTFileSpanExporter >> export: spans [

	(self directory asFileReference / DateAndTime now asString , 'ston')
		ensureCreateFile writeStreamDo: [ :stream |
		STON put: spans onStream: stream ]
]
