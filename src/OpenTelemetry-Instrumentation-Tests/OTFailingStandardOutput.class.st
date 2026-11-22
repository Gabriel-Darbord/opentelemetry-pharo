"
I stand for a standard output that cannot be flushed, as a pipe whose reader is gone or a closed terminal: flushing me fails as the VM's primitive does.
"
Class {
	#name : 'OTFailingStandardOutput',
	#superclass : 'Object',
	#instVars : [
		'flushCount'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'writing' }
OTFailingStandardOutput >> flush [

	flushCount := self flushCount + 1.
	PrimitiveFailed new signal: 'primitive #flush: in File class failed'
]

{ #category : 'accessing' }
OTFailingStandardOutput >> flushCount [

	^ flushCount ifNil: [ 0 ]
]

{ #category : 'writing' }
OTFailingStandardOutput >> lf [

	self
]

{ #category : 'writing' }
OTFailingStandardOutput >> nextPutAll: aString [

	self
]
