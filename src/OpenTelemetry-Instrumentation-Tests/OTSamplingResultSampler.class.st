Class {
	#name : 'OTSamplingResultSampler',
	#superclass : 'OTSampler',
	#instVars : [
		'samplingResult'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'instance creation' }
OTSamplingResultSampler class >> result: aSamplingResult [

	^ self new
		samplingResult: aSamplingResult;
		yourself
]

{ #category : 'accessing' }
OTSamplingResultSampler >> samplingResult: aSamplingResult [

	samplingResult := aSamplingResult
]

{ #category : 'sampling' }
OTSamplingResultSampler >> shouldSampleIn: aContext traceId: aTraceId name: aString kind: aSpanKind attributes: someAttributes links: someLinks [

	^ samplingResult
]
