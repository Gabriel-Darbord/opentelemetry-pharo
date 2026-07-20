"
A span wrapper around a SpanContext that participates in parenting and propagation while remaining non-recording.
"
Class {
	#name : 'OTNonRecordingSpan',
	#superclass : 'OTSpan',
	#instVars : [
		'wrappedSpanContext'
	],
	#category : 'OpenTelemetry-Instrumentation',
	#package : 'OpenTelemetry-Instrumentation'
}

{ #category : 'instance creation' }
OTNonRecordingSpan class >> spanContext: aSpanContext context: aContext parent: aSpan instrumentationName: aString [

	^ self
		spanContext: aSpanContext
		context: aContext
		parent: aSpan
		instrumentationScope: (OTInstrumentationScope named: aString)
]

{ #category : 'instance creation' }
OTNonRecordingSpan class >> spanContext: aSpanContext context: aContext parent: aSpan instrumentationScope: anInstrumentationScope [

	| span |
	span := self newInternal.
	span
		wrappedSpanContext: aSpanContext;
		restoreContext: aContext;
		restoreParent: aSpan;
		restoreInstrumentationScope: anInstrumentationScope.
	^ span
]

{ #category : 'instance creation' }
OTNonRecordingSpan class >> withSpanContext: aSpanContext [

	^ self newInternal
		  wrappedSpanContext: aSpanContext;
		  yourself
]

{ #category : 'control' }
OTNonRecordingSpan >> end [

	^ self
]

{ #category : 'control' }
OTNonRecordingSpan >> end: aDateAndTime [

	self
]

{ #category : 'initialization' }
OTNonRecordingSpan >> initialize [

	super initialize
]

{ #category : 'testing' }
OTNonRecordingSpan >> isRecording [

	^ false
]

{ #category : 'accessing' }
OTNonRecordingSpan >> spanContext [

	^ wrappedSpanContext
]

{ #category : 'control' }
OTNonRecordingSpan >> start [

	^ self
]

{ #category : 'private' }
OTNonRecordingSpan >> wrappedSpanContext: aSpanContext [

	wrappedSpanContext := aSpanContext
]
