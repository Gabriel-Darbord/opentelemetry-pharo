Class {
	#name : 'OTRecordingSpanProcessor',
	#superclass : 'OTSpanProcessor',
	#instVars : [
		'startedSpans',
		'startedParentContexts',
		'endedSpans'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

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
