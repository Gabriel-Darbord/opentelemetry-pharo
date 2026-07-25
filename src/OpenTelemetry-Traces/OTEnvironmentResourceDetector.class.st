"
Reads OTEL_RESOURCE_ATTRIBUTES as a resource detector.
"
Class {
	#name : 'OTEnvironmentResourceDetector',
	#superclass : 'OTResourceDetector',
	#category : 'OpenTelemetry-Traces',
	#package : 'OpenTelemetry-Traces'
}

{ #category : 'accessing' }
OTEnvironmentResourceDetector class >> detectorName [

	^ 'environment'
]

{ #category : 'detecting' }
OTEnvironmentResourceDetector >> detectResource [

	| rawValue |
	rawValue := OTTracerProvider environmentValueAt: 'OTEL_RESOURCE_ATTRIBUTES'.
	rawValue ifNil: [ ^ OTResource empty ].
	^ [ OTResource attributes: (OTTracerProvider resourceAttributesFromEnvironment: rawValue) ]
		  on: Error
		  do: [ :error |
				  OTTracerProvider noteInvalidResourceAttributes: rawValue error: error.
				  OTResource empty ]
]
