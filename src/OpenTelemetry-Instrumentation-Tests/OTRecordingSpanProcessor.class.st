Class {
	#name : 'OTRecordingSpanProcessor',
	#superclass : 'OTSpanProcessor',
	#instVars : [
		'endingSpans',
		'startedSpans',
		'startedParentContexts',
		'endedSpans'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'accessing' }
OTRecordingSpanProcessor >> endingSpans [

	^ endingSpans ifNil: [ endingSpans := OrderedCollection new ]
]

{ #category : 'accessing' }
OTRecordingSpanProcessor >> endedSpans [

	^ endedSpans ifNil: [ endedSpans := OrderedCollection new ]
]

{ #category : 'accessing' }
OTRecordingSpanProcessor >> onEnd: aSpan [

	self endedSpans add: aSpan.
	^ true
]

{ #category : 'accessing' }
OTRecordingSpanProcessor >> onEnding: aSpan [

	self endingSpans add: aSpan.
	aSpan attributeAt: 'processor.onEnding' put: true.
	^ true
]

{ #category : 'accessing' }
OTRecordingSpanProcessor >> onStart: aSpan parentContext: aContext [

	self startedSpans add: aSpan.
	self startedParentContexts add: aContext.
	^ true
]

{ #category : 'accessing' }
OTRecordingSpanProcessor >> startedParentContexts [

	^ startedParentContexts ifNil: [ startedParentContexts := OrderedCollection new ]
]

{ #category : 'accessing' }
OTRecordingSpanProcessor >> startedSpans [

	^ startedSpans ifNil: [ startedSpans := OrderedCollection new ]
]
