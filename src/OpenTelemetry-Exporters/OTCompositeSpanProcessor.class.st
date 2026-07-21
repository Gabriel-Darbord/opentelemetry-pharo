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
	^ self processors inject: true into: [ :allFlushed :each |
			  (self
				   withProcessor: each
				   operationNamed: 'forceFlush'
				   default: false
				   do: [ each forceFlush ]) & allFlushed ]
]

{ #category : 'initialization' }
OTCompositeSpanProcessor >> initialize [

	super initialize.
	processors := OrderedCollection new
]

{ #category : 'processing' }
OTCompositeSpanProcessor >> onEnd: aSpan [

	self isStopping ifTrue: [ ^ false ].
	^ self processors inject: true into: [ :allAccepted :each |
			  (self
				   withProcessor: each
				   operationNamed: 'onEnd'
				   default: false
				   do: [ each onEnd: aSpan ]) & allAccepted ]
]

{ #category : 'processing' }
OTCompositeSpanProcessor >> onEnding: aSpan [

	self isStopping ifTrue: [ ^ false ].
	^ self processors inject: true into: [ :allAccepted :each |
			  (self
				   withProcessor: each
				   operationNamed: 'onEnding'
				   default: false
				   do: [
						   each onEnding: aSpan.
						   true ]) & allAccepted ]
]

{ #category : 'processing' }
OTCompositeSpanProcessor >> onStart: aSpan parentContext: aContext [

	self isStopping ifTrue: [ ^ false ].
	^ self processors inject: true into: [ :allAccepted :each |
			  (self
				   withProcessor: each
				   operationNamed: 'onStart'
				   default: false
				   do: [
						   each onStart: aSpan parentContext: aContext.
						   true ]) & allAccepted ]
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
	flushed := self processors inject: true into: [ :allFlushed :each |
			           (self
				            withProcessor: each
				            operationNamed: 'forceFlush'
				            default: false
				            do: [ each forceFlush ]) & allFlushed ].
	allShutdown := self processors inject: true into: [ :allChildrenShutdown :each |
			               (self
				                withProcessor: each
				                operationNamed: 'shutdown'
				                default: false
				                do: [ each shutdown ]) & allChildrenShutdown ].
	self markShutdown.
	^ allShutdown & flushed
]

{ #category : 'private - error handling' }
OTCompositeSpanProcessor >> withProcessor: aProcessor operationNamed: anOperationName default: aDefaultValue do: aBlock [

	^ [ aBlock value ]
		  on: Error
		  do: [ :error |
				  OTTracerProvider noteSpanProcessor: aProcessor failedDuring: anOperationName error: error.
				  aDefaultValue ]
]
