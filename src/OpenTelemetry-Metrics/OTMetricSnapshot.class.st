Class {
	#name : 'OTMetricSnapshot',
	#superclass : 'Object',
	#instVars : [
		'resource',
		'measurements',
		'collectedAt',
		'metrics'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTMetricSnapshot class >> empty [

	^ self
		  resource: OTResource empty
		  measurements: #(  )
		  metrics: #(  )
		  collectedAt: DateAndTime now asUTC
]

{ #category : 'instance creation' }
OTMetricSnapshot class >> resource: anOTResource measurements: aCollection [

	^ self
		  resource: anOTResource
		  measurements: aCollection
		  metrics: #(  )
		  collectedAt: DateAndTime now asUTC
]

{ #category : 'instance creation' }
OTMetricSnapshot class >> resource: anOTResource measurements: aCollection collectedAt: aDateAndTime [

	^ self
		  resource: anOTResource
		  measurements: aCollection
		  metrics: #(  )
		  collectedAt: aDateAndTime
]

{ #category : 'instance creation' }
OTMetricSnapshot class >> resource: anOTResource measurements: aCollection metrics: someMetrics collectedAt: aDateAndTime [

	| snapshot |
	snapshot := self new.
	snapshot
		resource: anOTResource;
		measurements: aCollection;
		metrics: someMetrics;
		collectedAt: aDateAndTime.
	^ snapshot
]

{ #category : 'accessing' }
OTMetricSnapshot >> collectedAt [

	^ collectedAt ifNil: [ DateAndTime now asUTC ]
]

{ #category : 'accessing' }
OTMetricSnapshot >> collectedAt: aDateAndTime [

	collectedAt := aDateAndTime ifNil: [ DateAndTime now asUTC ] ifNotNil: [ aDateAndTime ]
]

{ #category : 'accessing' }
OTMetricSnapshot >> measurements [

	^ measurements ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
OTMetricSnapshot >> measurements: aCollection [

	measurements := aCollection ifNil: [ #(  ) ] ifNotNil: [ aCollection asArray ]
]

{ #category : 'accessing' }
OTMetricSnapshot >> metrics [

	^ metrics ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
OTMetricSnapshot >> metrics: aCollection [

	metrics := aCollection ifNil: [ #(  ) ] ifNotNil: [ aCollection asArray ]
]

{ #category : 'accessing' }
OTMetricSnapshot >> resource [

	^ resource ifNil: [ OTResource empty ]
]

{ #category : 'accessing' }
OTMetricSnapshot >> resource: anOTResource [

	resource := anOTResource ifNil: [ OTResource empty ] ifNotNil: [ anOTResource ]
]
