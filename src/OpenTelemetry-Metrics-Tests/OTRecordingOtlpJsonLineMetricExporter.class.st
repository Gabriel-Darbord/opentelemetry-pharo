Class {
	#name : 'OTRecordingOtlpJsonLineMetricExporter',
	#superclass : 'OTOtlpJsonLineMetricExporter',
	#instVars : [
		'writtenLines'
	],
	#category : 'OpenTelemetry-Metrics-Tests',
	#package : 'OpenTelemetry-Metrics-Tests'
}

{ #category : 'accessing' }
OTRecordingOtlpJsonLineMetricExporter >> writeJsonLine: aString [

	self writtenLines add: aString
]

{ #category : 'accessing' }
OTRecordingOtlpJsonLineMetricExporter >> writtenLines [

	^ writtenLines ifNil: [ writtenLines := OrderedCollection new ]
]
