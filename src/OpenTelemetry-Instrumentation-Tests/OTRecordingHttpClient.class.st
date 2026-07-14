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
		'shouldRaiseOnExecute'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'accessing' }
OTRecordingHttpClient >> code [

	^ responseCode ifNil: [ 200 ]
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

	self shouldRaiseOnExecute ifTrue: [
		Error signal: 'simulated HTTP failure' ].
	^ self
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

{ #category : 'executing' }
OTRecordingHttpClient >> response [

	^ self
]

{ #category : 'accessing' }
OTRecordingHttpClient >> responseCode: anInteger [

	responseCode := anInteger
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
