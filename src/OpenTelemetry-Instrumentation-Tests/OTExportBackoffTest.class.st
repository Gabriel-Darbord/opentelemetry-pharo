Class {
	#name : 'OTExportBackoffTest',
	#superclass : 'TestCase',
	#instVars : [
		'backoff',
		'now'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'running' }
OTExportBackoffTest >> setUp [

	super setUp.
	now := 0.
	backoff := OTExportBackoff new.
	backoff clock: [ now ]
]

{ #category : 'tests' }
OTExportBackoffTest >> testAClockThatGoesBackEndsTheWait [

	now := 1000000.
	backoff noteFailure.
	now := 10.
	self deny: backoff isWaiting
]

{ #category : 'tests' }
OTExportBackoffTest >> testASuccessResetsTheDelay [

	backoff
		noteFailure;
		noteFailure;
		noteSuccess.
	self deny: backoff isWaiting.
	backoff noteFailure.
	self assert: backoff waitMillis equals: OTExportBackoff initialDelayMillis
]

{ #category : 'tests' }
OTExportBackoffTest >> testDoesNotWaitBeforeAFailure [

	self deny: backoff isWaiting
]

{ #category : 'tests' }
OTExportBackoffTest >> testEachFailureDoublesTheDelayUpToTheMaximum [

	| expected waits |
	expected := (0 to: 7) collect: [ :each |
		            OTExportBackoff initialDelayMillis * (2 raisedTo: each) min: OTExportBackoff maximumDelayMillis ].
	waits := (1 to: 8) collect: [ :each |
			         backoff noteFailure.
			         backoff waitMillis ].
	self assert: waits equals: expected.
	self assert: waits last equals: OTExportBackoff maximumDelayMillis
]

{ #category : 'tests' }
OTExportBackoffTest >> testRetryAfterIsHonouredWithinTheMaximum [

	backoff noteFailureRetryingAfterMillis: 30000.
	self assert: backoff waitMillis equals: 30000.
	backoff noteFailureRetryingAfterMillis: 36000000.
	self assert: backoff waitMillis equals: OTExportBackoff maximumDelayMillis
]

{ #category : 'tests' }
OTExportBackoffTest >> testWaitsTheDelayAfterAFailure [

	backoff noteFailure.
	self assert: backoff isWaiting.
	now := OTExportBackoff initialDelayMillis - 1.
	self assert: backoff isWaiting.
	now := OTExportBackoff initialDelayMillis.
	self deny: backoff isWaiting
]
