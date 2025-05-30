Class {
	#name : 'OTContext',
	#superclass : 'Object',
	#instVars : [
		'currentSpan'
	],
	#category : 'OpenTelemetry-Instrumentation',
	#package : 'OpenTelemetry-Instrumentation'
}

{ #category : 'accessing' }
OTContext >> currentSpan [

	^ currentSpan
]

{ #category : 'accessing' }
OTContext >> currentSpan: aSpan [

	currentSpan := aSpan
]

{ #category : 'initialization' }
OTContext >> initialize [
	"TODO gather data on executor"
]
