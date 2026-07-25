Class {
	#name : 'OTContextToken',
	#superclass : 'Object',
	#instVars : [
		'previousContext',
		'attachedContext',
		'process'
	],
	#category : 'OpenTelemetry-Traces',
	#package : 'OpenTelemetry-Traces'
}

{ #category : 'instance creation' }
OTContextToken class >> previousContext: aPreviousContext attachedContext: anAttachedContext process: aProcess [

	^ self new
		  previousContext: aPreviousContext;
		  attachedContext: anAttachedContext;
		  process: aProcess;
		  yourself
]

{ #category : 'accessing' }
OTContextToken >> attachedContext [

	^ attachedContext
]

{ #category : 'accessing' }
OTContextToken >> attachedContext: anOTContext [

	attachedContext := anOTContext
]

{ #category : 'testing' }
OTContextToken >> isForActiveProcess [

	^ process == Processor activeProcess
]

{ #category : 'accessing' }
OTContextToken >> previousContext [

	^ previousContext
]

{ #category : 'accessing' }
OTContextToken >> previousContext: anOTContext [

	previousContext := anOTContext
]

{ #category : 'printing' }
OTContextToken >> printOn: aStream [

	aStream nextPutAll: 'ContextToken'
]

{ #category : 'accessing' }
OTContextToken >> process [

	^ process
]

{ #category : 'accessing' }
OTContextToken >> process: aProcess [

	process := aProcess
]
