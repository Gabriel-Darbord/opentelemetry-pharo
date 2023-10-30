Class {
	#name : 'OTFileSpanExporter',
	#superclass : 'OTSpanExporter',
	#instVars : [
		'folder'
	],
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'exporting' }
OTFileSpanExporter >> export: spans [

	(self folder asFileReference / DateAndTime now asString , 'ston')
		ensureCreateFile writeStreamDo: [ :stream |
		STON put: spans onStream: stream ]
]

{ #category : 'hook' }
OTFileSpanExporter >> folder [

	^ folder ifNil: [ folder := 'pharo-local/OpenTelemetry/traces' ]
]

{ #category : 'hook' }
OTFileSpanExporter >> folder: aString [

	folder := aString
]
