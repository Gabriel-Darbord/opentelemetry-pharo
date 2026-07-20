"
I am a basic processor that forwards any `OTSpan` I receive directly to the configured `OTSpanExporter`.
"
Class {
	#name : 'OTSimpleSpanProcessor',
	#superclass : 'OTSpanProcessor',
	#instVars : [
		'exportLock',
		'exporter'
	],
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'accessing' }
OTSimpleSpanProcessor >> exporter [

	^ exporter ifNil: [ exporter := OTSpanExporter current ]
]

{ #category : 'accessing' }
OTSimpleSpanProcessor >> exporter: aSpanExporter [

	exporter := aSpanExporter
]

{ #category : 'processing' }
OTSimpleSpanProcessor >> flush [

	^ self forceFlush
]

{ #category : 'processing' }
OTSimpleSpanProcessor >> forceFlush [

	self isShutdown ifTrue: [ ^ false ].
	^ exportLock critical: [ self exporter forceFlush ]
]

{ #category : 'initialization' }
OTSimpleSpanProcessor >> initialize [

	super initialize.
	exportLock := Semaphore forMutualExclusion
]

{ #category : 'processing' }
OTSimpleSpanProcessor >> process: span [
	"Directly export sampled spans and treat record-only spans as accepted without exporting"

	| snapshot |
	self isShutdown ifTrue: [ ^ false ].
	(self shouldExport: span) ifFalse: [ ^ true ].
	snapshot := OTSpanSnapshot fromSpan: span.
	^ exportLock critical: [ self exporter export: { snapshot } ]
]

{ #category : 'processing' }
OTSimpleSpanProcessor >> shutdown [

	| flushed shutdownResult |
	self isShutdown ifTrue: [ ^ false ].
	flushed := self forceFlush.
	shutdownResult := exportLock critical: [ self exporter shutdown ].
	self markShutdown.
	^ shutdownResult & flushed
]
