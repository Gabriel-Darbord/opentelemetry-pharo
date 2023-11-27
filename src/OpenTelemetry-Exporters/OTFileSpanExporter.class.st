"
I am used for exporting spans to local files in JSON format.
By default, spans are exported to the `pharo-local/OpenTelemetry/traces` folder of the image.
"
Class {
	#name : #OTFileSpanExporter,
	#superclass : #OTSpanExporter,
	#instVars : [
		'folder'
	],
	#category : 'OpenTelemetry-Exporters'
}

{ #category : #exporting }
OTFileSpanExporter >> export: spans [

	(self folder asFileReference / DateAndTime now asString , 'ston')
		ensureCreateFile writeStreamDo: [ :stream |
		STON put: spans onStream: stream ]
]

{ #category : #hook }
OTFileSpanExporter >> folder [

	^ folder ifNil: [ folder := 'pharo-local/OpenTelemetry/traces' ]
]

{ #category : #hook }
OTFileSpanExporter >> folder: aString [

	folder := aString
]
