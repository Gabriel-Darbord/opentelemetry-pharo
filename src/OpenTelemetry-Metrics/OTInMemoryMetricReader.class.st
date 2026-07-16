Class {
	#name : 'OTInMemoryMetricReader',
	#superclass : 'OTMetricReader',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'collecting' }
OTInMemoryMetricReader >> collect [

	^ self collectSnapshot measurements
]
