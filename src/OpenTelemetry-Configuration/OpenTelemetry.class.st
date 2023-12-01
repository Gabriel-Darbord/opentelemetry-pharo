"
A global singleton for the entrypoint to telemetry functionality for tracing.
"
Class {
	#name : #OpenTelemetry,
	#superclass : #Object,
	#classInstVars : [
		'localDirectoryName'
	],
	#category : #'OpenTelemetry-Configuration'
}

{ #category : #actions }
OpenTelemetry class >> install [

	<script>
	OTAgentInstaller install
]

{ #category : #accessing }
OpenTelemetry class >> localDirectory [

	^ self localDirectoryName asFileReference
]

{ #category : #accessing }
OpenTelemetry class >> localDirectoryName [

	^ localDirectoryName ifNil: [
		  localDirectoryName := 'pharo-local/OpenTelemetry' ]
]

{ #category : #accessing }
OpenTelemetry class >> localDirectoryName: aString [

	localDirectoryName := aString
]

{ #category : #accessing }
OpenTelemetry class >> logsDirectory [

	^ self localDirectory / 'logs'
]

{ #category : #actions }
OpenTelemetry class >> reinstall [

	<script>
	OTAgentInstaller reinstall
]

{ #category : #accessing }
OpenTelemetry class >> tracesDirectory [

	^ self localDirectory / 'traces'
]

{ #category : #actions }
OpenTelemetry class >> uninstall [

	<script>
	OTAgentInstaller uninstall
]
