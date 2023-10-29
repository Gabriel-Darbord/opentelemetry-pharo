Class {
	#name : #OTFileExporter,
	#superclass : #OTSpanExporter,
	#instVars : [
		'folder'
	],
	#category : #'OpenTelemetry-Exporters'
}

{ #category : #exporting }
OTFileExporter >> export: spans [

	(self folder asFileReference / DateAndTime now asString)
		ensureCreateFile writeStreamDo: [ :stream |
		STON put: spans onStream: stream ]
]

{ #category : #hook }
OTFileExporter >> folder [

	^ folder ifNil: [ folder := 'pharo-local/OpenTelemetry/traces' ]
]

{ #category : #hook }
OTFileExporter >> folder: aString [

	folder := aString
]
