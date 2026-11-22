"
I am a periodic metric reader whose first collection fails, for tests of the export loop.
"
Class {
	#name : 'OTFailingOnceMetricReader',
	#superclass : 'OTPeriodicExportingMetricReader',
	#instVars : [
		'collectCount'
	],
	#category : 'OpenTelemetry-Metrics-Tests',
	#package : 'OpenTelemetry-Metrics-Tests'
}

{ #category : 'collecting' }
OTFailingOnceMetricReader >> collect [

	collectCount := self collectCount + 1.
	collectCount = 1 ifTrue: [ Error signal: 'collection failure' ].
	^ OTMetricSnapshot empty
]

{ #category : 'accessing' }
OTFailingOnceMetricReader >> collectCount [

	^ collectCount ifNil: [ 0 ]
]
