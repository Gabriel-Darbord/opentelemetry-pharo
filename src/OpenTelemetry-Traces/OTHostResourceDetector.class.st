"
Supplies host and operating-system resource attributes that can be derived from the running platform.
"
Class {
	#name : 'OTHostResourceDetector',
	#superclass : 'OTResourceDetector',
	#category : 'OpenTelemetry-Traces',
	#package : 'OpenTelemetry-Traces'
}

{ #category : 'accessing' }
OTHostResourceDetector class >> detectorName [

	^ 'host'
]

{ #category : 'detecting' }
OTHostResourceDetector >> detectResource [

	| attributes |
	attributes := OrderedDictionary new.
	OTTracerProvider defaultHostName ifNotNil: [ :value | attributes at: 'host.name' put: value ].
	OTTracerProvider defaultHostArchitecture ifNotNil: [ :value | attributes at: 'host.arch' put: value ].
	OTTracerProvider defaultOsType ifNotNil: [ :value | attributes at: 'os.type' put: value ].
	OTTracerProvider defaultOsName ifNotNil: [ :value | attributes at: 'os.name' put: value ].
	OTTracerProvider defaultOsDescription ifNotNil: [ :value | attributes at: 'os.description' put: value ].
	^ attributes
		  ifEmpty: [ OTResource empty ]
		  ifNotEmpty: [ OTResource attributes: attributes schemaUrl: OTTracerProvider semanticConventionsSchemaUrl ]
]
