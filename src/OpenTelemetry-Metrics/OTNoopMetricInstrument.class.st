"
Shared stateless metric instrument behavior for the metrics no-op API.

Concrete subclasses provide the instrument type and accept the user-facing
recording protocol without emitting measurements.
"
Class {
	#name : 'OTNoopMetricInstrument',
	#superclass : 'Object',
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'accessing' }
OTNoopMetricInstrument class >> instance [

	^ OTClassStateStore valueAt: #otInstance forClass: self ifAbsentPut: [ self new ]
]

{ #category : 'accessing' }
OTNoopMetricInstrument >> advice [

	^ Dictionary new
]

{ #category : 'binding' }
OTNoopMetricInstrument >> bind: aCollection [

	^ self
]

{ #category : 'collecting' }
OTNoopMetricInstrument >> collectFor: anOTMetricReader into: aCollection [

	self
]

{ #category : 'accessing' }
OTNoopMetricInstrument >> creationTimestamp [

	^ DateAndTime now asUTC
]

{ #category : 'accessing' }
OTNoopMetricInstrument >> description [

	^ ''
]

{ #category : 'testing' }
OTNoopMetricInstrument >> enabled [

	^ false
]

{ #category : 'testing' }
OTNoopMetricInstrument >> isNoop [

	^ true
]

{ #category : 'accessing' }
OTNoopMetricInstrument >> instrumentType [

	self subclassResponsibility
]

{ #category : 'accessing' }
OTNoopMetricInstrument >> instrumentationScope [

	^ OTInstrumentationScope named: ''
]

{ #category : 'accessing' }
OTNoopMetricInstrument >> meter [

	^ nil
]

{ #category : 'accessing' }
OTNoopMetricInstrument >> name [

	^ ''
]

{ #category : 'aggregating' }
OTNoopMetricInstrument >> otlpTemporalityForCumulativePreference [

	^ #cumulative
]

{ #category : 'aggregating' }
OTNoopMetricInstrument >> otlpTemporalityForDeltaPreference [

	^ #cumulative
]

{ #category : 'aggregating' }
OTNoopMetricInstrument >> otlpTemporalityForLowMemoryPreference [

	^ self otlpTemporalityForCumulativePreference
]

{ #category : 'aggregating' }
OTNoopMetricInstrument >> otlpTemporalityForPreference: aSymbol [

	aSymbol = #delta ifTrue: [ ^ self otlpTemporalityForDeltaPreference ].
	aSymbol = #lowMemory ifTrue: [ ^ self otlpTemporalityForLowMemoryPreference ].
	^ self otlpTemporalityForCumulativePreference
]

{ #category : 'aggregating' }
OTNoopMetricInstrument >> supportsAggregation: aSymbol [

	^ aSymbol = #default or: [ aSymbol = #drop ]
]

{ #category : 'accessing' }
OTNoopMetricInstrument >> unit [

	^ ''
]
