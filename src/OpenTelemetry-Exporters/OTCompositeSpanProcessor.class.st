"
A span processor that forwards lifecycle and completed-span callbacks to an ordered collection of child processors.
"
Class {
	#name : 'OTCompositeSpanProcessor',
	#superclass : 'OTSpanProcessor',
	#instVars : [
		'processors'
	],
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'instance creation' }
OTCompositeSpanProcessor class >> withAll: aCollection [

	^ self new
		processors: aCollection;
		yourself
]

{ #category : 'processing' }
OTCompositeSpanProcessor >> forceFlush [

	^ processors
		inject: true
		into: [ :allFlushed :each | (each forceFlush) & allFlushed ]
]

{ #category : 'initialization' }
OTCompositeSpanProcessor >> initialize [

	super initialize.
	processors := OrderedCollection new
]

{ #category : 'processing' }
OTCompositeSpanProcessor >> process: aSpan [

	^ processors
		inject: true
		into: [ :allAccepted :each | (each process: aSpan) & allAccepted ]
]

{ #category : 'accessing' }
OTCompositeSpanProcessor >> processors [

	^ processors
]

{ #category : 'accessing' }
OTCompositeSpanProcessor >> processors: aCollection [

	processors := aCollection
		ifNil: [ OrderedCollection new ]
		ifNotNil: [ aCollection asOrderedCollection ]
]

{ #category : 'processing' }
OTCompositeSpanProcessor >> shutdown [

	| flushed |
	flushed := self forceFlush.
	^ processors
		inject: flushed
		into: [ :allShutdown :each | (each shutdown) & allShutdown ]
]
