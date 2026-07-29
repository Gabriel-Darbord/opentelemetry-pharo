Class {
	#name : 'OTFailingOtlpJsonLineMetricExporter',
	#superclass : 'OTOtlpJsonLineMetricExporter',
	#category : 'OpenTelemetry-Metrics-Tests',
	#package : 'OpenTelemetry-Metrics-Tests'
}

{ #category : 'accessing' }
OTFailingOtlpJsonLineMetricExporter >> writeJsonLine: aString [

	Error signal: 'json-line write failure'
]
