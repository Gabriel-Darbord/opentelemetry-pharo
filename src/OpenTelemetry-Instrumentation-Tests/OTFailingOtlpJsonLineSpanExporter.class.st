Class {
	#name : 'OTFailingOtlpJsonLineSpanExporter',
	#superclass : 'OTOtlpJsonLineSpanExporter',
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'accessing' }
OTFailingOtlpJsonLineSpanExporter >> writeJsonLine: aString [

	Error signal: 'json-line write failure'
]
