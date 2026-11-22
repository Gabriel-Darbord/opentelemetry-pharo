"
I close the connections exporters keep open before the image is saved, and hold their requests back until it runs again.

An exporter's HTTP client keeps its connection open between exports. Saved in the image, that connection holds a native socket and, over TLS, a session whose handle is stale once the image starts again: finalizing it then fails, and a headless image stops as it starts. Exporters note themselves here when they make a request, and close their connection when a request fails, since a connection left half made is not closed otherwise.
"
Class {
	#name : 'OTExporterConnections',
	#superclass : 'Object',
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'connections' }
OTExporterConnections class >> close: anExporter [
	"Closes anExporter's connection, which its next request opens again."

	[ anExporter httpClient close ]
		on: Error
		do: [ :error | error return: nil ]
]

{ #category : 'private' }
OTExporterConnections class >> exporters [
	"The exporters that made a request, weakly held."

	^ OTClassStateStore valueAt: #otExporters forClass: self ifAbsentPut: [ WeakIdentityKeyDictionary new ]
]

{ #category : 'private' }
OTExporterConnections class >> exportersLock [

	^ OTClassStateStore valueAt: #otExportersLock forClass: self ifAbsentPut: [ Semaphore forMutualExclusion ]
]

{ #category : 'class initialization' }
OTExporterConnections class >> initialize [

	SessionManager default registerToolClassNamed: self name
]

{ #category : 'snapshots' }
OTExporterConnections class >> isSavingImage [
	"Whether the image is being saved: requests wait until it runs again, so that none leaves a connection in it."

	^ OTClassStateStore valueAt: #otSavingImage forClass: self ifAbsent: [ false ]
]

{ #category : 'connections' }
OTExporterConnections class >> noteRequestBy: anExporter [

	self exportersLock critical: [ self exporters at: anExporter put: true ]
]

{ #category : 'snapshots' }
OTExporterConnections class >> prepareForSnapshot [
	"Holds requests back until the image runs again, and closes every connection an exporter keeps."

	| exporters |
	OTClassStateStore valueAt: #otSavingImage forClass: self put: true.
	exporters := self exportersLock critical: [ self exporters keys reject: [ :each | each isNil ] ].
	exporters do: [ :each | self close: each ]
]

{ #category : 'system startup' }
OTExporterConnections class >> shutDown: quitting [

	self prepareForSnapshot
]

{ #category : 'system startup' }
OTExporterConnections class >> startUp: resuming [
	"The image runs again, from its saved file or on after saving: requests go out again."

	OTClassStateStore valueAt: #otSavingImage forClass: self put: false
]
