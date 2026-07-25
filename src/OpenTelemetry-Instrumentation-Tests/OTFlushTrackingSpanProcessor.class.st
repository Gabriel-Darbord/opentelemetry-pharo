Class {
	#name : 'OTFlushTrackingSpanProcessor',
	#superclass : 'OTSpanProcessor',
	#instVars : [
		'flushCount'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'processing' }
OTFlushTrackingSpanProcessor >> flush [

	flushCount := self flushCount + 1.
	^ true
]

{ #category : 'accessing' }
OTFlushTrackingSpanProcessor >> flushCount [

	^ flushCount ifNil: [ 0 ]
]

{ #category : 'processing' }
OTFlushTrackingSpanProcessor >> onEnd: aSpan [

	^ true
]
