"
Severity-number helpers for the OpenTelemetry logs data model.
"
Class {
	#name : 'OTSeverity',
	#superclass : 'Object',
	#category : 'OpenTelemetry-Logs',
	#package : 'OpenTelemetry-Logs'
}

{ #category : 'severity' }
OTSeverity class >> debug [

	^ 5
]

{ #category : 'severity' }
OTSeverity class >> debug: anInteger [

	^ self severityAtBase: self debug variant: anInteger
]

{ #category : 'severity' }
OTSeverity class >> error [

	^ 17
]

{ #category : 'severity' }
OTSeverity class >> error: anInteger [

	^ self severityAtBase: self error variant: anInteger
]

{ #category : 'severity' }
OTSeverity class >> fatal [

	^ 21
]

{ #category : 'severity' }
OTSeverity class >> fatal: anInteger [

	^ self severityAtBase: self fatal variant: anInteger
]

{ #category : 'normalizing' }
OTSeverity class >> fromName: anObject [

	| normalized |
	anObject ifNil: [ ^ self undefined ].
	normalized := anObject asString trimBoth asLowercase.
	normalized = 'trace' ifTrue: [ ^ self trace ].
	normalized = 'trace2' ifTrue: [ ^ self trace: 2 ].
	normalized = 'trace3' ifTrue: [ ^ self trace: 3 ].
	normalized = 'trace4' ifTrue: [ ^ self trace: 4 ].
	normalized = 'debug' ifTrue: [ ^ self debug ].
	normalized = 'debug2' ifTrue: [ ^ self debug: 2 ].
	normalized = 'debug3' ifTrue: [ ^ self debug: 3 ].
	normalized = 'debug4' ifTrue: [ ^ self debug: 4 ].
	normalized = 'info' ifTrue: [ ^ self info ].
	normalized = 'info2' ifTrue: [ ^ self info: 2 ].
	normalized = 'info3' ifTrue: [ ^ self info: 3 ].
	normalized = 'info4' ifTrue: [ ^ self info: 4 ].
	normalized = 'warn' ifTrue: [ ^ self warn ].
	normalized = 'warn2' ifTrue: [ ^ self warn: 2 ].
	normalized = 'warn3' ifTrue: [ ^ self warn: 3 ].
	normalized = 'warn4' ifTrue: [ ^ self warn: 4 ].
	normalized = 'error' ifTrue: [ ^ self error ].
	normalized = 'error2' ifTrue: [ ^ self error: 2 ].
	normalized = 'error3' ifTrue: [ ^ self error: 3 ].
	normalized = 'error4' ifTrue: [ ^ self error: 4 ].
	normalized = 'fatal' ifTrue: [ ^ self fatal ].
	normalized = 'fatal2' ifTrue: [ ^ self fatal: 2 ].
	normalized = 'fatal3' ifTrue: [ ^ self fatal: 3 ].
	normalized = 'fatal4' ifTrue: [ ^ self fatal: 4 ].
	Error signal: 'Unknown OpenTelemetry severity name: ' , anObject printString
]

{ #category : 'severity' }
OTSeverity class >> info [

	^ 9
]

{ #category : 'severity' }
OTSeverity class >> info: anInteger [

	^ self severityAtBase: self info variant: anInteger
]

{ #category : 'testing' }
OTSeverity class >> isSpecified: anInteger [

	^ (self normalize: anInteger) > 0
]

{ #category : 'testing' }
OTSeverity class >> isValid: anInteger [

	anInteger isInteger ifFalse: [ ^ false ].
	^ anInteger between: 0 and: 24
]

{ #category : 'normalizing' }
OTSeverity class >> normalize: anObject [

	anObject ifNil: [ ^ self undefined ].
	(self isValid: anObject) ifFalse: [ Error signal: 'OpenTelemetry log severity numbers must be integers between 0 and 24' ].
	^ anObject
]

{ #category : 'private' }
OTSeverity class >> severityAtBase: aBase variant: anInteger [

	(anInteger isInteger and: [ anInteger between: 1 and: 4 ]) ifFalse: [
		Error signal: 'OpenTelemetry severity variants must be integers between 1 and 4' ].
	^ aBase + anInteger - 1
]

{ #category : 'severity' }
OTSeverity class >> shortNameFor: anObject [

	| baseName index offset value |
	value := self normalize: anObject.
	value = 0 ifTrue: [ ^ '' ].
	index := value - 1 // 4 + 1.
	(index between: 1 and: 6) ifFalse: [ Error signal: 'Unsupported OpenTelemetry severity number' ].
	baseName := #( 'TRACE' 'DEBUG' 'INFO' 'WARN' 'ERROR' 'FATAL' ) at: index.
	offset := value - 1 \\ 4.
	offset = 0 ifTrue: [ ^ baseName ].
	^ baseName , (offset + 1) asString
]

{ #category : 'severity' }
OTSeverity class >> trace [

	^ 1
]

{ #category : 'severity' }
OTSeverity class >> trace: anInteger [

	^ self severityAtBase: self trace variant: anInteger
]

{ #category : 'severity' }
OTSeverity class >> undefined [

	^ 0
]

{ #category : 'severity' }
OTSeverity class >> warn [

	^ 13
]

{ #category : 'severity' }
OTSeverity class >> warn: anInteger [

	^ self severityAtBase: self warn variant: anInteger
]
