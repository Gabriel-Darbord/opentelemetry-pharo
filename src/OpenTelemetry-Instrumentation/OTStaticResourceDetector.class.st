"
A resource detector that always contributes the same immutable resource.
"
Class {
	#name : 'OTStaticResourceDetector',
	#superclass : 'OTResourceDetector',
	#instVars : [
		'detectorName',
		'resource'
	],
	#category : 'OpenTelemetry-Instrumentation',
	#package : 'OpenTelemetry-Instrumentation'
}

{ #category : 'instance creation' }
OTStaticResourceDetector class >> named: aString resource: anOTResource [

	^ self new
		detectorName: aString;
		resource: anOTResource;
		yourself
]

{ #category : 'detecting' }
OTStaticResourceDetector >> detectResource [

	^ resource ifNil: [ OTResource empty ]
]

{ #category : 'accessing' }
OTStaticResourceDetector >> detectorName [

	^ detectorName ifNil: [ super detectorName ]
]

{ #category : 'private' }
OTStaticResourceDetector >> detectorName: aString [

	detectorName := aString
]

{ #category : 'private' }
OTStaticResourceDetector >> resource: anOTResource [

	resource := anOTResource
]
