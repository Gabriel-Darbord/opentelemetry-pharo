"
I am used for exporting spans to local files in STON format.
By default, spans are exported to the `pharo-local/OpenTelemetry/traces` folder of the image.
"
Class {
	#name : 'OTSTONFileSpanExporter',
	#superclass : 'OTFileSpanExporter',
	#category : 'OpenTelemetry-Traces',
	#package : 'OpenTelemetry-Traces'
}

{ #category : 'exporting' }
OTSTONFileSpanExporter >> export: spans [

	^ self withExportLockDo: [
			  self isShutdown ifTrue: [ ^ false ].
			  self withOperationNamed: 'export' default: false do: [
					  (self directory asFileReference / DateAndTime now asString , 'ston') ensureCreateFile writeStreamDo: [ :stream |
						  STON put: (spans collect: [ :each | each asExportRecord ]) asArray onStream: stream ].
					  true ] ]
]
