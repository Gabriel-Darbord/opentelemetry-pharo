"
I centralize OpenTelemetry SDK diagnostic output so warning and debugging paths
do not need to know which concrete logging backend is active.
"
Class {
	#name : 'OTDiagnosticLogger',
	#superclass : 'Object',
	#instVars : [
		'messageSink',
		'minimumSeverity',
		'errorHandler'
	],
	#classVars : [
		'Current'
	],
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'severity' }
OTDiagnosticLogger class >> allSeverity [

	^ 6
]

{ #category : 'instance creation' }
OTDiagnosticLogger class >> buildDefaultLogger [

	| tinyLoggerClass logger |
	tinyLoggerClass := self tinyLoggerClassIfAvailable.
	tinyLoggerClass ifNil: [ ^ self defaultStandardOutputLogger ].
	logger := tinyLoggerClass new.
	logger ensureStdoutLogger.
	^ (self onMessageDo: [ :severity :message | logger record: [ self messageForSeverity: severity text: message ] ])
		  minimumSeverity: self configuredMinimumSeverity;
		  yourself
]

{ #category : 'private - configuration' }
OTDiagnosticLogger class >> configuredMinimumSeverity [

	| configuredValue |
	configuredValue := self environmentValueAt: 'OTEL_LOG_LEVEL'.
	configuredValue ifNil: [ ^ self infoSeverity ].
	^ (self severityFromLogLevelValue: configuredValue)
		  ifNil: [
				  self noteInvalidLogLevel: configuredValue.
				  self infoSeverity ]
		  ifNotNil: [ :severity | severity ]
]

{ #category : 'accessing' }
OTDiagnosticLogger class >> current [

	^ Current ifNil: [ Current := self default ]
]

{ #category : 'accessing' }
OTDiagnosticLogger class >> current: aDiagnosticLogger [

	Current := aDiagnosticLogger
]

{ #category : 'severity' }
OTDiagnosticLogger class >> debugSeverity [

	^ 4
]

{ #category : 'instance creation' }
OTDiagnosticLogger class >> default [

	^ self loggerFactory value
]

{ #category : 'private - logging' }
OTDiagnosticLogger class >> defaultErrorHandler [

	^ [ :error :message | self current error: message ]
]

{ #category : 'instance creation' }
OTDiagnosticLogger class >> defaultStandardOutputLogger [

	^ (self onMessageDo: [ :severity :message | self writeMessageToStandardOutput: message severity: severity ])
		  minimumSeverity: self configuredMinimumSeverity;
		  yourself
]

{ #category : 'private - logging' }
OTDiagnosticLogger class >> defaultWarningSink [

	^ [ :message | self current warning: message ]
]

{ #category : 'private - configuration' }
OTDiagnosticLogger class >> environmentValueAt: aString [

	^ OTConfigurationSource environmentValueAt: aString
]

{ #category : 'severity' }
OTDiagnosticLogger class >> errorSeverity [

	^ 1
]

{ #category : 'severity' }
OTDiagnosticLogger class >> infoSeverity [

	^ 3
]

{ #category : 'instance creation' }
OTDiagnosticLogger class >> loggerFactory [

	^ OTClassStateStore valueAt: #otDiagnosticLoggerFactory forClass: self ifAbsent: [ [ self buildDefaultLogger ] ]
]

{ #category : 'instance creation' }
OTDiagnosticLogger class >> loggerFactory: aBlockOrNil [

	aBlockOrNil
		ifNil: [ OTClassStateStore removeValueAt: #otDiagnosticLoggerFactory forClass: self ifAbsent: [ ] ]
		ifNotNil: [ OTClassStateStore valueAt: #otDiagnosticLoggerFactory forClass: self put: aBlockOrNil ].
	^ self loggerFactory
]

{ #category : 'private - logging' }
OTDiagnosticLogger class >> messageForSeverity: aSeverity text: aString [

	^ 'OpenTelemetry ' , (self severityNameFor: aSeverity) , ': ' , aString
]

{ #category : 'severity' }
OTDiagnosticLogger class >> noneSeverity [

	^ 0
]

{ #category : 'private - logging' }
OTDiagnosticLogger class >> noteInvalidLogLevel: aString [

	self
		writeMessageToStandardOutput: 'OpenTelemetry diagnostic log level was unrecognized and has been ignored: ' , aString printString
		severity: self warningSeverity
]

{ #category : 'instance creation' }
OTDiagnosticLogger class >> onMessageDo: aBlock [

	^ self new
		  messageSink: aBlock;
		  yourself
]

{ #category : 'instance creation' }
OTDiagnosticLogger class >> onWarningDo: aBlock [

	^ self onMessageDo: [ :severity :message | severity = self warningSeverity ifTrue: [ aBlock value: message ] ]
]

{ #category : 'class initialization' }
OTDiagnosticLogger class >> reset [

	<script>
	OTConfigurationSource reset.
	self loggerFactory: nil.
	self tinyLoggerClassResolver: nil.
	Current := nil
]

{ #category : 'severity' }
OTDiagnosticLogger class >> severityFromLogLevelValue: aString [

	| normalizedValue |
	normalizedValue := aString asString trimBoth asUppercase.
	normalizedValue = 'NONE' ifTrue: [ ^ self noneSeverity ].
	normalizedValue = 'ERROR' ifTrue: [ ^ self errorSeverity ].
	normalizedValue = 'WARN' ifTrue: [ ^ self warningSeverity ].
	normalizedValue = 'INFO' ifTrue: [ ^ self infoSeverity ].
	normalizedValue = 'DEBUG' ifTrue: [ ^ self debugSeverity ].
	normalizedValue = 'VERBOSE' ifTrue: [ ^ self verboseSeverity ].
	normalizedValue = 'ALL' ifTrue: [ ^ self allSeverity ].
	^ nil
]

{ #category : 'severity' }
OTDiagnosticLogger class >> severityNameFor: aSeverity [

	aSeverity = self errorSeverity ifTrue: [ ^ 'error' ].
	aSeverity = self warningSeverity ifTrue: [ ^ 'warning' ].
	aSeverity = self infoSeverity ifTrue: [ ^ 'info' ].
	aSeverity = self debugSeverity ifTrue: [ ^ 'debug' ].
	aSeverity = self verboseSeverity ifTrue: [ ^ 'verbose' ].
	^ 'log'
]

{ #category : 'private - logging' }
OTDiagnosticLogger class >> tinyLoggerClassIfAvailable [

	^ self tinyLoggerClassResolver value
]

{ #category : 'private - logging' }
OTDiagnosticLogger class >> tinyLoggerClassResolver [

	^ OTClassStateStore
		  valueAt: #otTinyLoggerClassResolver
		  forClass: self
		  ifAbsent: [ [ Smalltalk globals at: #TinyLogger ifAbsent: [ nil ] ] ]
]

{ #category : 'private - logging' }
OTDiagnosticLogger class >> tinyLoggerClassResolver: aBlockOrNil [

	aBlockOrNil
		ifNil: [ OTClassStateStore removeValueAt: #otTinyLoggerClassResolver forClass: self ifAbsent: [ ] ]
		ifNotNil: [ OTClassStateStore valueAt: #otTinyLoggerClassResolver forClass: self put: aBlockOrNil ].
	^ self tinyLoggerClassResolver
]

{ #category : 'severity' }
OTDiagnosticLogger class >> verboseSeverity [

	^ 5
]

{ #category : 'severity' }
OTDiagnosticLogger class >> warningSeverity [

	^ 2
]

{ #category : 'private - logging' }
OTDiagnosticLogger class >> writeMessageToStandardOutput: aString severity: aSeverity [

	| logger |
	logger := Stdio stdout.
	logger
		nextPutAll: (self messageForSeverity: aSeverity text: aString);
		lf
]

{ #category : 'logging' }
OTDiagnosticLogger >> debug: aString [

	self logSeverity: self class debugSeverity message: aString
]

{ #category : 'logging' }
OTDiagnosticLogger >> error: aString [

	self logSeverity: self class errorSeverity message: aString
]

{ #category : 'accessing' }
OTDiagnosticLogger >> errorHandler [

	^ errorHandler
]

{ #category : 'accessing' }
OTDiagnosticLogger >> errorHandler: aBlock [

	errorHandler := aBlock
]

{ #category : 'logging' }
OTDiagnosticLogger >> handleSuppressedError: anError message: aString fallback: aBlock [

	errorHandler ifNil: [ ^ aBlock value ].
	^ errorHandler value: anError value: aString
]

{ #category : 'logging' }
OTDiagnosticLogger >> info: aString [

	self logSeverity: self class infoSeverity message: aString
]

{ #category : 'initialization' }
OTDiagnosticLogger >> initialize [

	super initialize.
	messageSink := [ :severity :message |  ].
	minimumSeverity := self class infoSeverity.
	errorHandler := nil
]

{ #category : 'logging' }
OTDiagnosticLogger >> logSeverity: aSeverity message: aString [

	(self shouldLogSeverity: aSeverity) ifFalse: [ ^ self ].
	messageSink value: aSeverity value: aString
]

{ #category : 'accessing' }
OTDiagnosticLogger >> messageSink [

	^ messageSink
]

{ #category : 'accessing' }
OTDiagnosticLogger >> messageSink: aBlock [

	messageSink := aBlock
]

{ #category : 'accessing' }
OTDiagnosticLogger >> minimumSeverity [

	^ minimumSeverity
]

{ #category : 'accessing' }
OTDiagnosticLogger >> minimumSeverity: anInteger [

	minimumSeverity := anInteger
]

{ #category : 'testing' }
OTDiagnosticLogger >> shouldLogSeverity: aSeverity [

	minimumSeverity = self class noneSeverity ifTrue: [ ^ false ].
	^ aSeverity <= minimumSeverity
]

{ #category : 'logging' }
OTDiagnosticLogger >> warning: aString [

	self logSeverity: self class warningSeverity message: aString
]
