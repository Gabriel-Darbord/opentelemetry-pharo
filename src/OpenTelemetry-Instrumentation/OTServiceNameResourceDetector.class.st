"
Reads OTEL_SERVICE_NAME as a dedicated service resource detector.
"
Class {
	#name : 'OTServiceNameResourceDetector',
	#superclass : 'OTResourceDetector',
	#category : 'OpenTelemetry-Instrumentation',
	#package : 'OpenTelemetry-Instrumentation'
}

{ #category : 'accessing' }
OTServiceNameResourceDetector class >> detectorName [

	^ 'service'
]

{ #category : 'detecting' }
OTServiceNameResourceDetector >> detectResource [

	| serviceName |
	serviceName := OTTracerProvider configuredServiceName.
	serviceName ifNil: [ ^ OTResource empty ].
	^ OTResource attributes: { 'service.name' -> serviceName }
]
