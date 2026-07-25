Class {
	#name : 'OTTestableOtlpHttpJsonSpanExporter',
	#superclass : 'OTOtlpHttpJsonSpanExporter',
	#instVars : [
		'operatingSystemNameOverride'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'accessing' }
OTTestableOtlpHttpJsonSpanExporter >> operatingSystemName [

	^ operatingSystemNameOverride ifNil: [ super operatingSystemName ]
]

{ #category : 'accessing' }
OTTestableOtlpHttpJsonSpanExporter >> operatingSystemName: aString [

	operatingSystemNameOverride := aString
]
