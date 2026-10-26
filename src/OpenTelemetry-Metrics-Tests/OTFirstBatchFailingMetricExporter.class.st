Class {
	#name : 'OTFirstBatchFailingMetricExporter',
	#superclass : 'OTInMemoryMetricExporter',
	#instVars : [
		'failureMode'
	],
	#category : 'OpenTelemetry-Metrics-Tests',
	#package : 'OpenTelemetry-Metrics-Tests'
}

{ #category : 'exporting' }
OTFirstBatchFailingMetricExporter >> export: aSnapshot [

	super export: aSnapshot.
	failureMode = #delay ifTrue: [
			(Delay forMilliseconds: 80) wait.
			^ true ].
	self exports size = 1 ifTrue: [
			failureMode = #failure ifTrue: [ ^ false ].
			failureMode = #error ifTrue: [ self error: 'First batch failed' ].
			failureMode = #timeout ifTrue: [ Semaphore new wait ] ].
	^ true
]

{ #category : 'accessing' }
OTFirstBatchFailingMetricExporter >> failureMode: aSymbol [

	failureMode := aSymbol
]
