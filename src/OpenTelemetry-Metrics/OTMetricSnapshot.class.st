Class {
	#name : 'OTMetricSnapshot',
	#superclass : 'Object',
	#instVars : [
		'resource',
		'measurements'
	],
	#category : 'OpenTelemetry-Metrics',
	#package : 'OpenTelemetry-Metrics'
}

{ #category : 'instance creation' }
OTMetricSnapshot class >> empty [

	^ self
		resource: OTResource empty
		measurements: #()
]

{ #category : 'instance creation' }
OTMetricSnapshot class >> resource: anOTResource measurements: aCollection [

	| snapshot |
	snapshot := self new.
	snapshot
		resource: anOTResource;
		measurements: aCollection.
	^ snapshot
]

{ #category : 'accessing' }
OTMetricSnapshot >> measurements [

	^ measurements ifNil: [ #() ]
]

{ #category : 'accessing' }
OTMetricSnapshot >> measurements: aCollection [

	measurements := aCollection ifNil: [ #() ] ifNotNil: [ aCollection asArray ]
]

{ #category : 'accessing' }
OTMetricSnapshot >> resource [

	^ resource ifNil: [ OTResource empty ]
]

{ #category : 'accessing' }
OTMetricSnapshot >> resource: anOTResource [

	resource := anOTResource ifNil: [ OTResource empty ] ifNotNil: [ anOTResource ]
]
