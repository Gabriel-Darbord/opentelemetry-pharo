"
I stand for a flush process that has ended, and run a block the first time I am asked whether I have, as a process that preempts the one asking would.
"
Class {
	#name : 'OTEndedFlushProcess',
	#superclass : 'Object',
	#instVars : [
		'onCheck'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'instance creation' }
OTEndedFlushProcess class >> onCheck: aBlock [

	^ self new
		  onCheck: aBlock;
		  yourself
]

{ #category : 'testing' }
OTEndedFlushProcess >> isTerminated [

	| block |
	block := onCheck.
	onCheck := nil.
	block ifNotNil: [ block value ].
	^ true
]

{ #category : 'accessing' }
OTEndedFlushProcess >> onCheck: aBlock [

	onCheck := aBlock
]

{ #category : 'actions' }
OTEndedFlushProcess >> terminate [

	self
]
