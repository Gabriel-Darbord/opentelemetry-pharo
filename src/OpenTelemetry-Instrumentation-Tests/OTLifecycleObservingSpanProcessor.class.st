Class {
	#name : 'OTLifecycleObservingSpanProcessor',
	#superclass : 'OTSpanProcessor',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'private' }
OTLifecycleObservingSpanProcessor class >> resetRecordedLifecycle [

	OTClassStateStore removeValueAt: #otLifecycleObservingTimeline forClass: self ifAbsent: [ ]
]

{ #category : 'private' }
OTLifecycleObservingSpanProcessor class >> timeline [

	^ OTClassStateStore valueAt: #otLifecycleObservingTimeline forClass: self ifAbsent: [
			  | timeline |
			  timeline := OrderedCollection new.
			  OTClassStateStore valueAt: #otLifecycleObservingTimeline forClass: self put: timeline.
			  timeline ]
]

{ #category : 'processing' }
OTLifecycleObservingSpanProcessor >> forceFlush [

	self isShutdown ifTrue: [ ^ false ].
	^ true
]

{ #category : 'processing' }
OTLifecycleObservingSpanProcessor >> onEnd: aSpan [

	| exportRecord hasMutation |
	exportRecord := aSpan asExportRecord.
	hasMutation := (exportRecord includesKey: #attributes) and: [
		               (exportRecord at: #attributes) includesKey: 'processor.onEnding.order' ].
	self timeline add: {
			self.
			#onEnd.
			aSpan isRecording.
			(exportRecord at: #endTime) notNil.
			hasMutation }.
	^ true
]

{ #category : 'processing' }
OTLifecycleObservingSpanProcessor >> onEnding: aSpan [

	| exportRecord |
	exportRecord := aSpan asExportRecord.
	self timeline add: {
			self.
			#onEnding.
			aSpan isRecording.
			(exportRecord at: #endTime) notNil }.
	aSpan
		attributeAt: 'processor.onEnding.order' put: self identityHash asString;
		addEventNamed: 'processor.onEnding.' , self identityHash asString.
	^ true
]

{ #category : 'processing' }
OTLifecycleObservingSpanProcessor >> onStart: aSpan parentContext: aContext [

	self timeline add: {
			self.
			#onStart.
			aSpan isRecording.
			(aSpan asExportRecord includesKey: #endTime) not }.
	^ true
]

{ #category : 'processing' }
OTLifecycleObservingSpanProcessor >> shutdown [

	self isShutdown ifTrue: [ ^ false ].
	self markShutdown.
	^ true
]

{ #category : 'accessing' }
OTLifecycleObservingSpanProcessor >> timeline [

	^ self class timeline
]
