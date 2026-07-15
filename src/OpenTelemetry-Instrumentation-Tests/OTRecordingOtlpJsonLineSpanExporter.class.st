Class {
	#name : 'OTRecordingOtlpJsonLineSpanExporter',
	#superclass : 'OTOtlpJsonLineSpanExporter',
	#instVars : [
		'writtenLines'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'accessing' }
OTRecordingOtlpJsonLineSpanExporter >> writeJsonLine: aString [

	self writtenLines add: aString
]

{ #category : 'accessing' }
OTRecordingOtlpJsonLineSpanExporter >> writtenLines [

	^ writtenLines ifNil: [ writtenLines := OrderedCollection new ]
]
