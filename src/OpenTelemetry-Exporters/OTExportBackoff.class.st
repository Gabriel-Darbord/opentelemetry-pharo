"
I hold an exporter's requests back after an export fails, so that a collector that is down or overloaded is not asked again for every batch.

A failed export starts a delay during which the exporter drops its batches at once, without a request. Each failure that follows doubles the delay, up to a maximum, and a collector that says how long to wait with Retry-After is left alone that long instead, within the same maximum. A successful export resets me. A clock that goes back, as when the image starts again, ends the wait.
"
Class {
	#name : 'OTExportBackoff',
	#superclass : 'Object',
	#instVars : [
		'delayMillis',
		'waitMillis',
		'failedAt',
		'clock'
	],
	#category : 'OpenTelemetry-Exporters',
	#package : 'OpenTelemetry-Exporters'
}

{ #category : 'defaults' }
OTExportBackoff class >> initialDelayMillis [
	"How long exports are held back after a first failure."

	^ 5000
]

{ #category : 'defaults' }
OTExportBackoff class >> maximumDelayMillis [
	"The longest exports are held back, however many failures came before and whatever the collector asks for."

	^ 120000
]

{ #category : 'accessing' }
OTExportBackoff >> clock: aBlock [
	"aBlock answers the time in milliseconds."

	clock := aBlock
]

{ #category : 'initialization' }
OTExportBackoff >> initialize [

	super initialize.
	clock := [ Time millisecondClockValue ].
	self noteSuccess
]

{ #category : 'testing' }
OTExportBackoff >> isWaiting [
	"Whether exports are dropped now, since the last one failed less than the delay ago."

	| elapsed |
	failedAt ifNil: [ ^ false ].
	elapsed := clock value - failedAt.
	^ elapsed >= 0 and: [ elapsed < waitMillis ]
]

{ #category : 'recording' }
OTExportBackoff >> noteFailure [

	self noteFailureRetryingAfterMillis: nil
]

{ #category : 'recording' }
OTExportBackoff >> noteFailureRetryingAfterMillis: aNumberOrNil [
	"Holds exports back for twice as long as after the previous failure, or for aNumberOrNil milliseconds when the collector asked for it."

	delayMillis := delayMillis
		               ifNil: [ self class initialDelayMillis ]
		               ifNotNil: [ delayMillis * 2 min: self class maximumDelayMillis ].
	waitMillis := (aNumberOrNil ifNil: [ delayMillis ]) min: self class maximumDelayMillis.
	failedAt := clock value
]

{ #category : 'recording' }
OTExportBackoff >> noteSuccess [

	delayMillis := nil.
	waitMillis := 0.
	failedAt := nil
]

{ #category : 'accessing' }
OTExportBackoff >> waitMillis [
	"How long exports are held back after the last failure."

	^ waitMillis
]
