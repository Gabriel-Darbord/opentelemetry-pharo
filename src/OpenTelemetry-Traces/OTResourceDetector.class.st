"
An object that discovers or supplies an OpenTelemetry resource fragment.
"
Class {
	#name : 'OTResourceDetector',
	#superclass : 'Object',
	#category : 'OpenTelemetry-Traces',
	#package : 'OpenTelemetry-Traces'
}

{ #category : 'accessing' }
OTResourceDetector class >> detectorName [

	^ self name
]

{ #category : 'detecting' }
OTResourceDetector >> detectResource [

	self subclassResponsibility
]

{ #category : 'accessing' }
OTResourceDetector >> detectorName [

	^ self class detectorName
]
