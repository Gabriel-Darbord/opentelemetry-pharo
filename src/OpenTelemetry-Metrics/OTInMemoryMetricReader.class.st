Class {
	#name : 'OTInMemoryMetricReader',
	#superclass : 'OTMetricReader',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'collecting' }
OTInMemoryMetricReader >> collect [

	self isShutdown ifTrue: [ ^ #() ].
	^ self provider
		ifNil: [ #() ]
		ifNotNil: [ :aProvider | aProvider measurements copy ]
]
