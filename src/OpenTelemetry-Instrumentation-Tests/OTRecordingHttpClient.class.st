Class {
	#name : 'OTRecordingHttpClient',
	#superclass : 'Object',
	#instVars : [
		'url',
		'method',
		'timeout',
		'headers',
		'entity',
		'responseCode',
		'shouldRaiseOnExecute',
		'plannedExecutions',
		'executionCount',
		'responseHeaders',
		'responseContents',
		'certificate',
		'certificateDuringExecute',
		'sslCertFileDuringExecute'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'accessing' }
OTRecordingHttpClient >> certificate [

	^ certificate
]

{ #category : 'accessing' }
OTRecordingHttpClient >> certificate: aStringOrNil [

	certificate := aStringOrNil
]

{ #category : 'accessing' }
OTRecordingHttpClient >> certificateDuringExecute [

	^ certificateDuringExecute
]

{ #category : 'accessing' }
OTRecordingHttpClient >> code [

	^ responseCode ifNil: [ 200 ]
]

{ #category : 'accessing' }
OTRecordingHttpClient >> contents: anObject [

	entity := anObject
]

{ #category : 'accessing' }
OTRecordingHttpClient >> entity [

	^ entity
]

{ #category : 'accessing' }
OTRecordingHttpClient >> entity: aZnEntity [

	entity := aZnEntity
]

{ #category : 'executing' }
OTRecordingHttpClient >> execute [

	executionCount := self executionCount + 1.
	certificateDuringExecute := certificate.
	sslCertFileDuringExecute := Smalltalk os environment at: 'SSL_CERT_FILE' ifAbsent: [ nil ].
	self playNextPlannedExecution.
	self shouldRaiseOnExecute ifTrue: [ Error signal: 'simulated HTTP failure' ].
	self
]

{ #category : 'accessing' }
OTRecordingHttpClient >> executionCount [

	^ executionCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
OTRecordingHttpClient >> headerAt: aKey put: aValue [

	self headers at: aKey put: aValue
]

{ #category : 'accessing' }
OTRecordingHttpClient >> headers [

	^ headers ifNil: [ headers := OrderedDictionary new ]
]

{ #category : 'accessing' }
OTRecordingHttpClient >> method [

	^ method
]

{ #category : 'accessing' }
OTRecordingHttpClient >> method: aSymbol [

	method := aSymbol
]

{ #category : 'private' }
OTRecordingHttpClient >> nextPlannedExecution [

	| executions |
	executions := self plannedExecutions.
	^ executions isEmpty
		ifTrue: [ nil ]
		ifFalse: [ executions removeFirst ]
]

{ #category : 'private' }
OTRecordingHttpClient >> plannedExecutions [

	^ plannedExecutions ifNil: [ plannedExecutions := OrderedCollection new ]
]

{ #category : 'private' }
OTRecordingHttpClient >> playNextPlannedExecution [

	| plannedExecution |
	plannedExecution := self nextPlannedExecution.
	plannedExecution ifNil: [ ^ self ].
	plannedExecution value: self
]

{ #category : 'private' }
OTRecordingHttpClient >> queueExecutionFailure [

	self plannedExecutions add: [ :client | client shouldRaiseOnExecute: true ].
	^ self
]

{ #category : 'private' }
OTRecordingHttpClient >> queueResponseCode: anInteger headers: aDictionary contents: anObject [

	self plannedExecutions add: [ :client |
		client
			shouldRaiseOnExecute: false;
			responseCode: anInteger;
			responseHeaders: aDictionary;
			responseContents: anObject ].
	^ self
]

{ #category : 'executing' }
OTRecordingHttpClient >> response [

	^ self
]

{ #category : 'accessing' }
OTRecordingHttpClient >> responseCode: anInteger [

	responseCode := anInteger
]

{ #category : 'accessing' }
OTRecordingHttpClient >> responseContents [

	^ responseContents ifNil: [ '{}' ]
]

{ #category : 'accessing' }
OTRecordingHttpClient >> responseContents: anObject [

	responseContents := anObject
]

{ #category : 'accessing' }
OTRecordingHttpClient >> responseHeaderAt: aKey ifAbsent: aBlock [

	^ self responseHeaders at: aKey ifAbsent: aBlock
]

{ #category : 'accessing' }
OTRecordingHttpClient >> responseHeaders [

	^ responseHeaders ifNil: [
		  OrderedDictionary new
			  at: 'Content-Type' put: 'application/json';
			  yourself ]
]

{ #category : 'accessing' }
OTRecordingHttpClient >> responseHeaders: aDictionary [

	responseHeaders := aDictionary
]

{ #category : 'accessing' }
OTRecordingHttpClient >> shouldRaiseOnExecute [

	^ shouldRaiseOnExecute = true
]

{ #category : 'accessing' }
OTRecordingHttpClient >> shouldRaiseOnExecute: aBoolean [

	shouldRaiseOnExecute := aBoolean = true
]

{ #category : 'accessing' }
OTRecordingHttpClient >> sslCertFileDuringExecute [

	^ sslCertFileDuringExecute
]

{ #category : 'accessing' }
OTRecordingHttpClient >> timeout [

	^ timeout
]

{ #category : 'accessing' }
OTRecordingHttpClient >> timeout: anInteger [

	timeout := anInteger
]

{ #category : 'accessing' }
OTRecordingHttpClient >> url [

	^ url
]

{ #category : 'accessing' }
OTRecordingHttpClient >> url: aString [

	url := aString
]
