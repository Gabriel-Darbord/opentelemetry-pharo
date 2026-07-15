"
I centralize OpenTelemetry SDK diagnostic output so warning and debugging paths
do not need to know which concrete logging backend is active.
"
Class {
	#name : 'OTDiagnosticLogger',
	#superclass : 'Object',
	#instVars : [
		'warningSink'
	],
	#classVars : [
		'Current'
	],
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'accessing' }
OTDiagnosticLogger class >> current [

	^ Current ifNil: [ Current := self default ]
]

{ #category : 'accessing' }
OTDiagnosticLogger class >> current: aDiagnosticLogger [

	Current := aDiagnosticLogger
]

{ #category : 'instance creation' }
OTDiagnosticLogger class >> default [

	| tinyLoggerClass logger |
	tinyLoggerClass := self tinyLoggerClassIfAvailable.
	tinyLoggerClass ifNil: [ ^ self defaultStandardOutputLogger ].
	logger := tinyLoggerClass new.
	logger ensureStdoutLogger.
	^ self onWarningDo: [ :message |
		logger record: [ self warningMessageFor: message ] ]
]

{ #category : 'instance creation' }
OTDiagnosticLogger class >> defaultStandardOutputLogger [

	^ self onWarningDo: [ :message |
		self writeWarningToStandardOutput: message ]
]

{ #category : 'private - logging' }
OTDiagnosticLogger class >> defaultWarningSink [

	^ [ :message | self current warning: message ]
]

{ #category : 'instance creation' }
OTDiagnosticLogger class >> onWarningDo: aBlock [

	^ self new
		warningSink: aBlock;
		yourself
]

{ #category : 'class initialization' }
OTDiagnosticLogger class >> reset [

	<script>
	Current := nil
]

{ #category : 'private - logging' }
OTDiagnosticLogger class >> tinyLoggerClassIfAvailable [

	^ Smalltalk globals at: #TinyLogger ifAbsent: [ nil ]
]

{ #category : 'private - logging' }
OTDiagnosticLogger class >> warningMessageFor: aString [

	^ 'OpenTelemetry warning: ' , aString
]

{ #category : 'private - logging' }
OTDiagnosticLogger class >> writeWarningToStandardOutput: aString [

	| logger |
	logger := Stdio stdout.
	logger
		nextPutAll: (self warningMessageFor: aString);
		lf
]

{ #category : 'initialization' }
OTDiagnosticLogger >> initialize [

	super initialize.
	warningSink := [ :message |  ]
]

{ #category : 'logging' }
OTDiagnosticLogger >> warning: aString [

	warningSink value: aString
]

{ #category : 'accessing' }
OTDiagnosticLogger >> warningSink [

	^ warningSink
]

{ #category : 'accessing' }
OTDiagnosticLogger >> warningSink: aBlock [

	warningSink := aBlock
]
