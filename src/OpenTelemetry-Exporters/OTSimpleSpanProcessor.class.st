"
I am a basic processor that forwards any `OTSpan` I receive directly to the configured `OTSpanExporter`.
"
Class {
	#name : 'OTSimpleSpanProcessor',
	#superclass : 'OTSpanProcessor',
	#instVars : [
		'exportLock'
	],
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'processing' }
OTSimpleSpanProcessor >> flush [

	^ self forceFlush
]

{ #category : 'processing' }
OTSimpleSpanProcessor >> forceFlush [

	self isShutdown ifTrue: [ ^ false ].
	^ exportLock critical: [ OTSpanExporter current forceFlush ]
]

{ #category : 'initialization' }
OTSimpleSpanProcessor >> initialize [

	super initialize.
	exportLock := Semaphore forMutualExclusion
]

{ #category : 'processing' }
OTSimpleSpanProcessor >> process: span [
	"Directly export sampled spans and treat record-only spans as accepted without exporting"

	self isShutdown ifTrue: [ ^ false ].
	(self shouldExport: span) ifFalse: [ ^ true ].
	^ exportLock critical: [ OTSpanExporter current export: { span } ]
]

{ #category : 'processing' }
OTSimpleSpanProcessor >> shutdown [

	| flushed shutdownResult |
	self isShutdown ifTrue: [ ^ false ].
	flushed := self forceFlush.
	shutdownResult := exportLock critical: [ OTSpanExporter current shutdown ].
	self markShutdown.
	^ shutdownResult & flushed
]
