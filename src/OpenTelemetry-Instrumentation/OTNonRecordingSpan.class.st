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

{ #category : 'accessing' }
OTNonRecordingSpan >> spanId [

	^ self spanContext spanId
]

{ #category : 'control' }
OTNonRecordingSpan >> start [

	^ self
]

{ #category : 'accessing' }
OTNonRecordingSpan >> traceFlags [

	^ self spanContext traceFlags
]

{ #category : 'accessing' }
OTNonRecordingSpan >> traceId [

	^ self spanContext traceId
]

{ #category : 'accessing' }
OTNonRecordingSpan >> traceState [

	^ self spanContext traceState
]

{ #category : 'private' }
OTNonRecordingSpan >> wrappedSpanContext: aSpanContext [

	wrappedSpanContext := aSpanContext
]
