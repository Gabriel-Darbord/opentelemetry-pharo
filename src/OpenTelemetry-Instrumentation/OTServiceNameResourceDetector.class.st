"
Supplies the built-in service resource attributes derived from SDK defaults and OTEL_SERVICE_NAME.
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

	| attributes rawResourceAttributes serviceName |
	attributes := OrderedDictionary new.
	serviceName := OTTracerProvider configuredServiceName.
	serviceName ifNotNil: [ attributes at: 'service.name' put: serviceName ].
	rawResourceAttributes := OTTracerProvider environmentValueAt: 'OTEL_RESOURCE_ATTRIBUTES'.
	(rawResourceAttributes isNil
		or: [ (rawResourceAttributes includesSubstring: 'service.instance.id=') not ]) ifTrue: [
			attributes
				at: 'service.instance.id'
				put: OTTracerProvider defaultServiceInstanceId ].
	^ attributes
		ifEmpty: [ OTResource empty ]
		ifNotEmpty: [
			OTResource
				attributes: attributes
				schemaUrl: OTTracerProvider semanticConventionsSchemaUrl ]
]
