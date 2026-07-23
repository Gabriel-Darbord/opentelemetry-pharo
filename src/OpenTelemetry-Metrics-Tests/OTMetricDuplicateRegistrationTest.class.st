Class {
	#name : 'OTMetricDuplicateRegistrationTest',
	#superclass : 'TestCase',
	#category : 'OpenTelemetry-Metrics-Tests',
	#package : 'OpenTelemetry-Metrics-Tests'
}

{ #category : 'running' }
OTMetricDuplicateRegistrationTest >> tearDown [

	[
		OTMeter instrumentWarningSink: nil.
		OTMeterProvider reset ] ensure: [ super tearDown ]
]

{ #category : 'tests' }
OTMetricDuplicateRegistrationTest >> testMatchingViewDescriptionOverrideSuppressesDescriptionConflictWarning [

	self withInstrumentWarningsDo: [ :warnings |
			| first second provider |
			provider := OTMeterProvider new.
			provider addView: ((OTMetricView named: 'requests.total')
					 streamDescription: 'Requests';
					 yourself).
			first := (provider meterNamed: 'demo.metrics')
				         counterNamed: 'requests.total'
				         unit: '1'
				         description: 'First'
				         advice: Dictionary new.
			second := (provider meterNamed: 'demo.metrics')
				          counterNamed: 'requests.total'
				          unit: '1'
				          description: 'Second'
				          advice: Dictionary new.
			self deny: second identicalTo: first.
			self assert: warnings isEmpty ]
]

{ #category : 'tests' }
OTMetricDuplicateRegistrationTest >> testMeterWarnsOnCrossKindDuplicateInstrumentNames [

	self withInstrumentWarningsDo: [ :warnings |
			| counter gauge meter |
			meter := OTMeterProvider new meterNamed: 'demo.metrics'.
			counter := meter
				           counterNamed: 'requests.total'
				           unit: '1'
				           description: ''
				           advice: Dictionary new.
			gauge := meter
				         gaugeNamed: 'requests.total'
				         unit: '1'
				         description: ''
				         advice: Dictionary new.
			self deny: gauge identicalTo: counter.
			self assert: warnings size equals: 1.
			self assert: (warnings first includesSubstring: 'class=OTGauge').
			self assert: (warnings first includesSubstring: 'instrumentType: #gauge').
			self assert: (warnings first includesSubstring: 'streamName:') ]
]

{ #category : 'tests' }
OTMetricDuplicateRegistrationTest >> testMeterWarnsOnDescriptionConflictWithViewRecipe [

	self withInstrumentWarningsDo: [ :warnings |
			| first second meter |
			meter := OTMeterProvider new meterNamed: 'demo.metrics'.
			first := meter
				         counterNamed: 'requests.total'
				         unit: '1'
				         description: 'First'
				         advice: Dictionary new.
			second := meter
				          counterNamed: 'requests.total'
				          unit: '1'
				          description: 'Second'
				          advice: Dictionary new.
			self deny: second identicalTo: first.
			self assert: warnings size equals: 1.
			self assert: (warnings first includesSubstring: 'streamDescription:').
			self assert: (warnings first includesSubstring: '''Second''') ]
]

{ #category : 'private' }
OTMetricDuplicateRegistrationTest >> withInstrumentWarningsDo: aBlock [

	| warnings |
	warnings := OrderedCollection new.
	OTMeter instrumentWarningSink: [ :message | warnings add: message ].
	[ ^ aBlock value: warnings ] ensure: [ OTMeter instrumentWarningSink: nil ]
]
