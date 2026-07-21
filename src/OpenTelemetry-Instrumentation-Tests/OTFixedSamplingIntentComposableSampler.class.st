Class {
	#name : 'OTFixedSamplingIntentComposableSampler',
	#superclass : 'OTComposableSampler',
	#instVars : [
		'intent'
	],
	#category : 'OpenTelemetry-Instrumentation-Tests',
	#package : 'OpenTelemetry-Instrumentation-Tests'
}

{ #category : 'instance creation' }
OTFixedSamplingIntentComposableSampler class >> intent: aSamplingIntent [

	^ self new
		  intent: aSamplingIntent;
		  yourself
]

{ #category : 'accessing' }
OTFixedSamplingIntentComposableSampler >> description [

	^ 'fixed intent'
]

{ #category : 'accessing' }
OTFixedSamplingIntentComposableSampler >> intent [

	^ intent
]

{ #category : 'accessing' }
OTFixedSamplingIntentComposableSampler >> intent: aSamplingIntent [

	intent := aSamplingIntent
]

{ #category : 'sampling' }
OTFixedSamplingIntentComposableSampler >> samplingIntentIn: aContext name: aString kind: aSpanKind attributes: someAttributes links: someLinks [

	^ self intent
]
