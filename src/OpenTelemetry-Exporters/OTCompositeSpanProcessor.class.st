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

{ #category : 'accessing' }
OTCompositeSpanProcessor >> componentProcessors [

	^ processors copy
]

{ #category : 'processing' }
OTCompositeSpanProcessor >> forceFlush [

	self isStopping ifTrue: [ ^ false ].
	^ self processors inject: true into: [ :allFlushed :each | each forceFlush & allFlushed ]
]

{ #category : 'initialization' }
OTCompositeSpanProcessor >> initialize [

	super initialize.
	processors := OrderedCollection new
]

{ #category : 'processing' }
OTCompositeSpanProcessor >> onEnd: aSpan [

	self isStopping ifTrue: [ ^ false ].
	^ self processors inject: true into: [ :allAccepted :each | (each onEnd: aSpan) & allAccepted ]
]

{ #category : 'processing' }
OTCompositeSpanProcessor >> onEnding: aSpan [

	self isStopping ifTrue: [ ^ false ].
	^ self processors inject: true into: [ :allAccepted :each |
			  each onEnding: aSpan.
			  allAccepted ]
]

{ #category : 'processing' }
OTCompositeSpanProcessor >> onStart: aSpan parentContext: aContext [

	self isStopping ifTrue: [ ^ false ].
	^ self processors inject: true into: [ :allAccepted :each |
			  each onStart: aSpan parentContext: aContext.
			  allAccepted ]
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

	| allShutdown flushed |
	self beginShutdown ifFalse: [ ^ false ].
	flushed := self processors inject: true into: [ :allFlushed :each | each forceFlush & allFlushed ].
	allShutdown := self processors inject: true into: [ :allChildrenShutdown :each | each shutdown & allChildrenShutdown ].
	self markShutdown.
	^ allShutdown & flushed
]
