"
I stand for the VM's standard output, which holds what is written until it is flushed: I keep what was written up to the last flush apart.
"
Class {
	#name : 'OTRecordingStandardOutput',
	#superclass : 'Object',
	#instVars : [
		'written',
		'flushed'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'writing' }
OTRecordingStandardOutput >> flush [

	flushed := written contents
]

{ #category : 'accessing' }
OTRecordingStandardOutput >> flushedContents [
	"What was written up to the last flush."

	^ flushed
]

{ #category : 'initialization' }
OTRecordingStandardOutput >> initialize [

	super initialize.
	written := WriteStream on: String new.
	flushed := ''
]

{ #category : 'writing' }
OTRecordingStandardOutput >> lf [

	written lf
]

{ #category : 'writing' }
OTRecordingStandardOutput >> nextPutAll: aString [

	written nextPutAll: aString
]

{ #category : 'accessing' }
OTRecordingStandardOutput >> writtenContents [

	^ written contents
]
