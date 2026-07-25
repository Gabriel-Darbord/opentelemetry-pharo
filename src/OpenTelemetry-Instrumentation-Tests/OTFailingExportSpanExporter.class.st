Class {
	#name : 'OTFailingExportSpanExporter',
	#superclass : 'OTRecordingSpanExporter',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'accessing' }
OTFailingExportSpanExporter >> exportUnchecked: spans [

	(self isShutdown and: [ self allowsExportsAfterShutdown not ]) ifTrue: [ ^ false ].
	^ false
]
