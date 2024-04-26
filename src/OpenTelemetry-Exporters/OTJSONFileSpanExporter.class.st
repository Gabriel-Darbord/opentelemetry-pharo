"
I am used for exporting spans to local files in JSON format.
By default, spans are exported to the `pharo-local/OpenTelemetry/traces` folder of the image.
"
Class {
	#name : 'OTJSONFileSpanExporter',
	#superclass : 'OTFileSpanExporter',
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'exporting' }
OTJSONFileSpanExporter >> export: spans [

	(self directory asFileReference / DateAndTime now asString , 'json')
		ensureCreateFile writeStreamDo: [ :stream |
		STON put: spans asArray asJsonOnStream: stream ]
]
