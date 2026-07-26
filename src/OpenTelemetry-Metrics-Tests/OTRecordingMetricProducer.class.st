Class {
	#name : 'OTRecordingMetricProducer',
	#superclass : 'OTMetricProducer',
	#instVars : [
		'snapshot',
		'produceCount',
		'lastMetricFilter'
	],
	#category : 'OpenTelemetry-Metrics-Tests',
	#package : 'OpenTelemetry-Metrics-Tests'
}

{ #category : 'instance creation' }
OTRecordingMetricProducer class >> snapshot: anOTMetricSnapshot [

	^ self new
		  snapshot: anOTMetricSnapshot;
		  yourself
]

{ #category : 'initialization' }
OTRecordingMetricProducer >> initialize [

	super initialize.
	produceCount := 0
]

{ #category : 'collecting' }
OTRecordingMetricProducer >> produce [

	produceCount := produceCount + 1.
	^ snapshot
]

{ #category : 'accessing' }
OTRecordingMetricProducer >> produceCount [

	^ produceCount
]

{ #category : 'accessing' }
OTRecordingMetricProducer >> lastMetricFilter [

	^ lastMetricFilter
]

{ #category : 'accessing' }
OTRecordingMetricProducer >> snapshot [

	^ snapshot ifNil: [ OTMetricSnapshot empty ]
]

{ #category : 'accessing' }
OTRecordingMetricProducer >> snapshot: anOTMetricSnapshot [

	snapshot := anOTMetricSnapshot ifNil: [ OTMetricSnapshot empty ] ifNotNil: [ anOTMetricSnapshot ]
]

{ #category : 'collecting' }
OTRecordingMetricProducer >> produceForReader: anOTMetricReader metricFilter: anOTMetricFilter [

	lastMetricFilter := anOTMetricFilter.
	^ self produce
]
