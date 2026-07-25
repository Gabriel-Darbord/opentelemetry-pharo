"
I am a metric reader that returns the collected measurements directly in memory.
I am useful for tests and local inspection.
"
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
