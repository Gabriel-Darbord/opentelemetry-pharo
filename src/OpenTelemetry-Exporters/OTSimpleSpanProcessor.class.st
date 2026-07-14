"
I am a basic processor that forwards any `OTSpan` I receive directly to the configured `OTSpanExporter`.
"
Class {
	#name : 'OTSimpleSpanProcessor',
	#superclass : 'OTSpanProcessor',
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
	^ OTSpanExporter current forceFlush
]

{ #category : 'processing' }
OTSimpleSpanProcessor >> process: span [
	"Directly export sampled spans and treat record-only spans as accepted without exporting"

	self isShutdown ifTrue: [ ^ false ].
	(self shouldExport: span) ifFalse: [ ^ true ].
	^ OTSpanExporter current export: { span }
]

{ #category : 'processing' }
OTSimpleSpanProcessor >> shutdown [

	| flushed shutdownResult |
	self isShutdown ifTrue: [ ^ false ].
	flushed := self forceFlush.
	shutdownResult := OTSpanExporter current shutdown.
	self markShutdown.
	^ shutdownResult & flushed
]
