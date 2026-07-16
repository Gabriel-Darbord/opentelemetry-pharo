"
Runtime logger filtering configuration.
"
Class {
	#name : 'OTLoggerConfig',
	#superclass : 'Object',
	#instVars : [
		'enabled',
		'minimumSeverity',
		'traceBased'
	],
	#category : 'OpenTelemetry-Logs',
	#package : 'OpenTelemetry-Logs'
}

{ #category : 'instance creation' }
OTLoggerConfig class >> default [

	^ self new
]

{ #category : 'testing' }
OTLoggerConfig >> allowsContext: anOTContext [

	| context span spanContext |
	traceBased ifFalse: [ ^ true ].
	context := anOTContext ifNil: [ OpenTelemetry currentContext ].
	span := context ifNotNil: [ context span ].
	span ifNil: [ ^ true ].
	spanContext := span spanContext.
	spanContext isValid ifFalse: [ ^ true ].
	^ spanContext isSampled
]

{ #category : 'testing' }
OTLoggerConfig >> allowsSeverityNumber: anObject [

	| severity |
	severity := OTSeverity normalize: anObject.
	severity = OTSeverity undefined ifTrue: [ ^ true ].
	^ severity >= self minimumSeverity
]

{ #category : 'comparing' }
OTLoggerConfig >> equalsDefaultConfiguration [

	^ enabled = true
		and: [ minimumSeverity = OTSeverity undefined
		and: [ traceBased = false ] ]
]

{ #category : 'accessing' }
OTLoggerConfig >> enabled [

	^ enabled = true
]

{ #category : 'accessing' }
OTLoggerConfig >> enabled: aBoolean [

	enabled := aBoolean == false ifTrue: [ false ] ifFalse: [ true ].
	^ enabled
]

{ #category : 'initialization' }
OTLoggerConfig >> initialize [

	super initialize.
	enabled := true.
	minimumSeverity := OTSeverity undefined.
	traceBased := false
]

{ #category : 'accessing' }
OTLoggerConfig >> minimumSeverity [

	^ OTSeverity normalize: minimumSeverity
]

{ #category : 'accessing' }
OTLoggerConfig >> minimumSeverity: anObject [

	minimumSeverity := OTSeverity normalize: anObject.
	^ minimumSeverity
]

{ #category : 'copying' }
OTLoggerConfig >> postCopy [

	super postCopy.
	enabled := enabled copy.
	minimumSeverity := minimumSeverity copy.
	traceBased := traceBased copy
]

{ #category : 'accessing' }
OTLoggerConfig >> traceBased [

	^ traceBased = true
]

{ #category : 'accessing' }
OTLoggerConfig >> traceBased: aBoolean [

	traceBased := aBoolean == true.
	^ traceBased
]
