Class {
	#name : 'OTRecordingOtlpJsonLineLogRecordExporter',
	#superclass : 'OTOtlpJsonLineLogRecordExporter',
	#instVars : [
		'writtenLines'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'accessing' }
OTRecordingOtlpJsonLineLogRecordExporter >> writeJsonLine: aString [

	self writtenLines add: aString
]

{ #category : 'accessing' }
OTRecordingOtlpJsonLineLogRecordExporter >> writtenLines [

	^ writtenLines ifNil: [ writtenLines := OrderedCollection new ]
]
