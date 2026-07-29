Class {
	#name : 'OTRecordingMetricProducer',
	#superclass : 'OTMetricProducer',
	#instVars : [
		'snapshot',
		'produceCount',
		'lastMetricFilter',
		'lastResource',
		'produceResultBlock',
		'instrumentationScopeValue'
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
	produceCount := 0.
	lastResource := nil.
	produceResultBlock := nil.
	instrumentationScopeValue := nil
]

{ #category : 'accessing' }
OTRecordingMetricProducer >> instrumentationScope [

	^ instrumentationScopeValue ifNil: [ super instrumentationScope ]
]

{ #category : 'accessing' }
OTRecordingMetricProducer >> instrumentationScope: anOTInstrumentationScope [

	instrumentationScopeValue := anOTInstrumentationScope
]

{ #category : 'accessing' }
OTRecordingMetricProducer >> lastMetricFilter [

	^ lastMetricFilter
]

{ #category : 'accessing' }
OTRecordingMetricProducer >> lastResource [

	^ lastResource
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

{ #category : 'collecting' }
OTRecordingMetricProducer >> produceForReader: anOTMetricReader metricFilter: anOTMetricFilter [

	^ self produceForReader: anOTMetricReader resource: nil metricFilter: anOTMetricFilter
]

{ #category : 'collecting' }
OTRecordingMetricProducer >> produceForReader: anOTMetricReader resource: anOTResource metricFilter: anOTMetricFilter [

	lastMetricFilter := anOTMetricFilter.
	lastResource := anOTResource.
	^ self produceResult
]

{ #category : 'collecting' }
OTRecordingMetricProducer >> produceResult [

	produceResultBlock ifNotNil: [
			produceCount := produceCount + 1.
			^ produceResultBlock value: self ].
	^ super produceResult
]

{ #category : 'accessing' }
OTRecordingMetricProducer >> produceResultBlock: aBlock [

	produceResultBlock := aBlock
]

{ #category : 'collecting' }
OTRecordingMetricProducer >> produceResultForReader: anOTMetricReader metricFilter: anOTMetricFilter [

	^ self produceResultForReader: anOTMetricReader resource: nil metricFilter: anOTMetricFilter
]

{ #category : 'collecting' }
OTRecordingMetricProducer >> produceResultForReader: anOTMetricReader resource: anOTResource metricFilter: anOTMetricFilter [

	lastMetricFilter := anOTMetricFilter.
	lastResource := anOTResource.
	^ self produceResult
]

{ #category : 'accessing' }
OTRecordingMetricProducer >> snapshot [

	^ snapshot ifNil: [ OTMetricSnapshot empty ]
]

{ #category : 'accessing' }
OTRecordingMetricProducer >> snapshot: anOTMetricSnapshot [

	snapshot := anOTMetricSnapshot ifNil: [ OTMetricSnapshot empty ] ifNotNil: [ anOTMetricSnapshot ]
]
