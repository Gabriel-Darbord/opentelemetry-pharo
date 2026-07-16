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
	(self isValid: anObject) ifFalse: [
		Error signal: 'OpenTelemetry log severity numbers must be integers between 0 and 24' ].
	^ anObject
]

{ #category : 'severity' }
OTSeverity class >> shortNameFor: anObject [

	| value baseName offset |
	value := self normalize: anObject.
	value = 0 ifTrue: [ ^ '' ].
	value <= 4 ifTrue: [ baseName := 'TRACE'. offset := value - 1 ].
	(value between: 5 and: 8) ifTrue: [ baseName := 'DEBUG'. offset := value - 5 ].
	(value between: 9 and: 12) ifTrue: [ baseName := 'INFO'. offset := value - 9 ].
	(value between: 13 and: 16) ifTrue: [ baseName := 'WARN'. offset := value - 13 ].
	(value between: 17 and: 20) ifTrue: [ baseName := 'ERROR'. offset := value - 17 ].
	(value between: 21 and: 24) ifTrue: [ baseName := 'FATAL'. offset := value - 21 ].
	offset ifNil: [ Error signal: 'Unsupported OpenTelemetry severity number' ].
	offset = 0 ifTrue: [ ^ baseName ].
	^ baseName, (offset + 1) asString
]

{ #category : 'private' }
OTSeverity class >> severityAtBase: aBase variant: anInteger [

	(anInteger isInteger and: [ anInteger between: 1 and: 4 ]) ifFalse: [
		Error signal: 'OpenTelemetry severity variants must be integers between 1 and 4' ].
	^ aBase + anInteger - 1
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
