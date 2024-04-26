"
I am used for exporting spans to local files in STON format.
By default, spans are exported to the `pharo-local/OpenTelemetry/traces` folder of the image.
"
Class {
	#name : 'OTSTONFileSpanExporter',
	#superclass : 'OTFileSpanExporter',
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'exporting' }
OTSTONFileSpanExporter >> export: spans [

	(self directory asFileReference / DateAndTime now asString , 'ston')
		ensureCreateFile writeStreamDo: [ :stream |
		STON put: spans onStream: stream ]
]
