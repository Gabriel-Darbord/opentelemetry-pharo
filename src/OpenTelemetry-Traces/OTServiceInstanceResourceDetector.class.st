"
Supplies a stable service.instance.id for the running process unless later detectors override it.
"
Class {
	#name : 'OTServiceInstanceResourceDetector',
	#superclass : 'OTResourceDetector',
	#category : 'OpenTelemetry-Traces',
	#package : 'OpenTelemetry-Traces'
}

{ #category : 'accessing' }
OTServiceInstanceResourceDetector class >> detectorName [

	^ 'service_instance'
]

{ #category : 'detecting' }
OTServiceInstanceResourceDetector >> detectResource [

	^ OTResource attributes: { ('service.instance.id' -> OTTracerProvider defaultServiceInstanceId) }
]
